import SwiftUI
import WebKit

// MARK: - Sniffed Media Model
public struct SniffedMediaItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public let title: String
    public let format: String
    public let detectedAt: Date

    public static func == (lhs: SniffedMediaItem, rhs: SniffedMediaItem) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Web Media Browser View Model
@MainActor
public final class WebMediaBrowserViewModel: NSObject, ObservableObject {
    @Published public var currentURLString: String = "https://m.youtube.com"
    @Published public var pageTitle: String = ""
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var estimatedProgress: Double = 0.0
    @Published public var detectedMedias: [SniffedMediaItem] = []
    @Published public var latestDetectedMedia: SniffedMediaItem? = nil
    @Published public var showDownloadSuccessToast: Bool = false

    public weak var webView: WKWebView?

    public func load(urlString: String) {
        var target = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if target.isEmpty { return }

        if !target.lowercased().hasPrefix("http://") && !target.lowercased().hasPrefix("https://") {
            if target.contains(".") && !target.contains(" ") {
                target = "https://" + target
            } else {
                let query = target.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? target
                target = "https://www.google.com/search?q=\(query)"
            }
        }

        if let url = URL(string: target) {
            self.currentURLString = target
            webView?.load(URLRequest(url: url))
        }
    }

    public func goBack() {
        webView?.goBack()
    }

    public func goForward() {
        webView?.goForward()
    }

    public func reload() {
        webView?.reload()
    }

    public func registerDetectedMedia(urlString: String, pageTitle: String?) {
        guard let url = URL(string: urlString) else { return }

        // Bỏ qua các URL blob hoặc ảnh nhỏ
        let lower = urlString.lowercased()
        if lower.hasPrefix("blob:") || lower.hasPrefix("data:") { return }
        if lower.contains(".jpg") || lower.contains(".png") || lower.contains(".gif") || lower.contains(".svg") { return }

        // Xác định định dạng
        let format: String
        if lower.contains(".m3u8") {
            format = "HLS Stream"
        } else if lower.contains(".mp4") || lower.contains("videoplayback") {
            format = "MP4 Video"
        } else if lower.contains(".mp3") {
            format = "MP3 Audio"
        } else if lower.contains(".m4a") {
            format = "M4A Audio"
        } else {
            format = "Video Stream"
        }

        let rawTitle = (pageTitle?.isEmpty == false ? pageTitle : self.pageTitle) ?? "Media_Video"
        let cleanTitle = rawTitle.replacingOccurrences(of: " - YouTube", with: "")

        let newItem = SniffedMediaItem(
            url: url,
            title: cleanTitle,
            format: format,
            detectedAt: Date()
        )

        // Tránh trùng lặp liên tục cùng URL
        if !detectedMedias.contains(where: { $0.url == url }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                detectedMedias.insert(newItem, at: 0)
                latestDetectedMedia = newItem
            }
            HapticFeedback.shared.touchMedium()
        }
    }

    public func downloadMedia(_ item: SniffedMediaItem) {
        DownloadManager.shared.startDownload(from: item.url, title: item.title)
        HapticFeedback.shared.notifySuccess()

        withAnimation {
            self.showDownloadSuccessToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.showDownloadSuccessToast = false
            }
        }
    }
}

// MARK: - Web Media Browser View
public struct WebMediaBrowserView: View {
    public let initialURL: URL?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WebMediaBrowserViewModel()
    @State private var addressInput: String = ""

    public init(initialURL: URL? = nil) {
        self.initialURL = initialURL
    }

