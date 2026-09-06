import SwiftUI

// MARK: - URL Input Card View
public struct URLInputCardView: View {
    @ObservedObject public var viewModel: DashboardViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Input field
            GlassTextField(
                "Dán link video, stream hoặc âm thanh...",
                text: $viewModel.inputURL,
                icon: "arrow.down.doc.fill",
                onPasteAction: {
                    viewModel.pasteFromClipboard()
                }
            )

            // Nút bấm phân tích & Trình duyệt bắt link
            if viewModel.isAnalyzingURL {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    Text("Đang phân tích luồng video...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                VStack(spacing: 10) {
                    GlassButton(
                        "Phân Tích & Tải",
                        icon: "sparkles",
                        style: .vibrantGradient
                    ) {
                        viewModel.analyzeCurrentURL()
                    }
                    .disabled(viewModel.inputURL.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(viewModel.inputURL.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)

                    GlassButton(
                        "Trình Duyệt Bắt Link Video",
                        icon: "globe.americas.fill",
                        style: .frosted
                    ) {
                        viewModel.openWebBrowser()
                    }
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.35)
    }
}
