import Foundation

// MARK: - Resolved Stream Result
public enum ResolvedStreamType: Equatable {
    case direct(streamURL: URL, title: String, format: String, fileSize: Int64?)
    case hls(streamURL: URL, title: String)
    case webStreamSnifferRequired(webURL: URL, title: String, reason: String)
}

// MARK: - Media Stream Resolver Service
/// Phân tích liên kết đầu vào, phát hiện luồng phát trực tiếp (Direct MP4/MOV/MP3),
/// luồng phân mảnh HLS (.m3u8), trích xuất OpenGraph/HTML5 video từ trang web,
/// và nhận diện các nền tảng mạng xã hội (YouTube, TikTok, Facebook...) cần mở qua Trình Duyệt Bắt Link.
public final class MediaStreamResolver {
    public static let shared = MediaStreamResolver()
    private init() {}

    private let directExtensions: Set<String> = [
        "mp4", "mov", "m4v", "mkv", "webm", "ts",
        "mp3", "m4a", "wav", "aac", "flac", "caf"
    ]

    /// Phân tích URL toàn diện
    public func resolve(url: URL) async -> ResolvedStreamType {
        let urlString = url.absoluteString
        let ext = url.pathExtension.lowercased()

        // 1. Kiểm tra luồng HLS .m3u8 trực tiếp
        if ext == "m3u8" || urlString.contains(".m3u8") {
            let title = extractCleanTitle(from: url)
            return .hls(streamURL: url, title: title)
        }

        // 2. Kiểm tra phần mở rộng tệp media trực tiếp
        if directExtensions.contains(ext) {
            let title = extractCleanTitle(from: url)
            return .direct(streamURL: url, title: title, format: ext.uppercased(), fileSize: nil)
        }

        // 3. Kiểm tra các nền tảng video lớn thường khóa luồng bằng JavaScript/DRM
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") || host.contains("youtu.be") {
            let title = await fetchWebPageTitle(url: url) ?? "YouTube Video"
            return .webStreamSnifferRequired(
                webURL: url,
                title: title,
                reason: "YouTube mã hoá luồng video theo phiên. Hãy mở qua Trình Duyệt Bắt Link để tự động bắt luồng MP4/1080p."
            )
        }

        if host.contains("tiktok.com") {
            let title = await fetchWebPageTitle(url: url) ?? "TikTok Video"
            return .webStreamSnifferRequired(
                webURL: url,
                title: title,
                reason: "TikTok yêu cầu chứng chỉ trình duyệt. Mở qua Trình Duyệt Bắt Link để bắt video không logo."
            )
        }

        if host.contains("facebook.com") || host.contains("fb.watch") || host.contains("instagram.com") {
            let title = await fetchWebPageTitle(url: url) ?? "Social Video"
            return .webStreamSnifferRequired(
                webURL: url,
                title: title,
                reason: "Nền tảng Meta yêu cầu phiên duyệt web để cung cấp luồng video độ phân giải cao."
            )
        }

