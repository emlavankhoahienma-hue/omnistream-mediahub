import Foundation

// MARK: - Download Task Status
public enum DownloadStatus: Equatable {
    case idle
    case connecting
    case downloading(progress: Double, speed: Double, eta: TimeInterval)
    case paused(resumeData: Data?)
    case completed(destinationURL: URL)
    case failed(error: String)

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed: return true
        default: return false
        }
    }

    public var statusDescription: String {
        switch self {
        case .idle:
            return "Đang chờ"
        case .connecting:
            return "Đang kết nối..."
        case .downloading:
            return "Đang tải xuống"
        case .paused:
            return "Tạm dừng"
        case .completed:
            return "Hoàn tất"
        case .failed(let err):
            return "Thất bại: \(err)"
        }
    }
}

// MARK: - Download Task Item
public struct DownloadTaskItem: Identifiable, Equatable {
    public let id: UUID
    public let sourceURL: URL
    public var title: String
    public var totalBytes: Int64
    public var bytesWritten: Int64
    public var progress: Double
    public var speedBytesPerSecond: Double
    public var etaSeconds: TimeInterval
    public var status: DownloadStatus
    public var thumbnailURL: URL?
    public var taskIdentifier: Int?

    public init(
        id: UUID = UUID(),
        sourceURL: URL,
        title: String? = nil,
        totalBytes: Int64 = 0,
        bytesWritten: Int64 = 0,
        progress: Double = 0.0,
        speedBytesPerSecond: Double = 0.0,
        etaSeconds: TimeInterval = 0.0,
        status: DownloadStatus = .idle,
        thumbnailURL: URL? = nil,
        taskIdentifier: Int? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.title = title ?? sourceURL.lastPathComponent
        self.totalBytes = totalBytes
        self.bytesWritten = bytesWritten
        self.progress = progress
        self.speedBytesPerSecond = speedBytesPerSecond
        self.etaSeconds = etaSeconds
        self.status = status
        self.thumbnailURL = thumbnailURL
        self.taskIdentifier = taskIdentifier
    }

    /// Định dạng tiến trình % (ví dụ: 45.2%)
    public var formattedPercentage: String {
        return String(format: "%.1f%%", progress * 100.0)
    }

    /// Định dạng tốc độ tải (KB/s hoặc MB/s)
    public var formattedSpeed: String {
        guard speedBytesPerSecond > 0 else { return "-- KB/s" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(speedBytesPerSecond)))/s"
    }

    /// Định dạng dung lượng đã tải / tổng dung lượng
    public var formattedProgressBytes: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file

        let written = formatter.string(fromByteCount: bytesWritten)
        if totalBytes > 0 {
            let total = formatter.string(fromByteCount: totalBytes)
            return "\(written) / \(total)"
        } else {
            return written
        }
    }

    /// Định dạng thời gian ước tính còn lại (ETA)
    public var formattedETA: String {
        guard etaSeconds > 0 && etaSeconds.isFinite else { return "--:--" }
        let total = Int(etaSeconds)
        let mins = total / 60
        let secs = total % 60
        if mins > 60 {
            let hours = mins / 60
            let remainMins = mins % 60
            return "\(hours)h \(remainMins)m"
        }
        return String(format: "%02d:%02d", mins, secs)
    }

    public static func == (lhs: DownloadTaskItem, rhs: DownloadTaskItem) -> Bool {
        return lhs.id == rhs.id && lhs.progress == rhs.progress && lhs.status == rhs.status
    }
}
