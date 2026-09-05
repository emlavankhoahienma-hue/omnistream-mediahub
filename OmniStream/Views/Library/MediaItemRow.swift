import SwiftUI

// MARK: - Media Item Row
public struct MediaItemRow: View {
    public let item: MediaItem
    public let onPlay: () -> Void
    public let onToggleFavorite: () -> Void
    public let onSaveToPhotos: () -> Void
    public let onRename: () -> Void
    public let onShare: () -> Void
    public let onDelete: () -> Void

    public var body: some View {
        Button(action: {
            HapticFeedback.shared.touchSoft()
            onPlay()
        }) {
            HStack(spacing: 12) {
                // Media Icon / Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(item.mediaType == .video ? Color.blue.opacity(0.15) : Color.pink.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }

                    Image(systemName: item.mediaType.systemIcon)
                        .font(.system(size: 20))
                        .foregroundColor(item.mediaType == .video ? .blue : .pink)
                }

                // Thông tin tệp
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.filename)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(item.formattedFileSize)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(item.formattedDuration)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(item.fileExtension)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    }

                    // Tags
                    if !item.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(item.tags).prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // Nút Menu Tác Vụ & Yêu thích
                HStack(spacing: 8) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: item.tags.contains("favorite") ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(item.tags.contains("favorite") ? .orange : .secondary.opacity(0.5))
                    }

                    Menu {
                        if item.mediaType == .video {
                            Button(action: onSaveToPhotos) {
                                Label("Lưu vào Photos (Cuộn Camera)", systemImage: "photo.badge.plus")
                            }
                        }

                        Button(action: onShare) {
                            Label("Chia sẻ / AirDrop", systemImage: "square.and.arrow.up")
                        }

                        Button(action: onRename) {
                            Label("Đổi tên tệp", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive, action: onDelete) {
                            Label("Xóa khỏi thiết bị", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 16, borderOpacity: 0.25)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
