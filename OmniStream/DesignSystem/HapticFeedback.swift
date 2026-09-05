import SwiftUI
import UIKit

// MARK: - Haptic Feedback Engine
/// Trình quản lý phản hồi xúc giác (Haptics) chuẩn xác,
/// mang lại cảm giác chân thực khi chạm vào các bề mặt kính ảo (Liquid Glass).

public final class HapticFeedback {
    public static let shared = HapticFeedback()
    private init() {}

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    /// Phản hồi nhẹ khi chạm nút kính nhỏ
    public func touchLight() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    /// Phản hồi vừa khi bấm nút chính (Tải xuống, Bắt đầu)
    public func touchMedium() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    /// Phản hồi cứng khi bấm nút thao tác quan trọng
    public func touchRigid() {
        rigidImpact.prepare()
        rigidImpact.impactOccurred()
    }

    /// Phản hồi mềm khi mở sheet hoặc chuyển tab
    public func touchSoft() {
        softImpact.prepare()
        softImpact.impactOccurred()
    }

    /// Phản hồi khi trượt slider chọn bitrate hoặc scrub thời gian
    public func selectionChanged() {
        selection.prepare()
        selection.selectionChanged()
    }

    /// Thông báo thành công (Tải xong, Chuyển đổi thành công, Lưu Camera Roll)
    public func notifySuccess() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Thông báo lỗi (Link hỏng, Chuyển đổi thất bại, Từ chối quyền Photos)
    public func notifyError() {
        notification.prepare()
        notification.notificationOccurred(.error)
    }

    /// Thông báo cảnh báo
    public func notifyWarning() {
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
}
