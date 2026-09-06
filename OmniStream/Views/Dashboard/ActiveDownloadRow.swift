import SwiftUI

// MARK: - Active Download Row
public struct ActiveDownloadRow: View {
    public let item: DownloadTaskItem
    public let onPause: () -> Void
    public let onResume: () -> Void
    public let onCancel: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Tiêu đề & Nút điều khiển
            HStack(alignment: .top, spacing: 12) {
                // Icon trạng thái
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                        }

                    Image(systemName: statusIconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(statusIconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(item.status.statusDescription)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusTextColor)

                        if case .downloading = item.status {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(item.formattedSpeed)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                    }
                }

                Spacer()

                // Nút thao tác (Pause/Resume/Cancel)
                HStack(spacing: 6) {
                    switch item.status {
                    case .downloading:
                        controlButton(icon: "pause.fill", color: .orange, action: onPause)
                    case .paused:
                        controlButton(icon: "play.fill", color: .green, action: onResume)
                    default:
                        EmptyView()
                    }

                    controlButton(icon: "xmark", color: .secondary, action: onCancel)
                }
            }

            // Thanh tiến trình Glass ProgressBar
            if case .downloading(let p, _, _) = item.status {
                GlassProgressBar(progress: p)

                HStack {
                    Text(item.formattedProgressBytes)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)

                    Spacer()

                    if !item.formattedETA.isEmpty && item.formattedETA != "--:--" {
                        Text("Còn lại: \(item.formattedETA)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }

                    Text(item.formattedPercentage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                }
            } else if case .paused = item.status {
                GlassProgressBar(progress: item.progress)

                HStack {
                    Text(item.formattedProgressBytes)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Đã tạm dừng (\(item.formattedPercentage))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(14)
        .glassRow(cornerRadius: 18)
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.shared.touchLight()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1).allowsHitTesting(false))
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statusIconName: String {
        switch item.status {
        case .idle, .connecting: return "network"
        case .downloading: return "arrow.down"
        case .paused: return "pause"
        case .completed: return "checkmark"
        case .failed: return "exclamationmark.triangle"
        }
    }

    private var statusIconColor: Color {
        switch item.status {
        case .idle, .connecting: return .blue
        case .downloading: return .cyan
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }

    private var statusTextColor: Color {
        switch item.status {
        case .idle, .connecting: return .secondary
        case .downloading: return .primary
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
}
