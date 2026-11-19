import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    func prepare() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLog.warn("Notification authorization failed. \(type(of: error))")
                return
            }
            if !granted {
                AppLog.warn("Notification authorization was declined.")
            }
        }
    }

    func notifyTimeUp() {
        deliver(title: "Time's Up", body: "Your countdown has finished.")
    }

    func notifyMenuBarHint() {
        deliver(title: "Timer", body: "Timer keeps running in the menu bar.")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    private func deliver(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLog.warn("Notification was not delivered. \(type(of: error))")
            }
        }
    }
}
