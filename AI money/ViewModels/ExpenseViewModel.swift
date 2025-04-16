//
//  ExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation

class ExpenseViewModel: ObservableObject {
    static let shared = ExpenseViewModel()

    @Published private(set) var expenses: [Expense] = []

    private init() {
        loadExpenses()
    }

    func loadExpenses() {
        guard expenses.isEmpty else {
            return
        }
        expenses = [
            Expense(date: Date(), category: "식비", amount: 20000.0, note: "점심"),
            Expense(date: Date(), category: "교통", amount: 15000.0, note: "버스 요금")
        ]
    }

    func addExpense(_ expense: Expense) {
        objectWillChange.send()
        expenses.append(expense)
    }

    func removeExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            objectWillChange.send()
            expenses.remove(at: index)
        }
    }

    func totalExpense(for date: Date) -> Double {
        let dailyExpenses = expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let total = dailyExpenses.reduce(0) { $0 + $1.amount }
        return total
    }
}
