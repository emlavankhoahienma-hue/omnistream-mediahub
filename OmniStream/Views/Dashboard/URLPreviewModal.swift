import SwiftUI

// MARK: - URL Preview Modal
public struct URLPreviewModal: View {
    public let preview: URLMetadataPreview
    public let onConfirm: () -> Void
    public let onDismiss: () -> Void

    public var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 24) {
                // Header Sheet
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Xác Nhận Tải Xuống")
                            .font(.system(size: 20, weight: .bold))
                        Text("Kiểm tra thông tin trước khi bắt đầu pipeline")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Glass Card thông tin tệp
                GlassCard(cornerRadius: 22, borderOpacity: 0.4) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 54, height: 54)

                                Image(systemName: preview.isDirectMedia ? "film.fill" : "globe")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(preview.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .lineLimit(2)

                                HStack(spacing: 8) {
                                    Text(preview.estimatedFormat)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue)
                                        .clipShape(Capsule())

                                    Text(preview.formattedSize)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.15))

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Nguồn URL:", systemImage: "link")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(preview.url.absoluteString)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.primary.opacity(0.85))
                                .lineLimit(3)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Nút hành động
                VStack(spacing: 12) {
                    GlassButton("Bắt Đầu Tải Xuống", icon: "arrow.down.circle.fill", style: .vibrantGradient) {
                        onConfirm()
                    }

                    GlassButton("Hủy Bỏ", style: .frosted) {
                        onDismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}
