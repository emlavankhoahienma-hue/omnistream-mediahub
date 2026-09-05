import SwiftUI
import Combine

// MARK: - Dashboard View Model
@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var inputURL: String = ""
    @Published public var detectedClipboardURL: String? = nil
    @Published public var isAnalyzingURL: Bool = false
    @Published public var previewMetadata: URLMetadataPreview? = nil
    @Published public var showPreviewSheet: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorAlert: Bool = false

    public let downloadManager = DownloadManager.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        // Lắng nghe thay đổi từ DownloadManager để cập nhật View
        downloadManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Smart Clipboard Auto-Detection
    /// Tự động phát hiện URL trong Clipboard an toàn, hoàn toàn không làm nghẽn Main Thread
    public func checkClipboardForURL() {
        Task.detached(priority: .utility) {
            guard UIPasteboard.general.hasStrings else { return }
            guard let pasteboardString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

            if MetadataExtractor.shared.isValidURL(pasteboardString) {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if pasteboardString != self.inputURL && pasteboardString != self.detectedClipboardURL {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            self.detectedClipboardURL = pasteboardString
                        }
                    }
                }
            }
        }
    }

    /// Chấp nhận URL từ Clipboard
    public func acceptClipboardURL() {
        guard let url = detectedClipboardURL else { return }
        self.inputURL = url
        self.detectedClipboardURL = nil
        HapticFeedback.shared.touchMedium()
        analyzeCurrentURL()
    }

    /// Từ chối/bỏ qua URL Clipboard
    public func dismissClipboardURL() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.detectedClipboardURL = nil
        }
        HapticFeedback.shared.touchLight()
    }

    // MARK: - URL Analysis & Preview
    public func analyzeCurrentURL() {
        let trimmed = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard MetadataExtractor.shared.isValidURL(trimmed), let url = URL(string: trimmed) else {
            self.errorMessage = "URL không hợp lệ. Vui lòng nhập link HTTP hoặc HTTPS chính xác."
            self.showErrorAlert = true
            HapticFeedback.shared.notifyError()
            return
        }

        self.isAnalyzingURL = true
        HapticFeedback.shared.touchLight()

        Task {
            let preview = await MetadataExtractor.shared.extractPreview(for: url)
            self.previewMetadata = preview
            self.isAnalyzingURL = false
            self.showPreviewSheet = true
            HapticFeedback.shared.touchSoft()
        }
    }

    // MARK: - Download Triggers
    public func confirmAndStartDownload() {
        guard let preview = previewMetadata else { return }
        downloadManager.startDownload(from: preview.url, title: preview.title)
        self.showPreviewSheet = false
        self.inputURL = ""
        self.previewMetadata = nil
        HapticFeedback.shared.notifySuccess()
    }

    public func directDownload() {
        let trimmed = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return }
        downloadManager.startDownload(from: url)
        self.inputURL = ""
    }

    public var activeTasksList: [DownloadTaskItem] {
        return downloadManager.downloadOrder.compactMap { downloadManager.activeTasks[$0] }
    }
}
