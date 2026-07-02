import Foundation
import UserNotifications

enum NotificationService {
    static func showFailure(message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Couldn't save to Readwise"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "readwise-send-failed-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
