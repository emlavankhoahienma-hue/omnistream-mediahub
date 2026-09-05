import SwiftUI

// MARK: - Audio Extraction Configuration Card
public struct AudioExtractionCard: View {
    @Binding public var selectedFormat: AudioFormat
    @Binding public var selectedBitrate: AudioBitrate

    public var body: some View {
        GlassCard(cornerRadius: 22, borderOpacity: 0.35) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20))
                        .foregroundColor(.pink)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tách Âm Thanh Ngoại Tuyến")
                            .font(.system(size: 16, weight: .bold))
                        Text("Trích xuất không nén hoặc nén chất lượng cao")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Divider().background(Color.white.opacity(0.15))

                // Chọn Định dạng (Format)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ĐỊNH DẠNG XUẤT:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(AudioFormat.allCases) { format in
                            Button(action: {
                                HapticFeedback.shared.touchLight()
                                selectedFormat = format
                            }) {
                                Text(format.rawValue)
                                    .font(.system(size: 13, weight: selectedFormat == format ? .bold : .medium))
                                    .foregroundColor(selectedFormat == format ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background {
                                        if selectedFormat == format {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(selectedFormat == format ? 0.3 : 0.15), lineWidth: 1)
                                    }
                            }
                        }
                    }

                    Text(selectedFormat.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                // Chọn Tốc độ Bitrate (Bitrate Quality) - Ẩn nếu là WAV
                if selectedFormat != .wav {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CHẤT LƯỢNG BITRATE:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(AudioBitrate.allCases) { bitrate in
                                Button(action: {
                                    HapticFeedback.shared.touchLight()
                                    selectedBitrate = bitrate
                                }) {
                                    VStack(spacing: 3) {
                                        Text(bitrate.label)
                                            .font(.system(size: 13, weight: selectedBitrate == bitrate ? .bold : .semibold))
                                            .foregroundColor(selectedBitrate == bitrate ? .white : .primary)

                                        Text(bitrate.badge)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(selectedBitrate == bitrate ? .white.opacity(0.9) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background {
                                        if selectedBitrate == bitrate {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(selectedBitrate == bitrate ? 0.3 : 0.15), lineWidth: 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
