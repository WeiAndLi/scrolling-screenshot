import UserNotifications

protocol NotificationManagerProtocol {
    func requestAuthorization() async throws
    func notifyProcessingComplete(sessionId: String, success: Bool)
}

final class NotificationManager: NotificationManagerProtocol {

    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else {
            throw NotificationError.denied
        }
    }

    func notifyProcessingComplete(sessionId: String, success: Bool) {
        let content = UNMutableNotificationContent()
        if success {
            content.title = "长截图已就绪"
            content.body = "滚动长截图已保存到相册"
            content.sound = .default
        } else {
            content.title = "截图失败"
            content.body = "无法处理录制视频，请重试"
            content.sound = .default
        }

        content.userInfo = ["sessionId": sessionId]

        let request = UNNotificationRequest(
            identifier: "stitch-\(sessionId)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

enum NotificationError: LocalizedError {
    case denied

    var errorDescription: String? {
        switch self {
        case .denied: return "Notification permission was denied"
        }
    }
}
