import SwiftUI

// MARK: - Glass Card Container
public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let borderOpacity: Double
    private let padding: CGFloat

    public init(
        cornerRadius: CGFloat = 22,
        borderOpacity: Double = 0.35,
        padding: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .liquidGlass(cornerRadius: cornerRadius, borderOpacity: borderOpacity)
    }
}

// MARK: - Glass Button
// MARK: - Glass Press Button Style
public struct GlassPressButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public struct GlassButton: View {
    public enum Style {
        case frosted
        case vibrantGradient
        case destructive
    }

    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void

    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .frosted,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.shared.touchMedium()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(backgroundView)
            .overlay(overlayBorder)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(GlassPressButtonStyle())
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .frosted:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        case .vibrantGradient:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .destructive:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.85), Color.pink.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private var overlayBorder: some View {
        switch style {
        case .frosted:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        case .vibrantGradient, .destructive:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .frosted:
            return .primary
        case .vibrantGradient, .destructive:
            return .white
        }
    }

    private var shadowColor: Color {
        switch style {
        case .frosted:
            return Color.black.opacity(0.08)
        case .vibrantGradient:
            return Color.blue.opacity(0.35)
        case .destructive:
            return Color.red.opacity(0.3)
        }
    }
}

// MARK: - Glass Text Field with Clear & Paste
public struct GlassTextField: View {
    @Binding private var text: String
    private let placeholder: String
    private let icon: String
    private let onPasteAction: (() -> Void)?
    @FocusState private var isFocused: Bool

    public init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String = "link",
        onPasteAction: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.onPasteAction = onPasteAction
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .blue : .secondary)
                .font(.system(size: 16, weight: .medium))

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)

            if !text.isEmpty {
                Button(action: {
                    HapticFeedback.shared.touchLight()
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.7))
                        .font(.system(size: 16))
                }
            } else if let onPasteAction = onPasteAction {
                Button(action: {
                    HapticFeedback.shared.touchLight()
                    onPasteAction()
                }) {
                    Text("Dán")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isFocused
                        ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isFocused ? 1.5 : 1.0
                )
        }
        .shadow(color: isFocused ? Color.blue.opacity(0.2) : Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Glass Capsule Tag
public struct GlassCapsuleTag: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(title: String, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.shared.touchLight()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                }
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Glass Progress Bar with Gradient Glow
public struct GlassProgressBar: View {
    private let progress: Double // 0.0 -> 1.0

    public init(progress: Double) {
        self.progress = max(0.0, min(1.0, progress))
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(height: 8)

                // Fill Track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan, Color.teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    .shadow(color: Color.cyan.opacity(0.6), radius: 6, x: 0, y: 0)
                    .animation(.linear(duration: 0.2), value: progress)
            }
        }
        .frame(height: 8)
    }
}
