import SwiftUI
import AVFoundation
import Combine

// MARK: - Player View Model
@MainActor
public final class PlayerViewModel: ObservableObject {
    public static let shared = PlayerViewModel()

    @Published public var currentItem: MediaItem? = nil
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var isMiniPlayerVisible: Bool = false
    @Published public var isFullScreenPresented: Bool = false

    public var player: AVPlayer? = nil
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .defaultToSpeaker])
        } catch {
            print("Audio Session error: \(error)")
        }
    }

    // MARK: - Playback Control
    public func play(item: MediaItem) {
        try? AVAudioSession.sharedInstance().setActive(true)
        if currentItem?.id == item.id && player != nil {
            player?.play()
            isPlaying = true
            isMiniPlayerVisible = true
            return
        }

        cleanupCurrentPlayer()

        self.currentItem = item
        let playerItem = AVPlayerItem(url: item.fileURL)
        self.player = AVPlayer(playerItem: playerItem)

        setupTimeObserver()

        player?.play()
        self.isPlaying = true
        self.isMiniPlayerVisible = true
        HapticFeedback.shared.touchSoft()
    }

    public func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        HapticFeedback.shared.touchLight()
    }

    public func seek(to time: TimeInterval) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    public func skipForward(_ seconds: Double = 15) {
        seek(to: min(duration, currentTime + seconds))
        HapticFeedback.shared.touchLight()
    }

    public func skipBackward(_ seconds: Double = 15) {
        seek(to: max(0, currentTime - seconds))
        HapticFeedback.shared.touchLight()
    }

    public func closePlayer() {
        cleanupCurrentPlayer()
        currentItem = nil
        isPlaying = false
        isMiniPlayerVisible = false
        isFullScreenPresented = false
        HapticFeedback.shared.touchLight()
    }

    // MARK: - Time Observation
    private func setupTimeObserver() {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let seconds = CMTimeGetSeconds(time)
                if seconds.isFinite {
                    self.currentTime = seconds
                }

                if let itemDuration = self.player?.currentItem?.duration {
                    let d = CMTimeGetSeconds(itemDuration)
                    if d.isFinite && d > 0 {
                        self.duration = d
                    }
                }
            }
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            .sink { [weak self] _ in
                self?.isPlaying = false
                self?.currentTime = 0
                self?.player?.seek(to: .zero)
            }
            .store(in: &cancellables)
    }

    private func cleanupCurrentPlayer() {
        if let token = timeObserverToken, let p = player {
            p.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        currentTime = 0
        duration = 0
    }

    // MARK: - Helper Formatters
    public var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    public var formattedDuration: String {
        formatTime(duration)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds > 0 && seconds.isFinite else { return "00:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
