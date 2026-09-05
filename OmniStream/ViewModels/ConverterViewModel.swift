import SwiftUI
import Combine

// MARK: - Converter Mode
public enum ConverterMode: String, CaseIterable, Identifiable {
    case audio = "Tách Âm Thanh"
    case video = "Nén Video"

    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .audio: return "waveform.badge.magnifyingglass"
        case .video: return "arrow.down.right.and.arrow.up.left"
        }
    }
}

// MARK: - Converter View Model
@MainActor
public final class ConverterViewModel: ObservableObject {
    @Published public var selectedMode: ConverterMode = .audio
    @Published public var selectedMediaItem: MediaItem? = nil

    // Cấu hình âm thanh
    @Published public var selectedAudioFormat: AudioFormat = .m4a
    @Published public var selectedAudioBitrate: AudioBitrate = .kbps320

    // Cấu hình video
    @Published public var selectedVideoCodec: VideoCodec = .hevc
    @Published public var selectedVideoQuality: VideoQualityTarget = .original1080p

    // Trạng thái xử lý
    @Published public var isTranscoding: Bool = false
    @Published public var conversionProgress: Double = 0.0
    @Published public var convertedOutputURL: URL? = nil
    @Published public var errorMessage: String? = nil
    @Published public var showSuccessSheet: Bool = false
    @Published public var showErrorAlert: Bool = false

    private let converterService = MediaConverterService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        converterService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .processing(let progress):
                    self.isTranscoding = true
                    self.conversionProgress = progress
                case .completed(let outputURL):
                    self.isTranscoding = false
                    self.conversionProgress = 1.0
                    self.convertedOutputURL = outputURL
                    self.showSuccessSheet = true
                case .failed(let err):
                    self.isTranscoding = false
                    self.errorMessage = err
                    self.showErrorAlert = true
                case .idle:
                    self.isTranscoding = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Start Conversion Action
    public func startConversion() {
        guard let item = selectedMediaItem else {
            self.errorMessage = "Vui lòng chọn một tệp media từ thư viện để chuyển đổi."
            self.showErrorAlert = true
            HapticFeedback.shared.notifyWarning()
            return
        }

        let sourceURL = item.fileURL
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            self.errorMessage = "Không tìm thấy tệp gốc trên thiết bị."
            self.showErrorAlert = true
            HapticFeedback.shared.notifyError()
            return
        }

        HapticFeedback.shared.touchMedium()

        Task {
            do {
                if self.selectedMode == .audio {
                    _ = try await self.converterService.extractAudio(
                        from: sourceURL,
                        format: self.selectedAudioFormat,
                        bitrate: self.selectedAudioBitrate,
                        progressHandler: { p in
                            Task { @MainActor in self.conversionProgress = p }
                        }
                    )
                } else {
                    _ = try await self.converterService.transcodeVideo(
                        from: sourceURL,
                        codec: self.selectedVideoCodec,
                        quality: self.selectedVideoQuality,
                        progressHandler: { p in
                            Task { @MainActor in self.conversionProgress = p }
                        }
                    )
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    public func cancelConversion() {
        converterService.cancelCurrentTask()
        isTranscoding = false
        conversionProgress = 0.0
        HapticFeedback.shared.touchLight()
    }
}
