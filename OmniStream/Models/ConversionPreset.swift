import Foundation
import AVFoundation

// MARK: - Audio Format
public enum AudioFormat: String, CaseIterable, Identifiable, Codable {
    case m4a = "M4A"
    case aac = "AAC"
    case wav = "WAV"
    case mp3 = "MP3"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .m4a: return "m4a"
        case .aac: return "aac"
        case .wav: return "wav"
        case .mp3: return "mp3"
        }
    }

    public var mimeType: String {
        switch self {
        case .m4a: return "audio/mp4"
        case .aac: return "audio/aac"
        case .wav: return "audio/wav"
        case .mp3: return "audio/mpeg"
        }
    }

    public var description: String {
        switch self {
        case .m4a: return "MPEG-4 Audio (Khuyên dùng cho Apple Ecosystem)"
        case .aac: return "Advanced Audio Codec (Nhỏ gọn, chuẩn quốc tế)"
        case .wav: return "Linear PCM Uncompressed (Chất lượng phòng thu nguyên bản)"
        case .mp3: return "MPEG Layer 3 (Tương thích mọi thiết bị cổ điển)"
        }
    }
}

// MARK: - Audio Bitrate
public enum AudioBitrate: Int, CaseIterable, Identifiable, Codable {
    case kbps128 = 128_000
    case kbps192 = 192_000
    case kbps320 = 320_000

    public var id: Int { rawValue }

    public var label: String {
        switch self {
        case .kbps128: return "128 kbps"
        case .kbps192: return "192 kbps"
        case .kbps320: return "320 kbps"
        }
    }

    public var badge: String {
        switch self {
        case .kbps128: return "Tiết kiệm"
        case .kbps192: return "Chuẩn HQ"
        case .kbps320: return "Audiophile"
        }
    }
}

// MARK: - Video Codec
public enum VideoCodec: String, CaseIterable, Identifiable, Codable {
    case hevc = "HEVC (H.265)"
    case h264 = "H.264 (AVC)"

    public var id: String { rawValue }

    public var avExportPreset: String {
        switch self {
        case .hevc:
            return AVAssetExportPresetHEVCHighestQuality
        case .h264:
            return AVAssetExportPresetHighestQuality
        }
    }

    public var compressionDescription: String {
        switch self {
        case .hevc:
            return "Giảm 50% dung lượng, giữ nguyên độ nét, hỗ trợ iOS 11+"
        case .h264:
            return "Tương thích 100% với mọi nền tảng web, TV và thiết bị cũ"
        }
    }
}

// MARK: - Video Quality Preset
public enum VideoQualityTarget: String, CaseIterable, Identifiable, Codable {
    case original1080p = "1080p (Full HD)"
    case balanced720p = "720p (HD)"
    case compact480p = "480p (SD)"

    public var id: String { rawValue }

    public func exportPreset(for codec: VideoCodec) -> String {
        switch (codec, self) {
        case (.hevc, .original1080p):
            return AVAssetExportPresetHEVC1920x1080
        case (.hevc, _):
            return AVAssetExportPresetHEVCHighestQuality
        case (.h264, .original1080p):
            return AVAssetExportPreset1920x1080
        case (.h264, .balanced720p):
            return AVAssetExportPreset1280x720
        case (.h264, .compact480p):
            return AVAssetExportPreset640x480
        }
    }
}
