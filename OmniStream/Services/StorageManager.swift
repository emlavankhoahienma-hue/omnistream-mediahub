import Foundation
import AVFoundation

// MARK: - Storage Manager
/// Quản lý hệ thống tệp cục bộ trong Sandbox Documents của ứng dụng,
/// hỗ trợ cấu trúc thư mục phân cấp, đồng bộ với Files App của iOS.

public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()

    public let fileManager = FileManager.default

    public var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public var downloadsDirectory: URL {
        documentsDirectory.appendingPathComponent("Downloads", isDirectory: true)
    }

    public var convertedDirectory: URL {
        documentsDirectory.appendingPathComponent("Converted", isDirectory: true)
    }

    private var metadataFileURL: URL {
        documentsDirectory.appendingPathComponent(".metadata.json")
    }

    private init() {
        createRequiredDirectories()
    }

    // MARK: - Setup Directory Hierarchy
    public func createRequiredDirectories() {
        let directories = [downloadsDirectory, convertedDirectory]
        for dir in directories {
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }

    // MARK: - File Moving & Saving
    public func saveDownloadedFile(from tempURL: URL, suggestedFilename: String) throws -> URL {
        createRequiredDirectories()
        let sanitizedName = sanitizeFilename(suggestedFilename)
        var destination = downloadsDirectory.appendingPathComponent(sanitizedName)

        // Tránh ghi đè file cũ nếu trùng tên
        destination = uniqueURL(for: destination)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: tempURL, to: destination)
        return destination
    }

    public func saveConvertedFile(from tempURL: URL, filename: String) throws -> URL {
        createRequiredDirectories()
        let sanitizedName = sanitizeFilename(filename)
        var destination = convertedDirectory.appendingPathComponent(sanitizedName)
        destination = uniqueURL(for: destination)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: tempURL, to: destination)
        return destination
    }

    // MARK: - Scan Local Media Items
    public func scanAllMediaItems() async -> [MediaItem] {
        var items: [MediaItem] = []
        let tagsMap = loadMetadataTags()

        let directories = [downloadsDirectory, convertedDirectory]
        for dir in directories {
            guard let enumerator = fileManager.enumerator(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .isRegularFileKey]),
                      resourceValues.isRegularFile == true else { continue }

                let filename = fileURL.lastPathComponent
                let fileSize = Int64(resourceValues.fileSize ?? 0)
                let creationDate = resourceValues.creationDate ?? Date()
                let relativePath = relativePath(from: fileURL)

                let ext = fileURL.pathExtension.lowercased()
                let mediaType: MediaType
                if ["mp4", "mov", "m4v", "mkv", "webm"].contains(ext) {
                    mediaType = .video
                } else if ["mp3", "m4a", "wav", "aac", "flac", "caf"].contains(ext) {
                    mediaType = .audio
                } else {
                    mediaType = .unknown
                }

                // Lấy thời lượng phát nếu là video/audio
                let duration = await extractDuration(for: fileURL)
                let tags = tagsMap[relativePath] ?? defaultTags(for: mediaType, in: dir)

                let item = MediaItem(
                    id: UUID(),
                    filename: filename,
                    localRelativePath: relativePath,
                    fileSize: fileSize,
                    duration: duration,
                    mediaType: mediaType,
                    createdDate: creationDate,
                    tags: tags
                )
                items.append(item)
            }
        }

        return items.sorted(by: { $0.createdDate > $1.createdDate })
    }

    // MARK: - File Operations
    public func deleteItem(_ item: MediaItem) throws {
        let url = item.fileURL
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        var tagsMap = loadMetadataTags()
        tagsMap.removeValue(forKey: item.localRelativePath)
        saveMetadataTags(tagsMap)
    }

    public func renameItem(_ item: MediaItem, to newName: String) throws -> MediaItem {
        let currentURL = item.fileURL
        let ext = currentURL.pathExtension
        let finalNewName = newName.hasSuffix(".\(ext)") ? newName : "\(newName).\(ext)"
        let newURL = currentURL.deletingLastPathComponent().appendingPathComponent(finalNewName)

        try fileManager.moveItem(at: currentURL, to: newURL)

        var tagsMap = loadMetadataTags()
        let oldPath = item.localRelativePath
        let newPath = relativePath(from: newURL)
        if let existingTags = tagsMap.removeValue(forKey: oldPath) {
            tagsMap[newPath] = existingTags
            saveMetadataTags(tagsMap)
        }

        var updatedItem = item
        updatedItem.filename = finalNewName
        updatedItem.localRelativePath = newPath
        return updatedItem
    }

    public func updateTags(for item: MediaItem, tags: Set<String>) {
        var tagsMap = loadMetadataTags()
        tagsMap[item.localRelativePath] = tags
        saveMetadataTags(tagsMap)
    }

    // MARK: - Storage Calculation
    public func totalStorageUsed() -> Int64 {
        var total: Int64 = 0
        let directories = [downloadsDirectory, convertedDirectory]
        for dir in directories {
            if let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                       let size = values.fileSize {
                        total += Int64(size)
                    }
                }
            }
        }
        return total
    }

    // MARK: - Private Helpers
    private func sanitizeFilename(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return name.components(separatedBy: invalidChars).joined(separator: "_")
    }

    private func uniqueURL(for url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }
        let dir = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let baseName = url.deletingPathExtension().lastPathComponent

        var counter = 1
        while true {
            let candidateName = "\(baseName)_\(counter).\(ext)"
            let candidateURL = dir.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }

    private func relativePath(from url: URL) -> String {
        let docPath = documentsDirectory.path
        let fullPath = url.path
        if fullPath.hasPrefix(docPath) {
            var rel = String(fullPath.dropFirst(docPath.count))
            if rel.hasPrefix("/") {
                rel.removeFirst()
            }
            return rel
        }
        return url.lastPathComponent
    }

    private func extractDuration(for url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        if #available(iOS 16.0, *) {
            do {
                let duration = try await asset.load(.duration)
                return CMTimeGetSeconds(duration)
            } catch {
                return 0
            }
        } else {
            return CMTimeGetSeconds(asset.duration)
        }
    }

    private func defaultTags(for type: MediaType, in dir: URL) -> Set<String> {
        var tags: Set<String> = []
        if type == .video { tags.insert("video") }
        if type == .audio { tags.insert("audio") }
        if dir.lastPathComponent == "Converted" { tags.insert("converted") }
        return tags
    }

    private func loadMetadataTags() -> [String: Set<String>] {
        guard fileManager.fileExists(atPath: metadataFileURL.path),
              let data = try? Data(contentsOf: metadataFileURL),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return decoded.mapValues { Set($0) }
    }

    private func saveMetadataTags(_ tagsMap: [String: Set<String>]) {
        let encodable = tagsMap.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encodable) {
            try? data.write(to: metadataFileURL, options: .atomic)
        }
    }
}
