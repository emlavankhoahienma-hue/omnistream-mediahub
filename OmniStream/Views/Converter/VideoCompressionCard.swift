import SwiftUI

// MARK: - Video Compression Configuration Card
public struct VideoCompressionCard: View {
    @Binding public var selectedCodec: VideoCodec
    @Binding public var selectedQuality: VideoQualityTarget

    public var body: some View {
        GlassCard(cornerRadius: 22, borderOpacity: 0.35) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nén & Chuyển Đổi Video")
                            .font(.system(size: 16, weight: .bold))
                        Text("Giảm dung lượng vượt trội với phần cứng Apple Silicon")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Divider().background(Color.white.opacity(0.15))

                // Chọn Chuẩn nén (Codec)
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHUẨN MÃ HÓA (CODEC):")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        ForEach(VideoCodec.allCases) { codec in
                            Button(action: {
                                HapticFeedback.shared.touchLight()
                                selectedCodec = codec
                            }) {
                                VStack(spacing: 4) {
                                    Text(codec.rawValue)
                                        .font(.system(size: 13, weight: selectedCodec == codec ? .bold : .medium))
                                        .foregroundColor(selectedCodec == codec ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background {
                                    if selectedCodec == codec {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    }
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(selectedCodec == codec ? 0.3 : 0.15), lineWidth: 1)
                                }
                            }
                        }
                    }

                    Text(selectedCodec.compressionDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                // Chọn Độ phân giải mục tiêu
                VStack(alignment: .leading, spacing: 8) {
                    Text("ĐỘ PHÂN GIẢI MỤC TIÊU:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(VideoQualityTarget.allCases) { quality in
                            Button(action: {
                                HapticFeedback.shared.touchLight()
                                selectedQuality = quality
                            }) {
                                Text(quality.rawValue)
                                    .font(.system(size: 12, weight: selectedQuality == quality ? .bold : .medium))
                                    .foregroundColor(selectedQuality == quality ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background {
                                        if selectedQuality == quality {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(selectedQuality == quality ? 0.3 : 0.15), lineWidth: 1)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
}
