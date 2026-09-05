import Foundation
import SwiftUI

// MARK: - Download Speed Calculator Helper
private final class SpeedTracker {
    private var timestamps: [Date] = []
    private var byteCounts: [Int64] = []
    private let windowSeconds: TimeInterval = 2.0

    func register(bytes: Int64) -> (speed: Double, eta: TimeInterval, totalBytes: Int64) {
        let now = Date()
        timestamps.append(now)
        byteCounts.append(bytes)

        // Lọc các bản ghi cũ ngoài cửa sổ 2 giây
        while let firstTime = timestamps.first, now.timeIntervalSince(firstTime) > windowSeconds {
            timestamps.removeFirst()
            byteCounts.removeFirst()
        }

        guard timestamps.count > 1, let firstTime = timestamps.first, let firstBytes = byteCounts.first else {
            return (0, 0, 0)
        }

        let timeDelta = now.timeIntervalSince(firstTime)
        let byteDelta = bytes - firstBytes

        if timeDelta > 0 && byteDelta > 0 {
            let speed = Double(byteDelta) / timeDelta
            return (speed, 0, bytes)
        }

        return (0, 0, bytes)
    }
}

// MARK: - Download Manager
/// Quản lý toàn bộ vòng đời tải xuống ngầm (Background Downloads) qua URLSessionDownloadDelegate.

public final class DownloadManager: NSObject, ObservableObject {
    public static let shared = DownloadManager()

    @Published public private(set) var activeTasks: [UUID: DownloadTaskItem] = [:]
    @Published public var downloadOrder: [UUID] = []

    private var urlSession: URLSession!
    private var sessionTasks: [Int: UUID] = [:] // taskIdentifier -> Item UUID
    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]
    private var speedTrackers: [UUID: SpeedTracker] = [:]

    public var backgroundCompletionHandler: (() -> Void)?

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.omnistream.mediahub.background")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 3600

        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }

    // MARK: - Public API
    /// Bắt đầu một tiến trình tải mới
    @discardableResult
    public func startDownload(from url: URL, title: String? = nil) -> UUID {
        let id = UUID()
        let taskName = title ?? url.lastPathComponent
        var item = DownloadTaskItem(
            id: id,
            sourceURL: url,
            title: taskName.isEmpty ? "Media_Stream" : taskName,
            status: .connecting
        )

        let downloadTask = urlSession.downloadTask(with: url)
        item.taskIdentifier = downloadTask.taskIdentifier

        activeTasks[id] = item
        downloadOrder.insert(id, at: 0)
        sessionTasks[downloadTask.taskIdentifier] = id
        downloadTasks[id] = downloadTask
        speedTrackers[id] = SpeedTracker()

        downloadTask.resume()
        HapticFeedback.shared.touchMedium()
        return id
    }

    /// Tạm dừng tác vụ tải và trích xuất resumeData
    public func pauseDownload(id: UUID) {
        guard let task = downloadTasks[id] else { return }
        task.cancel { [weak self] resumeData in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if var item = self.activeTasks[id] {
                    item.status = .paused(resumeData: resumeData)
                    self.activeTasks[id] = item
                }
                self.downloadTasks.removeValue(forKey: id)
                HapticFeedback.shared.touchLight()
            }
        }
    }

    /// Tiếp tục tác vụ tải từ resumeData
    public func resumeDownload(id: UUID) {
        guard let item = activeTasks[id], case .paused(let resumeData) = item.status else { return }

        let resumedTask: URLSessionDownloadTask
        if let data = resumeData {
            resumedTask = urlSession.downloadTask(withResumeData: data)
        } else {
            resumedTask = urlSession.downloadTask(with: item.sourceURL)
        }

        var updated = item
        updated.taskIdentifier = resumedTask.taskIdentifier
        updated.status = .downloading(progress: updated.progress, speed: 0, eta: 0)
        activeTasks[id] = updated

        sessionTasks[resumedTask.taskIdentifier] = id
        downloadTasks[id] = resumedTask
        speedTrackers[id] = SpeedTracker()

        resumedTask.resume()
        HapticFeedback.shared.touchMedium()
    }

    /// Hủy tác vụ tải
    public func cancelDownload(id: UUID) {
        if let task = downloadTasks[id] {
            task.cancel()
            downloadTasks.removeValue(forKey: id)
        }
        activeTasks.removeValue(forKey: id)
        downloadOrder.removeAll(where: { $0 == id })
        speedTrackers.removeValue(forKey: id)
        HapticFeedback.shared.touchLight()
    }

    /// Xóa toàn bộ tác vụ đã kết thúc
    public func clearCompleted() {
        let completedIDs = activeTasks.values.filter({ $0.status.isTerminal }).map({ $0.id })
        for id in completedIDs {
            activeTasks.removeValue(forKey: id)
            downloadOrder.removeAll(where: { $0 == id })
            speedTrackers.removeValue(forKey: id)
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let id = sessionTasks[downloadTask.taskIdentifier], var item = activeTasks[id] else { return }

        let progress: Double
        if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            progress = 0.0
        }

        // Tính tốc độ trung bình trượt và thời gian còn lại (ETA)
        let tracker = speedTrackers[id] ?? SpeedTracker()
        speedTrackers[id] = tracker
        let speedInfo = tracker.register(bytes: totalBytesWritten)
        let currentSpeed = speedInfo.speed

        var eta: TimeInterval = 0
        if currentSpeed > 0 && totalBytesExpectedToWrite > totalBytesWritten {
            let remainingBytes = totalBytesExpectedToWrite - totalBytesWritten
            eta = Double(remainingBytes) / currentSpeed
        }

        item.bytesWritten = totalBytesWritten
        item.totalBytes = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : item.totalBytes
        item.progress = progress
        item.speedBytesPerSecond = currentSpeed
        item.etaSeconds = eta
        item.status = .downloading(progress: progress, speed: currentSpeed, eta: eta)

        activeTasks[id] = item
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let id = sessionTasks[downloadTask.taskIdentifier], var item = activeTasks[id] else { return }

        do {
            // Lưu tệp vào thư mục Downloads của Documents Sandbox
            let savedURL = try StorageManager.shared.saveDownloadedFile(
                from: location,
                suggestedFilename: item.title
            )

            item.progress = 1.0
            item.status = .completed(destinationURL: savedURL)
            activeTasks[id] = item
            HapticFeedback.shared.notifySuccess()
        } catch {
            item.status = .failed(error: error.localizedDescription)
            activeTasks[id] = item
            HapticFeedback.shared.notifyError()
        }

        downloadTasks.removeValue(forKey: id)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let id = sessionTasks[task.taskIdentifier] else { return }

        if let error = error {
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled {
                if var item = activeTasks[id] {
                    item.status = .failed(error: error.localizedDescription)
                    activeTasks[id] = item
                    HapticFeedback.shared.notifyError()
                }
            }
        }

        sessionTasks.removeValue(forKey: task.taskIdentifier)
        downloadTasks.removeValue(forKey: id)
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let handler = self.backgroundCompletionHandler {
                self.backgroundCompletionHandler = nil
                handler()
            }
        }
    }
}
