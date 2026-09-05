import SwiftUI

// MARK: - Liquid Glass Design System
/// Liquid Glass là phong cách thiết kế Glassmorphism hiện đại tối ưu cho iOS 16 - 18+.
/// Kết hợp Ultra-thin Material, viền phản quang vi mô (specular border gradient),
/// đổ bóng nhiều lớp (layered soft shadows) và độ tương phản cao trong cả Light và Dark mode.

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var borderOpacity: Double
    public var shadowRadius: CGFloat
    public var shadowY: CGFloat
    public var backgroundOpacity: Double

    @Environment(\.colorScheme) private var colorScheme

    public init(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.35,
        shadowRadius: CGFloat = 16,
        shadowY: CGFloat = 8,
        backgroundOpacity: Double = 0.65
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.backgroundOpacity = backgroundOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(backgroundOpacity)
            }
            .overlay {
                // Viền phản quang vi mô tạo cảm giác thuỷ tinh cong
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(borderOpacity), location: 0.0),
                                .init(color: .white.opacity(borderOpacity * 0.4), location: 0.3),
                                .init(color: .cyan.opacity(borderOpacity * 0.25), location: 0.7),
                                .init(color: .white.opacity(borderOpacity * 0.1), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            // Đổ bóng 2 tầng: tầng bóng nông để tạo độ nổi, tầng bóng sâu tạo độ mềm
            .shadow(
                color: (colorScheme == .dark ? Color.black.opacity(0.45) : Color.blue.opacity(0.08)),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

public struct GlassCapsuleModifier: ViewModifier {
    public var borderOpacity: Double
    @Environment(\.colorScheme) private var colorScheme

    public init(borderOpacity: Double = 0.3) {
        self.borderOpacity = borderOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(borderOpacity),
                                .white.opacity(borderOpacity * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

public extension View {
    /// Áp dụng hiệu ứng Liquid Glass với bo góc tuỳ chỉnh
    func liquidGlass(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.35,
        shadowRadius: CGFloat = 16,
        shadowY: CGFloat = 8,
        backgroundOpacity: Double = 0.75
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            shadowRadius: shadowRadius,
            shadowY: shadowY,
            backgroundOpacity: backgroundOpacity
        ))
    }

    /// Áp dụng kiểu dáng viên nang kính vi mô cho Chip, Tag hoặc Toolbar items
    func glassCapsule(borderOpacity: Double = 0.3) -> some View {
        modifier(GlassCapsuleModifier(borderOpacity: borderOpacity))
    }

    /// Thích ứng an toàn cho Dynamic Island (iPhone 14 Pro - 16 Pro Max) và Tai thỏ (iPhone X - 13)
    func adaptiveGlassPadding() -> some View {
        self.safeAreaInset(edge: .top) {
            Color.clear.frame(height: 4)
        }
    }
}
