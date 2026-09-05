import Foundation

// MARK: - Media Tag
public struct MediaTag: Identifiable, Hashable, Codable {
    public let id: String
    public var name: String
    public var colorHex: String

    public init(id: String = UUID().uuidString, name: String, colorHex: String = "#007AFF") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    public static let defaults: [MediaTag] = [
        MediaTag(id: "all", name: "Tất cả", colorHex: "#007AFF"),
        MediaTag(id: "video", name: "Video", colorHex: "#5856D6"),
        MediaTag(id: "audio", name: "Âm thanh", colorHex: "#FF2D55"),
        MediaTag(id: "favorite", name: "Yêu thích", colorHex: "#FF9500"),
        MediaTag(id: "work", name: "Công việc", colorHex: "#34C759"),
        MediaTag(id: "converted", name: "Đã chuyển đổi", colorHex: "#AF52DE")
    ]
}
