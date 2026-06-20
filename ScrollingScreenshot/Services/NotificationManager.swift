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
            content.title = "Long Screenshot Ready"
            content.body = "Your scrolling screenshot has been saved to Photos."
            content.sound = .default
        } else {
            content.title = "Screenshot Failed"
            content.body = "Could not process the recording. Tap to try again."
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
