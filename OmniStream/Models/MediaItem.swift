import Foundation
import UIKit
import AVFoundation

// MARK: - Media Item Type
public enum MediaType: String, Codable {
    case video
    case audio
    case unknown

    public var systemIcon: String {
        switch self {
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .unknown: return "doc.fill"
        }
    }
}

// MARK: - Stored Media Item
public struct MediaItem: Identifiable, Hashable, Codable {
    public let id: UUID
    public var filename: String
    public var localRelativePath: String
    public var fileSize: Int64
    public var duration: TimeInterval
    public var mediaType: MediaType
    public var createdDate: Date
    public var tags: Set<String>

    public init(
        id: UUID = UUID(),
        filename: String,
        localRelativePath: String,
        fileSize: Int64 = 0,
        duration: TimeInterval = 0,
        mediaType: MediaType = .video,
        createdDate: Date = Date(),
        tags: Set<String> = []
    ) {
        self.id = id
        self.filename = filename
        self.localRelativePath = localRelativePath
        self.fileSize = fileSize
        self.duration = duration
        self.mediaType = mediaType
        self.createdDate = createdDate
        self.tags = tags
    }

    /// Đường dẫn file URL tuyệt đối trong Documents sandbox của phiên chạy hiện tại
    public var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(localRelativePath)
    }

    /// Định dạng dung lượng dễ đọc (KB, MB, GB)
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Định dạng thời lượng phát (MM:SS hoặc HH:MM:SS)
    public var formattedDuration: String {
        guard duration > 0 else { return "--:--" }
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Định dạng ngày tạo
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }

    /// Đuôi mở rộng của file
    public var fileExtension: String {
        fileURL.pathExtension.uppercased()
    }
}
