import Foundation
import Photos
import UIKit

// MARK: - Photo Library Manager
/// Quản lý quyền và lưu video vào Cuộn Camera (Camera Roll / Photo Library) của iOS.

public final class PhotoLibraryManager {
    public static let shared = PhotoLibraryManager()
    private init() {}

    public enum PhotoSaveError: LocalizedError {
        case permissionDenied
        case permissionRestricted
        case fileNotFound
        case invalidVideoFormat
        case unknown(Error)

        public var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Quyền truy cập Thư viện ảnh bị từ chối. Vui lòng bật quyền trong Cài đặt iPhone."
            case .permissionRestricted:
                return "Quyền bị giới hạn bởi tài khoản hoặc thiết bị."
            case .fileNotFound:
                return "Không tìm thấy tệp video để lưu."
            case .invalidVideoFormat:
                return "Định dạng video không được Photos hỗ trợ (chỉ hỗ trợ MP4/MOV)."
            case .unknown(let error):
                return "Lỗi lưu thư viện ảnh: \(error.localizedDescription)"
            }
        }
    }

    /// Yêu cầu cấp quyền thêm vào Photos
    public func requestAddPermission() async -> Bool {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .limited:
                return true
            case .notDetermined:
                let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                return newStatus == .authorized || newStatus == .limited
            case .denied, .restricted:
                return false
            @unknown default:
                return false
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .authorized { return true }
            if status == .notDetermined {
                return await withCheckedContinuation { continuation in
                    PHPhotoLibrary.requestAuthorization { newStatus in
                        continuation.resume(returning: newStatus == .authorized)
                    }
                }
            }
            return false
        }
    }

    /// Lưu tệp video vào Cuộn Camera
    public func saveVideoToCameraRoll(videoURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw PhotoSaveError.fileNotFound
        }

        // Đảm bảo là định dạng video tương thích (MP4 hoặc MOV)
        let ext = videoURL.pathExtension.lowercased()
        guard ["mp4", "mov", "m4v"].contains(ext) else {
            throw PhotoSaveError.invalidVideoFormat
        }

        let isAuthorized = await requestAddPermission()
        guard isAuthorized else {
            throw PhotoSaveError.permissionDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if success {
                    HapticFeedback.shared.notifySuccess()
                    continuation.resume()
                } else if let error = error {
                    HapticFeedback.shared.notifyError()
                    continuation.resume(throwing: PhotoSaveError.unknown(error))
                } else {
                    continuation.resume(throwing: PhotoSaveError.unknown(NSError(domain: "PhotoLibraryManager", code: -1)))
                }
            }
        }
    }
}
