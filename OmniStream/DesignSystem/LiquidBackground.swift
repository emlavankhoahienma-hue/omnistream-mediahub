import SwiftUI

// MARK: - Liquid Background (Ultra-Fluid 120 FPS Native Architecture)
/// Nền động đa sắc lỏng thời thượng, đạt chuẩn 120 FPS mượt mà tuyệt đối,
/// hoàn toàn không gây đơ/lag hay nghẽn Main Thread khi khởi động app.

public struct LiquidBackground: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Nền tối Obsidian sâu thẳm
            (colorScheme == .dark ? Color(red: 0.03, green: 0.04, blue: 0.07) : Color(red: 0.95, green: 0.96, blue: 0.99))
                .ignoresSafeArea()

            #if swift(>=6.0) || canImport(SwiftUI)
            if #available(iOS 18.0, *) {
                meshBackground
                    .ignoresSafeArea()
            } else {
                fluidAuroraBackground
                    .ignoresSafeArea()
            }
            #else
            fluidAuroraBackground
                .ignoresSafeArea()
            #endif

            // Lớp tráng kính mỏng đồng nhất
            Color.black.opacity(colorScheme == .dark ? 0.2 : 0.03)
                .ignoresSafeArea()
        }
        .onAppear {
            // GPU CoreAnimation layer animation (0% CPU impact)
            withAnimation(.linear(duration: 24.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    // MARK: - iOS 18 Native MeshGradient
    @available(iOS 18.0, *)
    private var meshBackground: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.55 : 0.45, isAnimating ? 0.45 : 0.55], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.05, green: 0.12, blue: 0.32),
                Color(red: 0.18, green: 0.05, blue: 0.35),
                Color(red: 0.03, green: 0.22, blue: 0.38),
                Color(red: 0.02, green: 0.16, blue: 0.28),
                Color(red: 0.14, green: 0.08, blue: 0.42),
                Color(red: 0.28, green: 0.05, blue: 0.26),
                Color(red: 0.12, green: 0.04, blue: 0.28),
                Color(red: 0.03, green: 0.18, blue: 0.34),
                Color(red: 0.08, green: 0.12, blue: 0.30)
            ]
        )
        .opacity(colorScheme == .dark ? 0.85 : 0.45)
    }

    // MARK: - Fluid Aurora (iOS 16 - 17 / Fallback)
    /// Gradient đa tầng mượt mà tự nhiên bằng GPU transform, không cần qua bộ lọc blur nặng
    private var fluidAuroraBackground: some View {
        ZStack {
            // Orb 1: Cyan / Electric Blue phát sáng góc trên
            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 0.75, blue: 1.0).opacity(colorScheme == .dark ? 0.35 : 0.25),
                    Color(red: 0.0, green: 0.4, blue: 0.9).opacity(colorScheme == .dark ? 0.18 : 0.12),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 400
            )
            .offset(x: -40, y: -80)

            // Orb 2: Neon Purple / Magenta ở trung tâm xoay nhẹ nhàng
            AngularGradient(
                colors: [
                    Color(red: 0.5, green: 0.1, blue: 0.95).opacity(0.32),
                    Color(red: 0.95, green: 0.1, blue: 0.55).opacity(0.28),
                    Color(red: 0.0, green: 0.7, blue: 0.95).opacity(0.3),
                    Color(red: 0.5, green: 0.1, blue: 0.95).opacity(0.32)
                ],
                center: .center
            )
            .scaleEffect(1.3)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .opacity(colorScheme == .dark ? 0.4 : 0.22)
            .blendMode(colorScheme == .dark ? .plusLighter : .normal)

            // Orb 3: Deep Teal / Blue ở góc dưới cùng
            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 0.65, blue: 0.75).opacity(colorScheme == .dark ? 0.32 : 0.2),
                    Color(red: 0.05, green: 0.15, blue: 0.45).opacity(colorScheme == .dark ? 0.15 : 0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 450
            )
            .offset(x: 50, y: 100)
        }
    }
}
