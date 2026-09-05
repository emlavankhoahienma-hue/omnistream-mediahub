import SwiftUI

// MARK: - Media Detail Sheet
public struct MediaDetailSheet: View {
    public let item: MediaItem
    public let onSaveToPhotos: () -> Void
    public let onShare: () -> Void
    public let onRename: () -> Void
    public let onDelete: () -> Void
    public let onDismiss: () -> Void

    public var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 20) {
                // Drag indicator
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thông Tin Tệp")
                            .font(.system(size: 20, weight: .bold))
                        Text(item.filename)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Inspector Card
                GlassCard(cornerRadius: 20, borderOpacity: 0.35) {
                    VStack(spacing: 12) {
                        infoRow(label: "Loại tệp:", value: item.fileExtension)
                        Divider().background(Color.white.opacity(0.1))
                        infoRow(label: "Dung lượng:", value: item.formattedFileSize)
                        Divider().background(Color.white.opacity(0.1))
                        infoRow(label: "Thời lượng:", value: item.formattedDuration)
                        Divider().background(Color.white.opacity(0.1))
                        infoRow(label: "Ngày tạo:", value: item.formattedDate)
                        Divider().background(Color.white.opacity(0.1))
                        infoRow(label: "Đường dẫn Documents:", value: item.localRelativePath)
                    }
                }
                .padding(.horizontal, 20)

                // Hành động
                VStack(spacing: 10) {
                    if item.mediaType == .video {
                        GlassButton("Lưu vào Cuộn Camera (Photos)", icon: "photo.badge.plus", style: .vibrantGradient) {
                            onSaveToPhotos()
                        }
                    }

                    GlassButton("Chia Sẻ / AirDrop", icon: "square.and.arrow.up", style: .frosted) {
                        onShare()
                    }

                    GlassButton("Đổi Tên Tệp", icon: "pencil", style: .frosted) {
                        onRename()
                    }

                    GlassButton("Xóa Tệp", icon: "trash", style: .destructive) {
                        onDelete()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
