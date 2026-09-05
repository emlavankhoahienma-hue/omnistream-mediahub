import SwiftUI
import AVKit

// MARK: - Full Player Modal
public struct FullPlayerModal: View {
    @ObservedObject public var viewModel: PlayerViewModel
    @State private var isScrubbing: Bool = false
    @State private var scrubValue: Double = 0.0

    public var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 24) {
                // Top Grabber & Close
                HStack {
                    Button(action: {
                        HapticFeedback.shared.touchSoft()
                        viewModel.isFullScreenPresented = false
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(viewModel.currentItem?.mediaType == .video ? "Video Player" : "Audio Player")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Media Stage (Video Player vs Audio Visualizer)
                if let item = viewModel.currentItem {
                    if item.mediaType == .video, let player = viewModel.player {
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                            .padding(.horizontal, 16)
                    } else {
                        audioArtworkVisualizer(filename: item.filename)
                    }
                }

                // File Info
                VStack(spacing: 6) {
                    Text(viewModel.currentItem?.filename ?? "Đang phát")
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text(viewModel.currentItem?.formattedFileSize ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Scrub Bar
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { isScrubbing ? scrubValue : viewModel.currentTime },
                            set: { newValue in
                                scrubValue = newValue
                            }
                        ),
                        in: 0...max(1.0, viewModel.duration),
                        onEditingChanged: { editing in
                            isScrubbing = editing
                            if !editing {
                                viewModel.seek(to: scrubValue)
                            }
                        }
                    )
                    .tint(.cyan)

                    HStack {
                        Text(viewModel.formattedCurrentTime)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formattedDuration)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                // Controls: -15s, Play/Pause, +15s
                HStack(spacing: 40) {
                    Button(action: {
                        viewModel.skipBackward(15)
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 26))
                            .foregroundColor(.primary)
                    }

                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: Color.cyan.opacity(0.4), radius: 16, x: 0, y: 4)
                    }

                    Button(action: {
                        viewModel.skipForward(15)
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 26))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Audio Artwork Visualizer
    private func audioArtworkVisualizer(filename: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: 240, height: 240)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.4), .cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.blue.opacity(0.2), radius: 25, x: 0, y: 10)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.pink.opacity(0.4), radius: 14, x: 0, y: 6)

                    Image(systemName: "music.note")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }

                HStack(spacing: 4) {
                    ForEach(0..<7) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cyan)
                            .frame(width: 4, height: viewModel.isPlaying ? CGFloat([24, 40, 16, 32, 48, 20, 36][index]) : 8)
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(index) * 0.08), value: viewModel.isPlaying)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
}
