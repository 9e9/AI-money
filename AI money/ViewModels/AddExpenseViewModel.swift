//
//  AddExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftUI

class AddExpenseViewModel: ObservableObject {
    @Published var expenseGroups: [ExpenseGroup] = [ExpenseGroup()]
    @Published var allCategories: [String] = []
    @Published var totalAmount: Double = 0
    @Published var hasUnsavedChanges: Bool = false
    @Published var focusedCardIndex: Int? = nil
    
    private let quickAmountSuggestions = ["5000", "10000", "20000", "30000", "50000", "100000"]
    
    var validExpenseCount: Int {
        expenseGroups.filter { !$0.amount.isEmpty && Double($0.amount) ?? 0 > 0 }.count
    }
    
    var hasValidExpenses: Bool {
        expenseGroups.contains { !$0.amount.isEmpty && Double($0.amount) ?? 0 > 0 }
    }
    
    var isEmpty: Bool {
        expenseGroups.count == 1 && expenseGroups.first?.amount.isEmpty == true
    }

    func updateCategories() {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        let customCategories = UserDefaults.standard.customCategories
        allCategories = predefinedCategories + customCategories
        
        for index in expenseGroups.indices {
            if expenseGroups[index].category.isEmpty {
                expenseGroups[index].category = allCategories.first ?? "기타"
            }
        }
        updateTotalAmount()
    }

    func validate() -> (Bool, String?) {
        for (index, group) in expenseGroups.enumerated() {
            if group.amount.isEmpty {
                return (false, "지출 \(index + 1)번의 금액을 입력해주세요.")
            }
            guard let amount = Double(group.amount), amount > 0 else {
                return (false, "지출 \(index + 1)번의 금액이 올바르지 않습니다.")
            }
            if amount > 10_000_000 {
                return (false, "지출 \(index + 1)번의 금액이 너무 큽니다.")
            }
        }
        return (true, nil)
    }

    func makeExpenses(selectedDate: Date) -> [Expense] {
        expenseGroups.compactMap { group in
            guard let amount = Double(group.amount), amount > 0 else { return nil }
            return Expense(date: selectedDate, category: group.category, amount: amount, note: group.note)
        }
    }

    func removeGroup(at index: Int) {
        guard expenseGroups.count > 1 else { return }
        expenseGroups.remove(at: index)
        updateTotalAmount()
        hasUnsavedChanges = true
    }

    func addGroup() {
        var newGroup = ExpenseGroup()
        newGroup.category = allCategories.first ?? "기타"
        expenseGroups.append(newGroup)
        focusedCardIndex = expenseGroups.count - 1
        hasUnsavedChanges = true
        updateTotalAmount()
    }
    
    func duplicateGroup(at index: Int) {
        guard index < expenseGroups.count else { return }
        let originalGroup = expenseGroups[index]
        var newGroup = ExpenseGroup()
        newGroup.category = originalGroup.category
        newGroup.note = originalGroup.note
        
        expenseGroups.insert(newGroup, at: index + 1)
        focusedCardIndex = index + 1
        hasUnsavedChanges = true
    }
    
    func applyQuickAmount(_ amount: String, to index: Int) {
        guard index < expenseGroups.count else { return }
        expenseGroups[index].amount = amount
        expenseGroups[index].formattedAmount = formatWithComma(amount)
        updateTotalAmount()
        hasUnsavedChanges = true
    }
    
    func getQuickAmounts() -> [String] {
        return quickAmountSuggestions
    }
    
    private func updateTotalAmount() {
        totalAmount = expenseGroups.compactMap { Double($0.amount) }.reduce(0, +)
    }
    
    private func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? numberString
    }
}
