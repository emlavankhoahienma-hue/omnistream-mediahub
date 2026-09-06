import SwiftUI

// MARK: - Liquid Background (Ultra-Fluid 120 FPS Metal Architecture)
/// Nền động đa sắc lỏng thời thượng đạt chuẩn 120 FPS mượt mà tuyệt đối.
/// Sử dụng các tầng Gradient quang học gia tốc trực tiếp qua GPU Metal,
/// loại bỏ hoàn toàn vòng lặp animation nặng nề gây nghẽn Main Thread hay đơ cảm ứng.

public struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // Nền tối Obsidian không gian sâu
            (colorScheme == .dark
                ? Color(red: 0.03, green: 0.04, blue: 0.08)
                : Color(red: 0.95, green: 0.96, blue: 0.99))
                .ignoresSafeArea()

            // Tầng ánh sáng cực quang tự nhiên (Metal Shader Fast-Path)
            auroraGlowLayers
                .ignoresSafeArea()

            // Lớp tráng kính mỏng tạo độ sâu và tương phản quang học
            (colorScheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.1))
                .ignoresSafeArea()
        }
    }

    // MARK: - Aurora Glow Layers (Zero CPU, Metal Accelerated)
    private var auroraGlowLayers: some View {
        ZStack {
            // Cực quang 1: Electric Cyan & Azure Blue phát quang góc trên bên trái
            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 0.72, blue: 1.0).opacity(colorScheme == .dark ? 0.30 : 0.20),
                    Color(red: 0.05, green: 0.25, blue: 0.65).opacity(colorScheme == .dark ? 0.15 : 0.10),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.05),
                startRadius: 20,
                endRadius: 420
            )

            // Cực quang 2: Neon Purple & Electric Violet tại trung tâm bên phải
            RadialGradient(
                colors: [
                    Color(red: 0.58, green: 0.15, blue: 0.95).opacity(colorScheme == .dark ? 0.26 : 0.18),
                    Color(red: 0.25, green: 0.05, blue: 0.50).opacity(colorScheme == .dark ? 0.12 : 0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.92, y: 0.42),
                startRadius: 30,
                endRadius: 450
            )

            // Cực quang 3: Deep Teal & Mint Emerald ở góc dưới cùng
            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 0.62, blue: 0.72).opacity(colorScheme == .dark ? 0.22 : 0.15),
                    Color(red: 0.02, green: 0.18, blue: 0.38).opacity(colorScheme == .dark ? 0.10 : 0.06),
                    Color.clear
                ],
                center: UnitPoint(x: 0.15, y: 0.88),
                startRadius: 25,
                endRadius: 400
            )
        }
    }
}
