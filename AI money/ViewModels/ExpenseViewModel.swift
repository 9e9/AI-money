//
//  ExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation
import SwiftData
import SwiftUI

class ExpenseViewModel: ObservableObject {
    static let shared = ExpenseViewModel()

    @Published private(set) var expenses: [Expense] = []
    @Published var customCategories: [String] = []

    private var modelContext: ModelContext?

    init(context: ModelContext? = nil) {
        self.modelContext = context
        loadExpenses()
        loadCustomCategories()
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        loadExpenses()
    }

    private func loadExpenses() {
        guard let context = modelContext else { return }
        let fetchRequest = FetchDescriptor<Expense>()
        do {
            expenses = try context.fetch(fetchRequest)
        } catch {
            print("지출 데이터를 불러오는 데 실패했습니다: \(error)")
            expenses = []
        }
    }

    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Context 저장 실패: \(error)")
        }
    }

    private func loadCustomCategories() {
        customCategories = UserDefaults.standard.customCategories
    }

    func addExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        context.insert(expense)
        saveContext()
        loadExpenses()
    }

    func removeExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        context.delete(expense)
        saveContext()
        loadExpenses()
    }

    func removeExpenses(for category: String) {
        guard let context = modelContext else { return }
        for expense in expenses where expense.category == category {
            context.delete(expense)
        }
        saveContext()
        loadExpenses()
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