        // 4. Nếu là trang web bất kỳ: Tải HTML và cào thẻ OpenGraph / Video tags
        return await extractMediaFromWebPage(url: url)
    }

    // MARK: - HTML Page Scraping
    private func extractMediaFromWebPage(url: URL) async -> ResolvedStreamType {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return .webStreamSnifferRequired(webURL: url, title: url.host ?? "Media Web", reason: "Máy chủ trả về mã lỗi HTTP. Hãy mở trực tiếp trong Trình Duyệt.")
            }

            // Kiểm tra Content-Type: Nếu phản hồi là nhị phân video/audio trực tiếp
            if let mime = httpResponse.mimeType?.lowercased() {
                if mime.hasPrefix("video/") || mime.hasPrefix("audio/") || mime.contains("mpegurl") {
                    let ext = mime.components(separatedBy: "/").last?.uppercased() ?? "MEDIA"
                    return .direct(streamURL: url, title: extractCleanTitle(from: url), format: ext, fileSize: httpResponse.expectedContentLength > 0 ? httpResponse.expectedContentLength : nil)
                }
            }

            guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
                return .webStreamSnifferRequired(webURL: url, title: url.host ?? "Media Web", reason: "Không thể đọc nội dung trang web. Dùng Trình Duyệt Bắt Link.")
            }

            let pageTitle = extractRegexMatch(pattern: "<title[^>]*>([^<]+)</title>", text: html)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? (url.host ?? "Media Stream")

            // A. Tìm OpenGraph Video (<meta property="og:video" content="..."> hoặc secure_url)
            let ogVideoPatterns = [
                "<meta[^>]+property=[\"']og:video:secure_url[\"'][^>]+content=[\"']([^\"']+)[\"']",
                "<meta[^>]+property=[\"']og:video[\"'][^>]+content=[\"']([^\"']+)[\"']",
                "<meta[^>]+property=[\"']og:video:url[\"'][^>]+content=[\"']([^\"']+)[\"']",
                "<meta[^>]+name=[\"']twitter:player:stream[\"'][^>]+content=[\"']([^\"']+)[\"']"
            ]

            for pattern in ogVideoPatterns {
                if let found = extractRegexMatch(pattern: pattern, text: html), let foundURL = URL(string: decodeHTMLEntities(found)) {
                    if foundURL.pathExtension.lowercased() == "m3u8" || foundURL.absoluteString.contains(".m3u8") {
                        return .hls(streamURL: foundURL, title: pageTitle)
                    }
                    return .direct(streamURL: foundURL, title: pageTitle, format: "MP4", fileSize: nil)
                }
            }

            // B. Tìm thẻ HTML5 <video src="..."> hoặc <source src="...">
            let videoTagPatterns = [
                "<video[^>]+src=[\"']([^\"']+)[\"']",
                "<source[^>]+src=[\"']([^\"']+)[\"'][^>]+type=[\"']video/[^\"']+[\"']",
                "<source[^>]+src=[\"']([^\"']+)[\"']"
            ]

            for pattern in videoTagPatterns {
                if let found = extractRegexMatch(pattern: pattern, text: html) {
                    let decoded = decodeHTMLEntities(found)
                    let resolvedMediaURL = URL(string: decoded, relativeTo: url) ?? URL(string: decoded)
                    if let streamURL = resolvedMediaURL {
                        if streamURL.pathExtension.lowercased() == "m3u8" || streamURL.absoluteString.contains(".m3u8") {
                            return .hls(streamURL: streamURL, title: pageTitle)
                        }
                        return .direct(streamURL: streamURL, title: pageTitle, format: "MP4", fileSize: nil)
                    }
                }
            }

            // C. Không tìm thấy thẻ tĩnh (trang sử dụng JavaScript Player) -> Mở qua Browser Sniffer
            return .webStreamSnifferRequired(
                webURL: url,
                title: pageTitle,
                reason: "Trang web sử dụng trình phát động JavaScript. Mở Trình Duyệt Bắt Link để bắt luồng video chuẩn khi phát."
            )

        } catch {
            return .webStreamSnifferRequired(
                webURL: url,
                title: url.host ?? "Media Web",
                reason: "Không thể kết nối trực tiếp. Sử dụng Trình Duyệt Bắt Link để truy cập."
            )
        }
    }

    // MARK: - Helpers
    private func fetchWebPageTitle(url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 4.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return nil
        }
        return extractRegexMatch(pattern: "<title[^>]*>([^<]+)</title>", text: html)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractRegexMatch(pattern: String, text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 else { return nil }
        guard let matchRange = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[matchRange])
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private func extractCleanTitle(from url: URL) -> String {
        let last = url.deletingPathExtension().lastPathComponent
        if !last.isEmpty && last != "/" {
            return last.removingPercentEncoding ?? last
        }
        return url.host ?? "Media_Stream"
    }
}
