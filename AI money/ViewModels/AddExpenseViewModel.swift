//
//  AddExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

class AddExpenseViewModel: ObservableObject {
    @Published var expenseGroups: [ExpenseGroup] = [ExpenseGroup()]
    @Published var allCategories: [String] = []

    func updateCategories() {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        let customCategories = UserDefaults.standard.customCategories
        allCategories = predefinedCategories + customCategories
    }

    func validate() -> (Bool, String?) {
        for group in expenseGroups {
            guard let amount = Double(group.amount), amount > 0 else {
                return (false, "지출 금액을 입력해야 저장할 수 있습니다.")
            }
        }
        return (true, nil)
    }

    func makeExpenses(selectedDate: Date) -> [Expense] {
        expenseGroups.map {
            Expense(date: selectedDate, category: $0.category, amount: Double($0.amount) ?? 0, note: $0.note)
        }
    }

    func removeGroup(at index: Int) {
        guard expenseGroups.count > 1 else { return }
        expenseGroups.remove(at: index)
    }

    func addGroup() {
        expenseGroups.append(ExpenseGroup())
    }
}
