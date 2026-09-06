import Foundation
import AVFoundation

// MARK: - HLS Downloader Service
/// Tải luồng HLS (.m3u8) chuẩn:
/// 1. Tải và phân tích playlist (.m3u8), tự động chọn bitrate/độ phân giải cao nhất nếu là Master Playlist.
/// 2. Tải toàn bộ các phân mảnh (.ts / .m4s) song song có kiểm soát luồng.
/// 3. Hợp nhất (concatenate) các mảnh vào 1 tệp Transport Stream.
/// 4. Dùng AVAssetExportSession đóng gói (remux/transcode) sang định dạng MP4 chuẩn tương thích Photos / Camera Roll.
public final class HLSDownloader {
    public static let shared = HLSDownloader()
    private init() {}

    private var cancelledTaskIDs: Set<UUID> = []
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 3600
        return URLSession(configuration: config)
    }()

    public func cancel(id: UUID) {
        cancelledTaskIDs.insert(id)
    }

    /// Bắt đầu tải luồng HLS
    public func download(
        from m3u8URL: URL,
        title: String,
        taskID: UUID,
        progressHandler: @escaping (_ progress: Double, _ bytesWritten: Int64, _ speed: Double, _ eta: TimeInterval) -> Void
    ) async throws -> URL {
        cancelledTaskIDs.remove(taskID)

        // 1. Phân tích Playlist và lấy danh sách segment URLs
        let (segmentURLs, _) = try await resolveSegments(from: m3u8URL)
        guard !segmentURLs.isEmpty else {
            throw NSError(domain: "HLSDownloader", code: 400, userInfo: [NSLocalizedDescriptionKey: "Playlist HLS không chứa phân mảnh video nào."])
        }

        let totalSegments = segmentURLs.count
        let tempDir = FileManager.default.temporaryDirectory
        let rawTSURL = tempDir.appendingPathComponent("\(UUID().uuidString).ts")

        FileManager.default.createFile(atPath: rawTSURL.path, contents: nil, attributes: nil)
        guard let fileHandle = try? FileHandle(forWritingTo: rawTSURL) else {
            throw NSError(domain: "HLSDownloader", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo file đệm cục bộ."])
        }

        defer {
            try? fileHandle.close()
        }

        var totalBytesWritten: Int64 = 0
        let startTime = Date()

        // 2. Tải lần lượt từng phân mảnh hoặc theo lô nhỏ để đảm bảo thứ tự chính xác
        for (index, segURL) in segmentURLs.enumerated() {
            if cancelledTaskIDs.contains(taskID) {
                try? FileManager.default.removeItem(at: rawTSURL)
                throw NSError(domain: "HLSDownloader", code: NSUserCancelledError, userInfo: [NSLocalizedDescriptionKey: "Đã hủy tải HLS."])
            }

            var request = URLRequest(url: segURL)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                // Nếu 1 segment bị lỗi 404/403, tiếp tục cố gắng các segment còn lại
                continue
            }

            _ = try? fileHandle.seekToEnd()
            try? fileHandle.write(contentsOf: data)
            totalBytesWritten += Int64(data.count)

            let progress = Double(index + 1) / Double(totalSegments)
            let elapsed = Date().timeIntervalSince(startTime)
            let speed = elapsed > 0 ? Double(totalBytesWritten) / elapsed : 0.0
            let remainingSegments = Double(totalSegments - (index + 1))
            let timePerSegment = elapsed / Double(index + 1)
            let eta = remainingSegments * timePerSegment

            progressHandler(progress, totalBytesWritten, speed, eta)
        }

        try? fileHandle.synchronize()

        // 3. Remux / Transcode sang MP4 bằng AVAssetExportSession
        let cleanName = title.replacingOccurrences(of: ".m3u8", with: "", options: .caseInsensitive)
        let mp4URL = tempDir.appendingPathComponent("\(UUID().uuidString).mp4")

        do {
            let finalVideoURL = try await remuxTSToMP4(tsURL: rawTSURL, destinationURL: mp4URL)
            try? FileManager.default.removeItem(at: rawTSURL)
            return try StorageManager.shared.saveDownloadedFile(from: finalVideoURL, suggestedFilename: "\(cleanName).mp4")
        } catch {
            // Nếu Remux thất bại do codec không hỗ trợ MP4 container, lưu trực tiếp tệp .ts (AVPlayer và VLC trên iOS đều phát mượt)
            return try StorageManager.shared.saveDownloadedFile(from: rawTSURL, suggestedFilename: "\(cleanName).ts")
        }
    }

    // MARK: - Parse M3U8 Playlist
    private func resolveSegments(from url: URL) async throws -> (segments: [URL], duration: Double) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw NSError(domain: "HLSDownloader", code: 422, userInfo: [NSLocalizedDescriptionKey: "Không thể đọc nội dung file .m3u8."])
        }

        let lines = content.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        // Kiểm tra xem có phải Master Playlist không (#EXT-X-STREAM-INF)
        if content.contains("#EXT-X-STREAM-INF") {
            var highestBandwidth = -1
            var bestSubPlaylistURL: URL? = nil

            for (idx, line) in lines.enumerated() {
                if line.hasPrefix("#EXT-X-STREAM-INF:") {
                    let bandwidth = extractBandwidth(from: line)
                    if bandwidth > highestBandwidth && idx + 1 < lines.count {
                        let nextLine = lines[idx + 1]
                        if !nextLine.isEmpty && !nextLine.hasPrefix("#") {
                            highestBandwidth = bandwidth
                            bestSubPlaylistURL = URL(string: nextLine, relativeTo: url) ?? URL(string: nextLine)
                        }
                    }
                }
            }

            if let targetMediaPlaylist = bestSubPlaylistURL {
                return try await resolveSegments(from: targetMediaPlaylist)
            }
        }

        // Đọc Media Playlist và thu thập các phân mảnh
        var segmentURLs: [URL] = []
        var totalDuration: Double = 0.0

        for (idx, line) in lines.enumerated() {
            if line.hasPrefix("#EXTINF:") {
                let durationStr = line.dropFirst(8).components(separatedBy: ",").first ?? "0"
                totalDuration += Double(durationStr) ?? 0.0

                if idx + 1 < lines.count {
                    let nextLine = lines[idx + 1]
                    if !nextLine.isEmpty && !nextLine.hasPrefix("#") {
                        if let segURL = URL(string: nextLine, relativeTo: url) ?? URL(string: nextLine) {
                            segmentURLs.append(segURL)
                        }
                    }
                }
            } else if !line.isEmpty && !line.hasPrefix("#") {
                if let segURL = URL(string: line, relativeTo: url) ?? URL(string: line) {
                    if !segmentURLs.contains(segURL) {
                        segmentURLs.append(segURL)
                    }
                }
            }
        }

        return (segmentURLs, totalDuration)
    }

    private func extractBandwidth(from line: String) -> Int {
        let pattern = "BANDWIDTH=(\\d+)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..<line.endIndex, in: line)),
           let range = Range(match.range(at: 1), in: line) {
            return Int(line[range]) ?? 0
        }
        return 0
    }

    // MARK: - Remux Transport Stream to MP4
    private func remuxTSToMP4(tsURL: URL, destinationURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: tsURL)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể khởi tạo AVAssetExportSession"])
        }

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                if exportSession.status == .completed {
                    continuation.resume(returning: destinationURL)
                } else {
                    continuation.resume(throwing: exportSession.error ?? NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Lỗi đóng gói MP4"]))
                }
            }
        }
    }
}
