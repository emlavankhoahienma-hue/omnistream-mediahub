import SwiftUI

// MARK: - Tag Filter Bar (Sliding Liquid Glass Indicator)
public struct TagFilterBar: View {
    public let tags: [MediaTag]
    @Binding public var selectedTagId: String
    @Namespace private var tagNamespace

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    let isSelected = selectedTagId == tag.id
                    Button(action: {
                        HapticFeedback.shared.touchLight()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTagId = tag.id
                        }
                    }) {
                        ZStack {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.6), .white.opacity(0.15)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                            .allowsHitTesting(false)
                                    }
                                    .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 3)
                                    .matchedGeometryEffect(id: "ACTIVE_TAG_PILL", in: tagNamespace)
                            } else {
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                            .allowsHitTesting(false)
                                    }
                            }

                            Text(tag.name)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}
