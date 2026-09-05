import SwiftUI

// MARK: - Liquid Background
/// Nền động đa sắc lỏng (Liquid Dynamic Ambient).
/// Tích hợp MeshGradient native trên iOS 18+ và Fallback đa tầng Radial/Angular Gradient
/// với hiệu ứng Blur sâu trên iOS 16-17, tạo nền tảng hoàn hảo cho hiệu ứng thấu kính Liquid Glass.

public struct LiquidBackground: View {
    @State private var animateGradients: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Lớp màu nền tối sâu cơ bản
            (colorScheme == .dark ? Color(red: 0.05, green: 0.07, blue: 0.12) : Color(red: 0.94, green: 0.96, blue: 0.99))
                .ignoresSafeArea()

            #if swift(>=6.0) || canImport(SwiftUI)
            if #available(iOS 18.0, *) {
                meshGradientView
                    .ignoresSafeArea()
                    .opacity(colorScheme == .dark ? 0.75 : 0.6)
                    .blur(radius: 40)
            } else {
                fallbackDynamicGradients
                    .ignoresSafeArea()
            }
            #else
            fallbackDynamicGradients
                .ignoresSafeArea()
            #endif

            // Lớp overlay mờ để cân bằng độ sáng
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.35 : 0.2)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateGradients.toggle()
            }
        }
    }

    // MARK: - iOS 18 Native MeshGradient
    @available(iOS 18.0, *)
    private var meshGradientView: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [animateGradients ? 0.6 : 0.4, animateGradients ? 0.4 : 0.6], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                colorScheme == .dark ? Color.indigo.opacity(0.8) : Color.blue.opacity(0.3),
                colorScheme == .dark ? Color.purple.opacity(0.7) : Color.cyan.opacity(0.3),
                colorScheme == .dark ? Color.blue.opacity(0.8) : Color.teal.opacity(0.3),
                colorScheme == .dark ? Color.cyan.opacity(0.6) : Color.indigo.opacity(0.2),
                colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue.opacity(0.35),
                colorScheme == .dark ? Color.pink.opacity(0.5) : Color.purple.opacity(0.25),
                colorScheme == .dark ? Color.purple.opacity(0.8) : Color.mint.opacity(0.2),
                colorScheme == .dark ? Color.teal.opacity(0.6) : Color.blue.opacity(0.2),
                colorScheme == .dark ? Color.indigo.opacity(0.9) : Color.cyan.opacity(0.3)
            ]
        )
    }

    // MARK: - Fallback Gradients for iOS 16 - 17
    private var fallbackDynamicGradients: some View {
        ZStack {
            // Orb 1: Cyan / Blue trên cùng góc trái
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (colorScheme == .dark ? Color.cyan.opacity(0.5) : Color.cyan.opacity(0.35)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .frame(width: 480, height: 480)
                .offset(
                    x: animateGradients ? -120 : -60,
                    y: animateGradients ? -240 : -160
                )
                .blur(radius: 60)

            // Orb 2: Indigo / Purple ở giữa góc phải
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (colorScheme == .dark ? Color.purple.opacity(0.55) : Color.indigo.opacity(0.3)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 320
                    )
                )
                .frame(width: 520, height: 520)
                .offset(
                    x: animateGradients ? 140 : 80,
                    y: animateGradients ? -60 : 40
                )
                .blur(radius: 70)

            // Orb 3: Teal / Deep Blue ở góc dưới cùng
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (colorScheme == .dark ? Color.teal.opacity(0.45) : Color.blue.opacity(0.25)),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 500, height: 500)
                .offset(
                    x: animateGradients ? -80 : 60,
                    y: animateGradients ? 320 : 260
                )
                .blur(radius: 65)
        }
    }
}
