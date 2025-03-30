//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftData
import Foundation

enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "식비"
    case transport = "교통비"
    case shopping = "쇼핑"
    case entertainment = "문화/오락"
    case other = "기타"
}

@Model
class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var category: String
    var expenseCategory: ExpenseCategory

    init(title: String, amount: Double, date: Date, category: String) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
    }
    
    init(amount: Double, date: Date, category: ExpenseCategory) {
        self.amount = amount
        self.date = date
        self.expenseCategory = category
    }
}
