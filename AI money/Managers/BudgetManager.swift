//
//  BudgetManager.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftData
import Foundation

@Model
class BudgetManager {
    var category: ExpenseCategory
    var limit: Double

    init(category: ExpenseCategory, limit: Double) {
        self.category = category
        self.limit = limit
    }
}
