import Foundation
import AVFoundation
import Combine

// MARK: - Transcoding State
public enum TranscodingState: Equatable {
    case idle
    case processing(progress: Double)
    case completed(outputURL: URL)
    case failed(error: String)
}

// MARK: - Media Converter Service
/// Bộ máy chuyển đổi định dạng và trích xuất âm thanh ngoại tuyến (Offline Transcoder).
/// Sử dụng AVFoundation (AVAsset, AVAssetReader, AVAssetWriter, AVAssetExportSession)
/// chạy trực tiếp trên GPU/Apple Neural Engine, không phụ thuộc server hay mạng internet.

public final class MediaConverterService: ObservableObject {
    public static let shared = MediaConverterService()

    @Published public private(set) var currentState: TranscodingState = .idle
    private var currentExportSession: AVAssetExportSession?
    private var progressTimer: AnyCancellable?

    private init() {}

    // MARK: - 1. Audio Extraction (Tách âm thanh từ Video)
    /// Trích xuất âm thanh từ Video sang định dạng (M4A / AAC / WAV / MP3) với Bitrate tùy chỉnh
    public func extractAudio(
        from sourceURL: URL,
        format: AudioFormat,
        bitrate: AudioBitrate,
        outputName: String? = nil,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        await MainActor.run {
            self.currentState = .processing(progress: 0.0)
        }

        let asset = AVURLAsset(url: sourceURL)

        // Kiểm tra xem video có track âm thanh không
        let audioTracks: [AVAssetTrack]
        if #available(iOS 16.0, *) {
            audioTracks = try await asset.loadTracks(withMediaType: .audio)
        } else {
            audioTracks = asset.tracks(withMediaType: .audio)
        }

        guard !audioTracks.isEmpty else {
            let errorMsg = "Tệp video không chứa luồng âm thanh (No Audio Track)."
            await MainActor.run { self.currentState = .failed(error: errorMsg) }
            throw NSError(domain: "MediaConverter", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let baseName = outputName ?? sourceURL.deletingPathExtension().lastPathComponent
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFilename = "\(baseName)_\(bitrate.id/1000)k_\(UUID().uuidString.prefix(6)).\(format.fileExtension)"
        let tempOutputURL = tempDirectory.appendingPathComponent(tempFilename)

        if FileManager.default.fileExists(atPath: tempOutputURL.path) {
            try? FileManager.default.removeItem(at: tempOutputURL)
        }

        // Tùy theo định dạng, áp dụng AVAssetExportSession hoặc AVAssetReader + AVAssetWriter
        switch format {
        case .m4a, .aac, .mp3:
            try await extractAudioUsingWriter(
                asset: asset,
                outputURL: tempOutputURL,
                format: format,
                bitrate: bitrate,
                progressHandler: progressHandler
            )
        case .wav:
            try await extractAudioWAV(
                asset: asset,
                outputURL: tempOutputURL,
                progressHandler: progressHandler
            )
        }

        // Chuyển file hoàn tất vào Documents/Converted
        let finalURL = try StorageManager.shared.saveConvertedFile(
            from: tempOutputURL,
            filename: "\(baseName)_\(bitrate.id/1000)k.\(format.fileExtension)"
        )

        await MainActor.run {
            self.currentState = .completed(outputURL: finalURL)
            HapticFeedback.shared.notifySuccess()
        }

        return finalURL
    }

    // MARK: - 2. Video Compression & Transcoding (Nén & chuyển đổi video)
    /// Nén hoặc đổi mã hóa video sang HEVC (H.265) hoặc H.264
    public func transcodeVideo(
        from sourceURL: URL,
        codec: VideoCodec,
        quality: VideoQualityTarget,
        outputName: String? = nil,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        await MainActor.run {
            self.currentState = .processing(progress: 0.0)
        }

        let asset = AVURLAsset(url: sourceURL)
        let presetName = quality.exportPreset(for: codec)

        // Kiểm tra độ tương thích của preset với asset
        let compatiblePresets: [String]
        if #available(iOS 16.0, *) {
            compatiblePresets = await AVAssetExportSession.exportPresets(compatibleWith: asset)
        } else {
            compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        }

        let finalPreset = compatiblePresets.contains(presetName) ? presetName : AVAssetExportPresetHighestQuality

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: finalPreset) else {
            let errorMsg = "Không thể khởi tạo phiên nén video với preset: \(finalPreset)"
            await MainActor.run { self.currentState = .failed(error: errorMsg) }
            throw NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        self.currentExportSession = exportSession

        let baseName = outputName ?? sourceURL.deletingPathExtension().lastPathComponent
        let tempDirectory = FileManager.default.temporaryDirectory
        let ext = "mp4"
        let tempFilename = "\(baseName)_transcoded_\(UUID().uuidString.prefix(6)).\(ext)"
        let tempOutputURL = tempDirectory.appendingPathComponent(tempFilename)

        if FileManager.default.fileExists(atPath: tempOutputURL.path) {
            try? FileManager.default.removeItem(at: tempOutputURL)
        }

        exportSession.outputURL = tempOutputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Theo dõi tiến trình nén qua Timer
        let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        self.progressTimer = timer.sink { [weak exportSession] _ in
            guard let session = exportSession else { return }
            let progress = Double(session.progress)
            progressHandler(progress)
            Task { @MainActor in
                MediaConverterService.shared.currentState = .processing(progress: progress)
            }
        }

        await exportSession.export()
        self.progressTimer?.cancel()
        self.progressTimer = nil

        switch exportSession.status {
        case .completed:
            let finalURL = try StorageManager.shared.saveConvertedFile(
                from: tempOutputURL,
                filename: "\(baseName)_\(codec.rawValue.prefix(4)).mp4"
            )
            await MainActor.run {
                self.currentState = .completed(outputURL: finalURL)
                HapticFeedback.shared.notifySuccess()
            }
            return finalURL

        case .failed:
            let err = exportSession.error?.localizedDescription ?? "Nén video thất bại"
            await MainActor.run {
                self.currentState = .failed(error: err)
                HapticFeedback.shared.notifyError()
            }
            throw exportSession.error ?? NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: err])

