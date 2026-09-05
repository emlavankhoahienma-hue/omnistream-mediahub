import SwiftUI

// MARK: - URL Input Card View
public struct URLInputCardView: View {
    @ObservedObject public var viewModel: DashboardViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Banner gợi ý URL từ Clipboard (nếu phát hiện)
            if let clipboardURL = viewModel.detectedClipboardURL {
                clipboardBanner(url: clipboardURL)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Input field
            GlassTextField(
                "Dán link video, stream hoặc âm thanh...",
                text: $viewModel.inputURL,
                icon: "arrow.down.doc.fill",
                onPasteAction: {
                    if let string = UIPasteboard.general.string {
                        viewModel.inputURL = string
                        viewModel.analyzeCurrentURL()
                    }
                }
            )

            // Nút bấm phân tích & tải xuống
            HStack(spacing: 12) {
                if viewModel.isAnalyzingURL {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Text("Đang phân tích link...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                } else {
                    GlassButton(
                        "Phân Tích & Tải",
                        icon: "sparkles",
                        style: .vibrantGradient
                    ) {
                        viewModel.analyzeCurrentURL()
                    }
                    .disabled(viewModel.inputURL.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(viewModel.inputURL.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.35)
    }

    // MARK: - Clipboard Banner
    private func clipboardBanner(url: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundColor(.cyan)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("Phát hiện link từ Clipboard")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)

                Text(url)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                viewModel.acceptClipboardURL()
            }) {
                Text("Dùng")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }

            Button(action: {
                viewModel.dismissClipboardURL()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                }
        }
    }
}