    public var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 0) {
                // Top Glass Navigation Bar
                browserNavigationBar
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                // Thanh tiến trình tải trang
                if viewModel.isLoading {
                    ProgressView(value: viewModel.estimatedProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .frame(height: 2.5)
                }

                // Web View Container
                ZStack(alignment: .bottom) {
                    WebViewRepresentable(viewModel: viewModel, initialURL: initialURL)
                        .edgesIgnoringSafeArea(.bottom)

                    // Floating Glass Card thông báo bắt được video
                    if let media = viewModel.latestDetectedMedia {
                        floatingMediaSnifferCard(media: media)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                    }

                    // Toast báo thành công khi bắt đầu tải
                    if viewModel.showDownloadSuccessToast {
                        Text("🚀 Đã thêm vào hàng đợi tải nền tốc độ cao!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.85))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            .padding(.bottom, 100)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            if let initial = initialURL {
                viewModel.currentURLString = initial.absoluteString
                addressInput = initial.absoluteString
            } else {
                addressInput = viewModel.currentURLString
            }
        }
        .onChange(of: viewModel.currentURLString) { newURL in
            addressInput = newURL
        }
    }

    // MARK: - Browser Navigation Bar
    private var browserNavigationBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                // Nút Đóng
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // Nút Back
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.canGoBack ? .primary : .secondary.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(!viewModel.canGoBack)
                .buttonStyle(PlainButtonStyle())

                // Nút Forward
                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.canGoForward ? .primary : .secondary.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(!viewModel.canGoForward)
                .buttonStyle(PlainButtonStyle())

                // Thanh địa chỉ Glass Capsule
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)

                    TextField("Nhập URL hoặc tìm kiếm...", text: $addressInput, onCommit: {
                        viewModel.load(urlString: addressInput)
                    })
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)

                    if !addressInput.isEmpty {
                        Button(action: { addressInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))

                // Nút Tải lại
                Button(action: { viewModel.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Quick Access Chips Bar
            quickShortcutsBar
        }
    }

    // MARK: - Quick Shortcuts Bar
    private var quickShortcutsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quickChip(title: "YouTube", icon: "play.rectangle.fill", color: .red, url: "https://m.youtube.com")
                quickChip(title: "TikTok", icon: "music.note", color: .cyan, url: "https://www.tiktok.com")
                quickChip(title: "Facebook", icon: "f.circle.fill", color: .blue, url: "https://m.facebook.com")
                quickChip(title: "Instagram", icon: "camera.fill", color: .purple, url: "https://www.instagram.com")
                quickChip(title: "Google", icon: "magnifyingglass", color: .orange, url: "https://www.google.com")
            }
            .padding(.horizontal, 4)
        }
    }

    private func quickChip(title: String, icon: String, color: Color, url: String) -> some View {
        Button(action: {
            viewModel.load(urlString: url)
            HapticFeedback.shared.touchLight()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Floating Media Sniffer Card
    private func floatingMediaSnifferCard(media: SniffedMediaItem) -> some View {
        GlassCard(cornerRadius: 20, borderOpacity: 0.45) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 42, height: 42)

                        Image(systemName: "waveform.and.mic")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("BẮT ĐƯỢC LUỒNG VIDEO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.cyan)

                            Text(media.format)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }

                        Text(media.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation {
                            viewModel.latestDetectedMedia = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Nút Tải Video Ngay
                GlassButton("TẢI VIDEO NGAY (.mp4)", icon: "arrow.down.circle.fill", style: .vibrantGradient) {
                    viewModel.downloadMedia(media)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - WebView Representable
public struct WebViewRepresentable: UIViewRepresentable {
    @ObservedObject public var viewModel: WebMediaBrowserViewModel
    public let initialURL: URL?

    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()

        // Tiêm Media Sniffer JavaScript
        let snifferScript = """
        (function() {
            function postMedia(url, type) {
                if (!url || typeof url !== 'string' || url.length < 10) return;
                if (url.startsWith('blob:') || url.startsWith('data:')) return;
                window.webkit.messageHandlers.omniMediaSniffer.postMessage({
                    url: url,
                    title: document.title || 'Media Video',
                    type: type || 'video'
                });
            }

            function inspectVideos() {
                var videos = document.getElementsByTagName('video');
                for (var i = 0; i < videos.length; i++) {
                    var v = videos[i];
                    if (v.currentSrc) postMedia(v.currentSrc, 'video');
                    else if (v.src) postMedia(v.src, 'video');
                    var sources = v.getElementsByTagName('source');
                    for (var j = 0; j < sources.length; j++) {
                        if (sources[j].src) postMedia(sources[j].src, 'video');
                    }
                }
            }

            // Lắng nghe sự kiện play của thẻ Video
            document.addEventListener('play', function(e) {
                if (e.target && e.target.tagName === 'VIDEO') {
                    postMedia(e.target.currentSrc || e.target.src, 'video');
                }
            }, true);

            // Chặn bắt qua window.fetch
            var origFetch = window.fetch;
            window.fetch = function() {
                var url = arguments[0];
                if (typeof url === 'string') {
                    if (url.includes('.m3u8') || url.includes('.mp4') || url.includes('videoplayback') || url.includes('.webm') || url.includes('.m4a')) {
                        postMedia(url, 'stream');
                    }
                } else if (url && url.url) {
                    if (url.url.includes('.m3u8') || url.url.includes('.mp4') || url.url.includes('videoplayback')) {
                        postMedia(url.url, 'stream');
                    }
                }
                return origFetch.apply(this, arguments);
            };

            // Chặn bắt qua XMLHttpRequest
            var origOpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                if (typeof url === 'string') {
                    if (url.includes('.m3u8') || url.includes('.mp4') || url.includes('videoplayback') || url.includes('.webm') || url.includes('.m4a')) {
                        postMedia(url, 'stream');
                    }
                }
                return origOpen.apply(this, arguments);
            };

            setInterval(inspectVideos, 1500);
        })();
        """

        let userScript = WKUserScript(source: snifferScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        userContentController.add(context.coordinator, name: "omniMediaSniffer")

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        webView.allowsBackForwardNavigationGestures = true

        context.coordinator.setupObservation(for: webView)
        viewModel.webView = webView

        let urlToLoad = initialURL ?? URL(string: viewModel.currentURLString) ?? URL(string: "https://m.youtube.com")!
        webView.load(URLRequest(url: urlToLoad))

        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var viewModel: WebMediaBrowserViewModel
        private var progressObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var canBackObservation: NSKeyValueObservation?
        private var canForwardObservation: NSKeyValueObservation?

        init(viewModel: WebMediaBrowserViewModel) {
            self.viewModel = viewModel
        }

        func setupObservation(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.estimatedProgress = wv.estimatedProgress
                }
            }
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    if let newURL = wv.url?.absoluteString {
                        self?.viewModel.currentURLString = newURL
                    }
                }
            }
            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.pageTitle = wv.title ?? ""
                }
            }
            canBackObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.canGoBack = wv.canGoBack
                }
            }
            canForwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.canGoForward = wv.canGoForward
                }
            }
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = true
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                self.viewModel.pageTitle = webView.title ?? ""
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
            }
        }

        // Bắt message từ JavaScript
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "omniMediaSniffer", let dict = message.body as? [String: Any] {
                let url = dict["url"] as? String ?? ""
                let title = dict["title"] as? String ?? ""
                if !url.isEmpty {
                    DispatchQueue.main.async {
                        self.viewModel.registerDetectedMedia(urlString: url, pageTitle: title)
                    }
                }
            }
        }
    }
}
