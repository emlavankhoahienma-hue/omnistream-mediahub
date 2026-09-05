import SwiftUI
import Combine

// MARK: - Library View Model
@MainActor
public final class LibraryViewModel: ObservableObject {
    @Published public var mediaItems: [MediaItem] = []
    @Published public var selectedTagId: String = "all"
    @Published public var searchQuery: String = ""
    @Published public var isLoading: Bool = false
    @Published public var totalStorageUsed: Int64 = 0

    // Sheet điều khiển
    @Published public var selectedItemForDetail: MediaItem? = nil
    @Published public var itemToRename: MediaItem? = nil
    @Published public var renameInputText: String = ""
    @Published public var itemToShare: URL? = nil
    @Published public var alertMessage: String? = nil
    @Published public var showAlert: Bool = false

    public let tags: [MediaTag] = MediaTag.defaults
    private let storageManager = StorageManager.shared

    public init() {
        Task {
            await loadMediaItems()
        }
    }

    // MARK: - Load & Refresh Data
    public func loadMediaItems() async {
        isLoading = true
        let items = await storageManager.scanAllMediaItems()
        self.mediaItems = items
        self.totalStorageUsed = storageManager.totalStorageUsed()
        self.isLoading = false
    }

    // MARK: - Filtered Items
    public var filteredItems: [MediaItem] {
        mediaItems.filter { item in
            // Lọc theo từ khóa tìm kiếm
            let matchesQuery = searchQuery.isEmpty || item.filename.localizedCaseInsensitiveContains(searchQuery)

            // Lọc theo Tag
            let matchesTag: Bool
            switch selectedTagId {
            case "all":
                matchesTag = true
            case "video":
                matchesTag = item.mediaType == .video
            case "audio":
                matchesTag = item.mediaType == .audio
            case "converted":
                matchesTag = item.tags.contains("converted") || item.localRelativePath.contains("Converted")
            case "favorite":
                matchesTag = item.tags.contains("favorite")
            default:
                matchesTag = item.tags.contains(selectedTagId)
            }

            return matchesQuery && matchesTag
        }
    }

    // MARK: - File Actions
    public func deleteItem(_ item: MediaItem) {
        do {
            try storageManager.deleteItem(item)
            mediaItems.removeAll(where: { $0.id == item.id })
            totalStorageUsed = storageManager.totalStorageUsed()
            HapticFeedback.shared.touchLight()
        } catch {
            alertMessage = "Không thể xóa tệp: \(error.localizedDescription)"
            showAlert = true
            HapticFeedback.shared.notifyError()
        }
    }

    public func prepareRename(item: MediaItem) {
        self.itemToRename = item
        self.renameInputText = (item.filename as NSString).deletingPathExtension
    }

    public func commitRename() {
        guard let item = itemToRename, !renameInputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let updated = try storageManager.renameItem(item, to: renameInputText)
            if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
                mediaItems[index] = updated
            }
            self.itemToRename = nil
            self.renameInputText = ""
            HapticFeedback.shared.notifySuccess()
        } catch {
            alertMessage = "Không thể đổi tên: \(error.localizedDescription)"
            showAlert = true
            HapticFeedback.shared.notifyError()
        }
    }

    public func toggleFavorite(for item: MediaItem) {
        var updatedTags = item.tags
        if updatedTags.contains("favorite") {
            updatedTags.remove("favorite")
        } else {
            updatedTags.insert("favorite")
        }

        storageManager.updateTags(for: item, tags: updatedTags)
        if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
            mediaItems[index].tags = updatedTags
        }
        HapticFeedback.shared.touchLight()
    }

    public func saveToCameraRoll(item: MediaItem) {
        guard item.mediaType == .video else {
            alertMessage = "Chỉ có thể lưu tệp video vào Cuộn Camera."
            showAlert = true
            HapticFeedback.shared.notifyWarning()
            return
        }

        Task {
            do {
                try await PhotoLibraryManager.shared.saveVideoToCameraRoll(videoURL: item.fileURL)
                alertMessage = "Đã lưu video thành công vào Photos!"
                showAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}
