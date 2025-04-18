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
    @Published var customCategories: [String] = []

    private init() {
        loadExpenses()
        loadCustomCategories()
    }

    private func loadExpenses() {
        expenses = [
            Expense(date: Date(), category: "식비", amount: 20000.0, note: "점심"),
            Expense(date: Date(), category: "교통", amount: 15000.0, note: "버스 요금")
        ]
    }

    private func loadCustomCategories() {
        customCategories = UserDefaults.standard.customCategories
    }

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    func removeExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    func removeExpenses(for category: String) {
        expenses.removeAll { $0.category == category }
    }

    func addCustomCategory(_ category: String) {
        guard !customCategories.contains(category) else { return }
        customCategories.append(category)
        UserDefaults.standard.customCategories = customCategories
    }

    func removeCustomCategory(_ category: String) {
        if let index = customCategories.firstIndex(of: category) {
            customCategories.remove(at: index)
            UserDefaults.standard.customCategories = customCategories
        }
    }

    func totalExpense(for date: Date) -> Double {
        expenses
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .map { $0.amount }
            .reduce(0, +)
    }
}
