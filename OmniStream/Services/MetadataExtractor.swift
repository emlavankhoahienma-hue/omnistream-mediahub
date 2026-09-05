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

    public var formattedSize: String {
        guard let size = fileSize, size > 0 else { return "Dung lượng động / Stream" }
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

    /// Lấy metadata preview nhanh từ URL thông qua HTTP HEAD
    public func extractPreview(for url: URL) async -> URLMetadataPreview {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 6.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        var fileSize: Int64?
        var mimeType: String?
        var filename = url.lastPathComponent

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                fileSize = httpResponse.expectedContentLength > 0 ? httpResponse.expectedContentLength : nil
                mimeType = httpResponse.mimeType

                if let disposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition"),
                   let extracted = extractFilenameFromDisposition(disposition) {
                    filename = extracted
                }
            }
        } catch {
            // Nếu HEAD thất bại (nhiều CDN chặn HEAD), ta dùng thông tin suy luận từ URL
        }

        if filename.isEmpty || filename == "/" {
            filename = url.host ?? "Media_Stream"
        }

        let ext = (filename as NSString).pathExtension.uppercased()
        let format = ext.isEmpty ? (mimeType?.components(separatedBy: "/").last?.uppercased() ?? "MEDIA") : ext
        let isDirect = ["MP4", "MOV", "M4V", "WEBM", "MP3", "M4A", "WAV", "AAC"].contains(format)

        return URLMetadataPreview(
            url: url,
            title: cleanFilename(filename),
            estimatedFormat: format,
            fileSize: fileSize,
            mimeType: mimeType,
            isDirectMedia: isDirect
        )
    }

    private func extractFilenameFromDisposition(_ disposition: String) -> String? {
        let pattern = "filename[*]?=(?:UTF-8'')?\"?([^;\"]+)\"?"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: disposition, options: [], range: NSRange(location: 0, length: disposition.utf16.count)) {
            if let range = Range(match.range(at: 1), in: disposition) {
                return String(disposition[range])
            }
        }
        return nil
    }

    private func cleanFilename(_ name: String) -> String {
        let decoded = name.removingPercentEncoding ?? name
        return decoded.replacingOccurrences(of: "+", with: " ")
    }
}
