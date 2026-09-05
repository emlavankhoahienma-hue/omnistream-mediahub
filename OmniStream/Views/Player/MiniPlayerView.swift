import SwiftUI

// MARK: - Mini Player View
/// Thanh trình phát Mini dạng Liquid Glass nổi trên Tab Bar.
public struct MiniPlayerView: View {
    @ObservedObject public var viewModel: PlayerViewModel

    public var body: some View {
        if let item = viewModel.currentItem, viewModel.isMiniPlayerVisible {
            Button(action: {
                HapticFeedback.shared.touchSoft()
                viewModel.isFullScreenPresented = true
            }) {
                HStack(spacing: 12) {
                    // Icon đĩa quay hoặc video thumbnail
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)

                        Image(systemName: item.mediaType == .video ? "film" : "music.note")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Tên bài & thời gian
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.filename)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text(viewModel.formattedCurrentTime)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.cyan)

                            Text("/")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            Text(viewModel.formattedDuration)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Nút Play / Pause
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    // Nút Đóng mini player
                    Button(action: {
                        viewModel.closePlayer()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .liquidGlass(cornerRadius: 22, borderOpacity: 0.35, shadowRadius: 12, shadowY: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
