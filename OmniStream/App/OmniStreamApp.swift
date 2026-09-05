import SwiftUI

// MARK: - OmniStream & MediaHub Entry Point
@main
struct OmniStreamApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark) // Tôn vinh vẻ đẹp khúc xạ của Liquid Glass
        }
    }
}
