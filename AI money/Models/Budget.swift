//
//  Budget.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftData
import Foundation

@Model
class Budget {
    var budgetLimit: Double  // 사용자가 설정한 예산 한도
    var currentSpent: Double  // 현재까지 소비한 금액

    init(budgetLimit: Double, currentSpent: Double = 0) {
        self.budgetLimit = budgetLimit
        self.currentSpent = currentSpent
    }
}
