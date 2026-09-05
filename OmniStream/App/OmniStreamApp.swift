import SwiftUI

// MARK: - OmniStream & MediaHub Entry Point
@main
struct OmniStreamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark) // Tôn vinh vẻ đẹp khúc xạ của Liquid Glass
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        // Kích hoạt quét nhanh clipboard khi app được mở lại
                        NotificationCenter.default.post(
                            name: UIApplication.didBecomeActiveNotification,
                            object: nil
                        )
                    }
                }
        }
    }
}
