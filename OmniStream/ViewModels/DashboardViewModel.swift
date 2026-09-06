import SwiftUI
import Combine

// MARK: - Dashboard View Model
@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var inputURL: String = ""
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

    // MARK: - Safe User-Triggered Clipboard Paste
    /// Dán URL từ Clipboard an toàn khi người dùng bấm nút Dán (chạy trên MainActor, hoàn toàn không nghẽn hệ thống)
    public func pasteFromClipboard() {
        guard UIPasteboard.general.hasStrings,
              let pasteboardString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasteboardString.isEmpty else {
            return
        }

        self.inputURL = pasteboardString
        HapticFeedback.shared.touchMedium()
        analyzeCurrentURL()
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
