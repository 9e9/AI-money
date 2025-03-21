//
//  ExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreML

@Observable
class ExpenseViewModel {
    init() {}

    func addExpense(modelContext: ModelContext, date: Date, amount: Double, memo: String, category: Category?) {
        let newExpense = Expense(date: date, amount: amount, description: memo, category: category)
        modelContext.insert(newExpense)
    }

    func updateExpense(expense: Expense, newDate: Date, newAmount: Double, newMemo: String, newCategory: Category?) {
        expense.date = newDate
        expense.amount = newAmount
        expense.memo = newMemo
        expense.category = newCategory
    }

    func deleteExpense(modelContext: ModelContext, expense: Expense) {
        modelContext.delete(expense)
    }

    func fetchAllExpenses(modelContext: ModelContext) throws -> [Expense] {
        let fetchDescriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(fetchDescriptor)
    }

    func fetchExpenses(modelContext: ModelContext, forCategory category: Category) throws -> [Expense] {
        let predicate = #Predicate<Expense> { expense in
            expense.category.map { $0 == category } ?? false
        }
        let fetchDescriptor = FetchDescriptor<Expense>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(fetchDescriptor)
    }

    func fetchAllCategories(modelContext: ModelContext) throws -> [Category] {
        let fetchDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(fetchDescriptor)
    }

    func addCategory(modelContext: ModelContext, name: String) {
        let newCategory = Category(name: name)
        modelContext.insert(newCategory)
    }

    func deleteCategory(modelContext: ModelContext, category: Category) {
        do {
            let expensesToDelete = try fetchExpenses(modelContext: modelContext, forCategory: category)
            for expense in expensesToDelete {
                modelContext.delete(expense)
            }
            modelContext.delete(category)
        } catch {
            print("Error deleting category and its expenses: \(error)")
        }
    }

    func predictNextMonthSpending(modelContext: ModelContext) -> Double {
        // 임시 예측 로직: 지난 3개월 평균 지출액 계산
        let calendar = Calendar.current
        let currentDate = Date()
        var totalSpending: Double = 0
        var monthsCount = 0

        for monthOffset in 0..<3 {
            if let pastMonth = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate) {
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: pastMonth))!
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

                let predicate = #Predicate<Expense> { $0.date >= startOfMonth && $0.date <= endOfMonth }
                let fetchDescriptor = FetchDescriptor<Expense>(predicate: predicate)

                do {
                    let monthlyExpenses = try modelContext.fetch(fetchDescriptor)
                    let monthlySpending = monthlyExpenses.reduce(0) { $0 + $1.amount }
                    totalSpending += monthlySpending
                    monthsCount += 1
                } catch {
                    print("Error fetching expenses for prediction: \(error)")
                }
            }
        }

        if monthsCount > 0 {
            return totalSpending / Double(monthsCount)
        } else {
            return Double.random(in: 50000...150000) // 데이터가 없을 경우 임의의 값 반환
        }
    }
}
