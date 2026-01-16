//
//  Notifications.swift
//  Sergeant AI
//
//  Created by Samuel Ramirez on 12/26/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            print("Notifications granted:", granted)
        }
    }

    func scheduleTaskOverdueNotification(
        taskID: UUID,
        title: String,
        dueDate: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Task Overdue"
        content.body = "You failed to complete: \(title)"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            ),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: taskID.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(taskID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [taskID.uuidString]
            )
    }
}
