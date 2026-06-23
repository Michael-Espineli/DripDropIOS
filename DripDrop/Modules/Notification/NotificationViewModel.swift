//
//  NotificationViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/14/24.
//

import Foundation
import UserNotifications

final class NotificationViewModel {
    static let shared = NotificationViewModel()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                print("[NotificationViewModel][requestAuthorizationIfNeeded] \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }

    func scheduleServiceStopStartPrompt(
        serviceStopId: String,
        customerName: String,
        serviceType: String,
        arrivalTime: Date
    ) async {
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Start this stop?"
        content.body = "\(customerName) is nearby. Arrival time: \(arrivalTime.formatted(date: .omitted, time: .shortened))."
        content.sound = .default
        content.categoryIdentifier = "SERVICE_STOP_START_PROMPT"
        content.userInfo = [
            "serviceStopId": serviceStopId,
            "serviceType": serviceType
        ]

        let request = UNNotificationRequest(
            identifier: serviceStopStartPromptIdentifier(serviceStopId: serviceStopId),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            print("[NotificationViewModel][scheduleServiceStopStartPrompt] \(error)")
        }
    }

    func cancelServiceStopStartPrompt(serviceStopId: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: [serviceStopStartPromptIdentifier(serviceStopId: serviceStopId)]
        )
    }

    private func serviceStopStartPromptIdentifier(serviceStopId: String) -> String {
        "service-stop-start-\(serviceStopId)"
    }
}
