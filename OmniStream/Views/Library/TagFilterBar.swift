import SwiftUI

// MARK: - Tag Filter Bar
public struct TagFilterBar: View {
    public let tags: [MediaTag]
    @Binding public var selectedTagId: String

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    GlassCapsuleTag(
                        title: tag.name,
                        isSelected: selectedTagId == tag.id
                    ) {
                        selectedTagId = tag.id
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}
