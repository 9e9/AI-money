//
//  ExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    
    init() {
        loadExpenses()
    }
    
    func loadExpenses() {
        // Load expenses from storage or sample data
        expenses = [Expense(date: Date(), category: "식비", amount: 20000.0, note: "점심"),
                    Expense(date: Date(), category: "교통비", amount: 15000.0, note: "버스 요금")]
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    func removeExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
        }
    }
}
