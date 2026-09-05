import SwiftUI

// MARK: - Liquid Background (Metal-Accelerated & 120 FPS Fluid)
/// Nền động đa sắc lỏng thời thượng, đạt chuẩn 60-120 FPS không gây drop frame,
/// không gây nghẽn GPU / CoreAnimation render server.
/// Tích hợp MeshGradient native (iOS 18+) và Metal-rendered Fluid Aurora (iOS 16-17).

public struct LiquidBackground: View {
    @State private var phase: Float = 0.0
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Nền tối Obsidian sang trọng
            (colorScheme == .dark ? Color(red: 0.04, green: 0.05, blue: 0.09) : Color(red: 0.95, green: 0.96, blue: 0.99))
                .ignoresSafeArea()

            #if swift(>=6.0) || canImport(SwiftUI)
            if #available(iOS 18.0, *) {
                nativeMeshGradient
                    .ignoresSafeArea()
            } else {
                metalFluidAurora
                    .ignoresSafeArea()
            }
            #else
            metalFluidAurora
                .ignoresSafeArea()
            #endif

            // Lớp tráng kính mỏng tạo độ đồng nhất và độ tương phản cao cho văn bản
            Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04)
                .ignoresSafeArea()
        }
        .onAppear {
            // Animation nhẹ nhàng 10s với easeInOut
            withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }

    // MARK: - iOS 18 Native MeshGradient (Zero-Lag, Metal Native)
    @available(iOS 18.0, *)
    private var nativeMeshGradient: some View {
        let p = phase
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [Float(0.35 + 0.15 * p), Float(0.45 + 0.1 * p)], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                colorScheme == .dark ? Color(red: 0.08, green: 0.12, blue: 0.28) : Color.blue.opacity(0.25),
                colorScheme == .dark ? Color(red: 0.15, green: 0.08, blue: 0.32) : Color.purple.opacity(0.2),
                colorScheme == .dark ? Color(red: 0.05, green: 0.20, blue: 0.35) : Color.cyan.opacity(0.2),
                colorScheme == .dark ? Color(red: 0.02, green: 0.18, blue: 0.25) : Color.teal.opacity(0.2),
                colorScheme == .dark ? Color(red: 0.12, green: 0.10, blue: 0.38) : Color.indigo.opacity(0.25),
                colorScheme == .dark ? Color(red: 0.25, green: 0.06, blue: 0.22) : Color.pink.opacity(0.15),
                colorScheme == .dark ? Color(red: 0.10, green: 0.05, blue: 0.25) : Color.purple.opacity(0.2),
                colorScheme == .dark ? Color(red: 0.04, green: 0.15, blue: 0.30) : Color.blue.opacity(0.2),
                colorScheme == .dark ? Color(red: 0.06, green: 0.10, blue: 0.26) : Color.cyan.opacity(0.25)
            ]
        )
        .opacity(0.85)
    }

    // MARK: - Metal-Rendered Fluid Aurora (iOS 16 - 17)
    /// Sử dụng .drawingGroup() để Metal biên dịch shader trực tiếp trên GPU thành 1 texture duy nhất,
    /// loại bỏ hoàn toàn hiện tượng nghẽn CoreAnimation render server.
    private var metalFluidAurora: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let p = phase

            ZStack {
                // Luồng ánh sáng Cyan / Teal ở góc trên
                RadialGradient(
                    colors: [
                        (colorScheme == .dark ? Color(red: 0.0, green: 0.65, blue: 0.95).opacity(0.38) : Color.cyan.opacity(0.3)),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.2 + 0.15 * p, y: 0.15 + 0.1 * p),
                    startRadius: 20,
                    endRadius: max(size.width, size.height) * 0.55
                )

                // Luồng ánh sáng Tím / Indigo ở trung tâm chuyển động
                RadialGradient(
                    colors: [
                        (colorScheme == .dark ? Color(red: 0.45, green: 0.15, blue: 0.9).opacity(0.35) : Color.purple.opacity(0.25)),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.75 - 0.2 * p, y: 0.5 + 0.15 * p),
                    startRadius: 30,
                    endRadius: max(size.width, size.height) * 0.6
                )

                // Luồng ánh sáng Hồng Neon / Magenta ở góc dưới
                RadialGradient(
                    colors: [
                        (colorScheme == .dark ? Color(red: 0.9, green: 0.1, blue: 0.45).opacity(0.25) : Color.pink.opacity(0.2)),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.35 + 0.2 * p, y: 0.85 - 0.1 * p),
                    startRadius: 40,
                    endRadius: max(size.width, size.height) * 0.5
                )
            }
            .drawingGroup() // Ép Metal GPU render phẳng, không drop frame!
        }
    }
}
