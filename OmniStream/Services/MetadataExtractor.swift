import Foundation
import UIKit

// MARK: - URL Metadata Preview
public struct URLMetadataPreview {
    public let url: URL
    public let title: String
    public let estimatedFormat: String
    public let fileSize: Int64?
    public let mimeType: String?
    public let isDirectMedia: Bool
    public let isHLS: Bool
    public let requiresBrowserSniffer: Bool
    public let snifferReason: String?

    public init(
        url: URL,
        title: String,
        estimatedFormat: String,
        fileSize: Int64? = nil,
        mimeType: String? = nil,
        isDirectMedia: Bool = false,
        isHLS: Bool = false,
        requiresBrowserSniffer: Bool = false,
        snifferReason: String? = nil
    ) {
        self.url = url
        self.title = title
        self.estimatedFormat = estimatedFormat
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.isDirectMedia = isDirectMedia
        self.isHLS = isHLS
        self.requiresBrowserSniffer = requiresBrowserSniffer
        self.snifferReason = snifferReason
    }

    public var formattedSize: String {
        guard let size = fileSize, size > 0 else {
            if isHLS { return "Luồng phân mảnh HLS (.m3u8)" }
            if requiresBrowserSniffer { return "Trình duyệt bắt link" }
            return "Dung lượng động / Stream"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Metadata Extractor Service
public final class MetadataExtractor {
    public static let shared = MetadataExtractor()
    private init() {}

    /// Kiểm tra xem chuỗi có phải là URL hợp lệ không
    public func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }
        return url.host != nil
    }

    /// Lấy metadata preview thông minh từ MediaStreamResolver
    public func extractPreview(for url: URL) async -> URLMetadataPreview {
        let resolution = await MediaStreamResolver.shared.resolve(url: url)

        switch resolution {
        case .direct(let streamURL, let title, let format, let size):
            return URLMetadataPreview(
                url: streamURL,
                title: cleanFilename(title),
                estimatedFormat: format,
                fileSize: size,
                mimeType: "video/\(format.lowercased())",
                isDirectMedia: true,
                isHLS: false,
                requiresBrowserSniffer: false,
                snifferReason: nil
            )

        case .hls(let streamURL, let title):
            return URLMetadataPreview(
                url: streamURL,
                title: cleanFilename(title),
                estimatedFormat: "HLS STREAM",
                fileSize: nil,
                mimeType: "application/x-mpegURL",
                isDirectMedia: false,
                isHLS: true,
                requiresBrowserSniffer: false,
                snifferReason: nil
            )

        case .webStreamSnifferRequired(let webURL, let title, let reason):
            return URLMetadataPreview(
                url: webURL,
                title: cleanFilename(title),
                estimatedFormat: "WEB STREAM",
                fileSize: nil,
                mimeType: "text/html",
                isDirectMedia: false,
                isHLS: false,
                requiresBrowserSniffer: true,
                snifferReason: reason
            )
        }
    }

    private func cleanFilename(_ name: String) -> String {
        let decoded = name.removingPercentEncoding ?? name
        return decoded.replacingOccurrences(of: "+", with: " ")
    }
}
