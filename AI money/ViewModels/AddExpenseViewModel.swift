//
//  AddExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import Combine

class AddExpenseViewModel: ObservableObject {
    @Published var expenseGroups: [ExpenseGroup] = [ExpenseGroup()]
    @Published var allCategories: [String] = []
    @Published var validationErrors: [Int: String] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Real-time validation as user types
        $expenseGroups
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] groups in
                self?.validateInRealTime()
            }
            .store(in: &cancellables)
    }

    func updateCategories() {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        let customCategories = UserDefaults.standard.customCategories
        allCategories = predefinedCategories + customCategories
    }
    
    private func validateInRealTime() {
        var errors: [Int: String] = [:]
        
        for (index, group) in expenseGroups.enumerated() {
            if !group.amount.isEmpty {
                if let amount = Double(group.amount), amount <= 0 {
                    errors[index] = "금액은 0보다 커야 합니다."
                } else if group.amount.contains(".") && group.amount.components(separatedBy: ".")[1].count > 0 {
                    errors[index] = "원 단위로만 입력 가능합니다."
                }
            }
        }
        
        validationErrors = errors
    }

    func validate() -> (Bool, String?) {
        var hasValidAmount = false
        var errorMessages: [String] = []
        
        for (index, group) in expenseGroups.enumerated() {
            if group.amount.isEmpty {
                continue // Empty amounts are allowed, user might be adding multiple expenses
            }
            
            guard let amount = Double(group.amount), amount > 0 else {
                errorMessages.append("지출 #\(index + 1): 올바른 금액을 입력하세요.")
                continue
            }
            
            if amount > 10_000_000 {
                errorMessages.append("지출 #\(index + 1): 금액이 너무 큽니다. (최대 1천만원)")
                continue
            }
            
            hasValidAmount = true
        }
        
        if !hasValidAmount {
            return (false, "최소 하나의 지출 금액을 입력해야 저장할 수 있습니다.")
        }
        
        if !errorMessages.isEmpty {
            return (false, errorMessages.joined(separator: "\n"))
        }
        
        return (true, nil)
    }

    func makeExpenses(selectedDate: Date) -> [Expense] {
        return expenseGroups.compactMap { group in
            guard let amount = Double(group.amount), amount > 0 else { return nil }
            return Expense(
                date: selectedDate, 
                category: group.category, 
                amount: amount, 
                note: group.note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    func removeGroup(at index: Int) {
        guard expenseGroups.count > 1, index < expenseGroups.count else { return }
        expenseGroups.remove(at: index)
        
        // Clean up validation errors for removed item and adjust indices
        var newErrors: [Int: String] = [:]
        for (errorIndex, message) in validationErrors {
            if errorIndex < index {
                newErrors[errorIndex] = message
            } else if errorIndex > index {
                newErrors[errorIndex - 1] = message
            }
        }
        validationErrors = newErrors
    }

    func addGroup() {
        let newGroup = ExpenseGroup()
        expenseGroups.append(newGroup)
    }
    
    func clearValidationError(for index: Int) {
        validationErrors.removeValue(forKey: index)
    }
}
