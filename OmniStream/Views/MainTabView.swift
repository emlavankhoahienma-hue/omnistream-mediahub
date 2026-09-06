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
    @Namespace private var tabNamespace

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Nền Liquid Background duy nhất toàn ứng dụng (120 FPS Metal-Accelerated)
            LiquidBackground()

            // Nội dung từng Tab với hiệu ứng chuyển cảnh Fluid mượt mà
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                case .converter:
                    ConverterView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                case .library:
                    LibraryView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)

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

    // MARK: - Custom Glass Tab Bar (Sliding Liquid Glass Indicator)
    private var customGlassTabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    HapticFeedback.shared.touchSoft()
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                }) {
                    ZStack {
                        // Viên nang kính lỏng chuyển động trượt theo tab (Liquid Glass Pill)
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan.opacity(0.35),
                                            Color.blue.opacity(0.20)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .white.opacity(0.65), location: 0.0),
                                                    .init(color: .cyan.opacity(0.4), location: 0.5),
                                                    .init(color: .white.opacity(0.12), location: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.0
                                        )
                                        .allowsHitTesting(false)
                                }
                                .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 2)
                                .matchedGeometryEffect(id: "ACTIVE_TAB_PILL", in: tabNamespace)
                        }

                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : .secondary.opacity(0.8))
                                .scaleEffect(isSelected ? 1.08 : 1.0)

                            Text(tab.title)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : .secondary.opacity(0.8))
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .liquidGlass(cornerRadius: 28, borderOpacity: 0.38, shadowRadius: 14, shadowY: 6)
    }
}
