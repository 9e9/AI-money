//
//  ExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftData
import Foundation

@Observable
class ExpenseViewModel {
    var modelContext: ModelContext

    init(context: ModelContext) {
        self.modelContext = context
    }

    func addExpense(title: String, amount: Double, date: Date, category: Category?) {
        let newExpense = Expense(title: title, amount: amount, date: date, category: category)
        modelContext.insert(newExpense)
    }

    func deleteExpense(_ expense: Expense) {
        modelContext.delete(expense)
    }
}
