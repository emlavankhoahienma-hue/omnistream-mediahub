import SwiftUI

// MARK: - App Tab Enum
public enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard = 0
    case converter = 1
    case library = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .dashboard: return "Tải Xuống"
        case .converter: return "Chuyển Đổi"
        case .library: return "Thư Viện"
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: return "arrow.down.circle.fill"
        case .converter: return "arrow.triangle.2.circlepath.circle.fill"
        case .library: return "folder.fill"
        }
    }
}

// MARK: - Main Tab View
public struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @ObservedObject private var playerViewModel = PlayerViewModel.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Nền Liquid Background duy nhất toàn ứng dụng (120 FPS Metal-Accelerated)
            LiquidBackground()

            // Nội dung từng Tab
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .converter:
                    ConverterView()
                case .library:
                    LibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Điều khiển nổi: Mini Player & Glass Tab Bar
            VStack(spacing: 8) {
                // Mini Player
                MiniPlayerView(viewModel: playerViewModel)

                // Custom Liquid Glass Tab Bar
                customGlassTabBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $playerViewModel.isFullScreenPresented) {
            FullPlayerModal(viewModel: playerViewModel)
        }
    }

    // MARK: - Custom Glass Tab Bar
    private var customGlassTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button(action: {
                    HapticFeedback.shared.touchSoft()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .cyan : .secondary.opacity(0.8))

                        Text(tab.title)
                            .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .liquidGlass(cornerRadius: 26, borderOpacity: 0.35, shadowRadius: 12, shadowY: 5)
    }
}
