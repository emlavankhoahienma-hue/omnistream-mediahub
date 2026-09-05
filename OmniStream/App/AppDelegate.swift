import UIKit
import AVFoundation

// MARK: - App Delegate
/// Quản lý vòng đời cấp thấp của iOS, đặc biệt là background URLSession completion.

public final class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Cấu hình danh mục cho AVAudioSession (không kích hoạt sớm để tránh nghẽn startup)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .defaultToSpeaker])
        return true
    }

    /// Tiếp nhận sự kiện hoàn tất tải nền từ iOS khi ứng dụng đang bị suspend hoặc kill
    public func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == "com.omnistream.mediahub.background" {
            DownloadManager.shared.backgroundCompletionHandler = completionHandler
        } else {
            completionHandler()
        }
    }
}
