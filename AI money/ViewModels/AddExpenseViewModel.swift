//
//  AddExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftUI

struct ExpenseGroup {
    var category: String = "기타"
    var amount: String = ""
    var formattedAmount: String = ""
    var note: String = ""
}

class AddExpenseViewModel: ObservableObject {
    @Published var expenseGroups: [ExpenseGroup] = [ExpenseGroup()]
    @Published var allCategories: [String] = []
    @Published var totalAmount: Double = 0
    @Published var hasUnsavedChanges: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showingSaveAnimation: Bool = false
    
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
            
            if !FormatHelper.isValidAmount(group.amount) {
                return (false, "지출 \(index + 1)번의 금액이 올바르지 않습니다.")
            }
        }
        return (true, nil)
    }

    func makeExpenses(selectedDate: Date) -> [Expense] {
        expenseGroups.compactMap { group in
            guard let amount = FormatHelper.parseAmountString(group.amount), amount > 0 else { return nil }
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
        hasUnsavedChanges = true
    }
    
    func applyQuickAmount(_ amount: String, to index: Int) {
        guard index < expenseGroups.count else { return }
        expenseGroups[index].amount = amount
        expenseGroups[index].formattedAmount = FormatHelper.formatWithComma(amount)
        updateTotalAmount()
        hasUnsavedChanges = true
    }
    
    func getQuickAmounts() -> [String] {
        return quickAmountSuggestions
    }
    
    func validateAndPrepareForSave(selectedDate: Date, completion: @escaping ([Expense]?, String?) -> Void) {
        let (isValid, errorMsg) = validate()
        if !isValid {
            alertTitle = "확인"
            alertMessage = errorMsg ?? ""
            showingAlert = true
            completion(nil, errorMsg)
            return
        }
        
        showingSaveAnimation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newExpenses = self.makeExpenses(selectedDate: selectedDate)
            completion(newExpenses, nil)
        }
    }
    
    func completeSaveAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showingSaveAnimation = false
        }
    }
    
    func shouldShowExitAlert() -> Bool {
        return hasUnsavedChanges
    }
    
    func prepareExitAlert() {
        alertTitle = "나가기"
        alertMessage = "저장하지 않고 나가시겠습니까?"
        showingAlert = true
    }
    
    func formatSelectedDate(_ date: Date) -> String {
        return FormatHelper.formatSelectedDate(date)
    }
    
    func formatAmount(_ amount: Double) -> String {
        return FormatHelper.formatAmountWithoutCurrency(amount)
    }
    
    func updateAmountFormatting(at index: Int, newValue: String) {
        guard index < expenseGroups.count else { return }
        
        let filteredValue = newValue.replacingOccurrences(of: ",", with: "")
        if let number = Int(filteredValue), number >= 0 {
            expenseGroups[index].formattedAmount = FormatHelper.formatWithComma(String(number))
            expenseGroups[index].amount = String(number)
            hasUnsavedChanges = true
        } else if newValue.isEmpty {
            expenseGroups[index].formattedAmount = ""
            expenseGroups[index].amount = ""
            hasUnsavedChanges = true
        }
        updateTotalAmount()
    }
    
    private func updateTotalAmount() {
        totalAmount = expenseGroups.compactMap { FormatHelper.parseAmountString($0.amount) }.reduce(0, +)
    }
}
