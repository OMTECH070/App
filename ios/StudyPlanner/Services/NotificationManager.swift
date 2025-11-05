import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if let error = error {
                    print("Notification authorization error: \(error)")
                }
            }
        }
    }

    func scheduleStudyReminder(for date: Date, subject: String, topics: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Study Reminder"
        content.subtitle = subject
        content.body = topics ?? "Time to focus on \(subject)"
        content.sound = .default
        content.categoryIdentifier = "STUDY_REMINDER"
        content.userInfo = ["subject": subject]

        // Add action buttons
        let startAction = UNNotificationAction(identifier: "START_SESSION", title: "Start Study", options: [.foreground])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Snooze 5 min", options: [])
        let skipAction = UNNotificationAction(identifier: "SKIP", title: "Skip", options: [.destructive])

        let category = UNNotificationCategory(
            identifier: "STUDY_REMINDER",
            actions: [startAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "study_reminder_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling study reminder: \(error)")
            }
        }
    }

    func scheduleBreakReminder(for date: Date, sessionDuration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Break Time"
        content.body = "You've been studying for \(Int(sessionDuration / 60)) minutes. Time for a break!"
        content.sound = .default
        content.categoryIdentifier = "BREAK_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "break_reminder_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling break reminder: \(error)")
            }
        }
    }

    func scheduleProgressUpdate(hour: Int, completedSessions: Int, totalSessions: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Progress Update"
        content.body = "You've completed \(completedSessions) out of \(totalSessions) study sessions today!"
        content.sound = .default
        content.categoryIdentifier = "PROGRESS_UPDATE"

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "progress_update_\(hour)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling progress update: \(error)")
            }
        }
    }

    func scheduleMotivationalNotification() {
        let motivations = [
            "Every study session brings you closer to your goals! 💪",
            "Small progress is still progress. Keep going! 📚",
            "Your future self will thank you for the work you're doing today! 🌟",
            "Education is the passport to the future. 🎓",
            "The harder you work for something, the greater you'll feel when you achieve it! 🏆"
        ]

        let content = UNMutableNotificationContent()
        content.title = "Daily Motivation"
        content.body = motivations.randomElement()!
        content.sound = .default
        content.categoryIdentifier = "MOTIVATION"

        // Schedule for random time during preferred study hours
        var dateComponents = DateComponents()
        dateComponents.hour = Int.random(in: 9...21)
        dateComponents.minute = Int.random(in: 0...59)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "motivation_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling motivational notification: \(error)")
            }
        }
    }

    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.userInfo

        switch response.actionIdentifier {
        case "START_SESSION":
            // Handle start study session action
            NotificationCenter.default.post(name: .startStudySessionFromNotification, object: userInfo)
        case "SNOOZE":
            // Handle snooze action
            if let subject = userInfo["subject"] as? String {
                let snoozeDate = Date().addingTimeInterval(5 * 60) // 5 minutes
                scheduleStudyReminder(for: snoozeDate, subject: subject)
            }
        case "SKIP":
            // Handle skip action
            NotificationCenter.default.post(name: .skipStudySession, object: userInfo)
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleNotificationTap(userInfo: userInfo)
        default:
            break
        }

        completionHandler()
    }

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Handle notification tap based on category
        if let category = userInfo["category"] as? String {
            switch category {
            case "STUDY_REMINDER":
                NotificationCenter.default.post(name: .studyReminderTapped, object: userInfo)
            case "BREAK_REMINDER":
                NotificationCenter.default.post(name: .breakReminderTapped, object: userInfo)
            case "PROGRESS_UPDATE":
                NotificationCenter.default.post(name: .progressUpdateTapped, object: userInfo)
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startStudySessionFromNotification = Notification.Name("startStudySessionFromNotification")
    static let skipStudySession = Notification.Name("skipStudySession")
    static let studyReminderTapped = Notification.Name("studyReminderTapped")
    static let breakReminderTapped = Notification.Name("breakReminderTapped")
    static let progressUpdateTapped = Notification.Name("progressUpdateTapped")
}