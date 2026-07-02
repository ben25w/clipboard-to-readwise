import AppKit
import UserNotifications

final class ClipboardToReadwiseApp: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            NSApp.setActivationPolicy(.regular)

            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.delegate = self
            _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])

            let coordinator = AppCoordinator()
            coordinator.start()
            self.coordinator = coordinator
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