        case .cancelled:
            let err = "Tác vụ nén đã bị hủy"
            await MainActor.run { self.currentState = .idle }
            throw NSError(domain: "MediaConverter", code: -2, userInfo: [NSLocalizedDescriptionKey: err])

        default:
            throw NSError(domain: "MediaConverter", code: -3, userInfo: [NSLocalizedDescriptionKey: "Trạng thái không xác định"])
        }
    }

    /// Hủy tác vụ chuyển đổi đang chạy
    public func cancelCurrentTask() {
        currentExportSession?.cancelExport()
        progressTimer?.cancel()
        progressTimer = nil
        currentState = .idle
    }

    // MARK: - Private Pipeline: AVAssetReader & AVAssetWriter for Audio Bitrate
    private func extractAudioUsingWriter(
        asset: AVAsset,
        outputURL: URL,
        format: AudioFormat,
        bitrate: AudioBitrate,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        let reader = try AVAssetReader(asset: asset)
        let audioTracks: [AVAssetTrack]
        if #available(iOS 16.0, *) {
            audioTracks = try await asset.loadTracks(withMediaType: .audio)
        } else {
            audioTracks = asset.tracks(withMediaType: .audio)
        }

        guard let firstAudioTrack = audioTracks.first else {
            throw NSError(domain: "MediaConverter", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy track audio"])
        }

        // Reader output: Linear PCM 16-bit
        let readerOutputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: firstAudioTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)

        // Writer output: AAC / M4A với Bitrate chính xác (128k, 192k, 320k)
        let fileType: AVFileType = (format == .m4a || format == .mp3) ? .m4a : .caf
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: fileType)

        var channelLayout = AudioChannelLayout()
        memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
        channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo

        let writerInputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: bitrate.rawValue,
            AVChannelLayoutKey: Data(bytes: &channelLayout, count: MemoryLayout<AudioChannelLayout>.size)
        ]

        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerInputSettings)
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)

        guard reader.startReading() else {
            throw reader.error ?? NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể bắt đầu đọc audio"])
        }

        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể bắt đầu ghi audio"])
        }

        writer.startSession(atSourceTime: .zero)

        let totalDuration: CMTime
        if #available(iOS 16.0, *) {
            totalDuration = try await asset.load(.duration)
        } else {
            totalDuration = asset.duration
        }
        let totalSeconds = CMTimeGetSeconds(totalDuration)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let queue = DispatchQueue(label: "com.omnistream.audio.transcode", qos: .userInitiated)

            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        writerInput.append(sampleBuffer)

                        let currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                        let currentSeconds = CMTimeGetSeconds(currentSampleTime)
                        if totalSeconds > 0 {
                            let progress = min(1.0, max(0.0, currentSeconds / totalSeconds))
                            DispatchQueue.main.async {
                                progressHandler(progress)
                                self.currentState = .processing(progress: progress)
                            }
                        }
                    } else {
                        // Kết thúc stream
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: writer.error ?? NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Lỗi hoàn tất ghi audio"]))
                            }
                        }
                        break
                    }
                }
            }
        }
    }

    // MARK: - Private Pipeline: Uncompressed WAV Audio
    private func extractAudioWAV(
        asset: AVAsset,
        outputURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể khởi tạo xuất WAV"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .wav

        let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        self.progressTimer = timer.sink { [weak exportSession] _ in
            guard let session = exportSession else { return }
            let p = Double(session.progress)
            progressHandler(p)
            Task { @MainActor in
                MediaConverterService.shared.currentState = .processing(progress: p)
            }
        }

        await exportSession.export()
        self.progressTimer?.cancel()
        self.progressTimer = nil

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "MediaConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Xuất WAV không thành công"])
        }
    }
}
