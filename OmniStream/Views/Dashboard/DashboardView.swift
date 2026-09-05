import SwiftUI

// MARK: - Dashboard View
public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Bar
                headerBar
                    .padding(.top, 10)

                // Card nhập URL & phát hiện clipboard
                URLInputCardView(viewModel: viewModel)

                // Danh sách tác vụ đang tải
                activeTasksSection

                // Khoảng trống dưới đáy để không bị che bởi tab bar và mini player
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 18)
        }
        .sheet(isPresented: $viewModel.showPreviewSheet) {
            if let preview = viewModel.previewMetadata {
                URLPreviewModal(
                    preview: preview,
                    onConfirm: {
                        viewModel.confirmAndStartDownload()
                    },
                    onDismiss: {
                        viewModel.showPreviewSheet = false
                    }
                )
            }
        }
        .alert("Thông Báo", isPresented: $viewModel.showErrorAlert) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.checkClipboardForURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.checkClipboardForURL()
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("OmniStream")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Capsule())
                }

                Text("Media Hub & Downloader Pipeline")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Trạng thái mạng / Sideload badge
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Native Engine")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassCapsule(borderOpacity: 0.2)
        }
    }

    // MARK: - Active Tasks Section
    private var activeTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tác Vụ Tải Xuống (\(viewModel.activeTasksList.count))")
                    .font(.system(size: 17, weight: .bold))

                Spacer()

                if !viewModel.activeTasksList.isEmpty {
                    Button(action: {
                        viewModel.downloadManager.clearCompleted()
                    }) {
                        Text("Dọn dẹp")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }

            if viewModel.activeTasksList.isEmpty {
                emptyDownloadsPlaceholder
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.activeTasksList) { task in
                        ActiveDownloadRow(
                            item: task,
                            onPause: { viewModel.downloadManager.pauseDownload(id: task.id) },
                            onResume: { viewModel.downloadManager.resumeDownload(id: task.id) },
                            onCancel: { viewModel.downloadManager.cancelDownload(id: task.id) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Empty Downloads Placeholder
    private var emptyDownloadsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 16)

            Text("Chưa có tác vụ tải nào")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Dán liên kết video hoặc audio phía trên để bắt đầu tải nền tốc độ cao.")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .liquidGlass(cornerRadius: 20, borderOpacity: 0.2)
    }
}
