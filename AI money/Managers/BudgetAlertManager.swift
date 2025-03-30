//
//  BudgetAIert.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import UserNotifications
import SwiftUI

class BudgetAlertManager {
    static let shared = BudgetAlertManager()

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
        }
    }

    func sendBudgetWarning() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 예산 초과 경고!"
        content.body = "소비 속도를 조절하지 않으면 이번 달 예산을 초과할 가능성이 높아요!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "budgetWarning", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 등록 실패: \(error.localizedDescription)")
            }
        }
    }
}
