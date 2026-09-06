import SwiftUI

// MARK: - Liquid Glass Design System (High-Performance Edition)
/// Hệ thống hiệu ứng kính lỏng (Liquid Glass) tối ưu hóa cho ProMotion 120Hz.
/// Sử dụng Ultra-Thin Material kết hợp ánh sáng khúc xạ vi mô và đường viền specular,
/// không gây hiện tượng quá tải bộ nhớ đồ họa hay đơ cảm ứng.

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var borderOpacity: Double
    public var shadowRadius: CGFloat
    public var shadowY: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(
        cornerRadius: CGFloat = 20,
        borderOpacity: Double = 0.3,
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 5
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                // Hiệu ứng ánh sáng khúc xạ bề mặt (Top-down Specular Reflection)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.08), location: 0.0),
                                .init(color: .clear, location: 0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
            .overlay {
                // Viền sáng phản quang vi mô (Micro Specular Rim)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(borderOpacity * 1.2), location: 0.0),
                                .init(color: .white.opacity(borderOpacity * 0.3), location: 0.25),
                                .init(color: .cyan.opacity(borderOpacity * 0.4), location: 0.6),
                                .init(color: .white.opacity(borderOpacity * 0.08), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.06),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

// MARK: - Optimized Row Glass for Smooth 120Hz Scroll Lists
public struct GlassRowModifier: ViewModifier {
    public var cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.25),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.04),
                radius: 6,
                x: 0,
                y: 3
            )
    }
}

// MARK: - Glass Capsule Modifier
public struct GlassCapsuleModifier: ViewModifier {
    public var borderOpacity: Double

    @Environment(\.colorScheme) private var colorScheme

    public init(borderOpacity: Double = 0.25) {
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
                                .white.opacity(borderOpacity * 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.03),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

public extension View {
    /// Áp dụng hiệu ứng Liquid Glass cao cấp cho Thẻ chính
    func liquidGlass(
        cornerRadius: CGFloat = 20,
        borderOpacity: Double = 0.3,
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 5
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            shadowRadius: shadowRadius,
            shadowY: shadowY
        ))
    }

    /// Áp dụng hiệu ứng Kính siêu mượt cho danh sách cuộn (120 FPS không giật lag)
    func glassRow(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassRowModifier(cornerRadius: cornerRadius))
    }

    /// Áp dụng kiểu dáng viên nang kính cho Chip, Tag hoặc Toolbar items
    func glassCapsule(borderOpacity: Double = 0.25) -> some View {
        modifier(GlassCapsuleModifier(borderOpacity: borderOpacity))
    }
}
