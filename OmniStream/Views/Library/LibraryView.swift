import SwiftUI

// MARK: - Activity View Controller Wrapper for Sharing
public struct ActivityView: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Library View
public struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @ObservedObject private var playerViewModel = PlayerViewModel.shared
    @State private var showingRenameDialog = false

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar
            headerBar
                .padding(.horizontal, 18)
                .padding(.top, 10)

            // Search Bar
            GlassTextField("Tìm kiếm tệp media...", text: $viewModel.searchQuery, icon: "magnifyingglass")
                .padding(.horizontal, 18)

            // Tag Filter Pills
            TagFilterBar(tags: viewModel.tags, selectedTagId: $viewModel.selectedTagId)
                .padding(.horizontal, 18)

            // Danh sách tệp
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.filteredItems.isEmpty {
                emptyLibraryPlaceholder
                Spacer()
            } else {
                mediaList
            }
        }
        .sheet(item: $viewModel.selectedItemForDetail) { item in
            MediaDetailSheet(
                item: item,
                onSaveToPhotos: {
                    viewModel.selectedItemForDetail = nil
                    viewModel.saveToCameraRoll(item: item)
                },
                onShare: {
                    viewModel.selectedItemForDetail = nil
                    viewModel.itemToShare = item.fileURL
                },
                onRename: {
                    viewModel.selectedItemForDetail = nil
                    viewModel.prepareRename(item: item)
                    showingRenameDialog = true
                },
                onDelete: {
                    viewModel.selectedItemForDetail = nil
                    viewModel.deleteItem(item)
                },
                onDismiss: {
                    viewModel.selectedItemForDetail = nil
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { viewModel.itemToShare != nil },
            set: { if !$0 { viewModel.itemToShare = nil } }
        )) {
            if let shareURL = viewModel.itemToShare {
                ActivityView(activityItems: [shareURL])
            }
        }
        .alert("Đổi Tên Tệp", isPresented: $showingRenameDialog) {
            TextField("Tên mới", text: $viewModel.renameInputText)
            Button("Lưu", action: { viewModel.commitRename() })
            Button("Hủy", role: .cancel, action: { viewModel.itemToRename = nil })
        } message: {
            Text("Nhập tên mới cho tệp đa phương tiện này.")
        }
        .alert("Thông Báo", isPresented: $viewModel.showAlert) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .onAppear {
            Task { await viewModel.loadMediaItems() }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kho Phương Tiện")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.primary, .cyan], startPoint: .leading, endPoint: .trailing)
                    )

                Text("Quản lý tệp cục bộ trong Files App")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Dung lượng đã dùng
            VStack(alignment: .trailing, spacing: 2) {
                Text("Đã dùng")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(formatByteCount(viewModel.totalStorageUsed))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassCapsule(borderOpacity: 0.25)
        }
    }

    // MARK: - Media List
    private var mediaList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredItems) { item in
                    MediaItemRow(
                        item: item,
                        onPlay: {
                            playerViewModel.play(item: item)
                        },
                        onToggleFavorite: {
                            viewModel.toggleFavorite(for: item)
                        },
                        onSaveToPhotos: {
                            viewModel.saveToCameraRoll(item: item)
                        },
                        onRename: {
                            viewModel.prepareRename(item: item)
                            showingRenameDialog = true
                        },
                        onShare: {
                            viewModel.itemToShare = item.fileURL
                        },
                        onDelete: {
                            viewModel.deleteItem(item)
                        }
                    )
                }

                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 18)
        }
        .refreshable {
            await viewModel.loadMediaItems()
        }
    }

    // MARK: - Empty Placeholder
    private var emptyLibraryPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Không có tệp phù hợp")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Các video và bài nhạc tải về hoặc chuyển đổi sẽ xuất hiện tại đây.")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func formatByteCount(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
