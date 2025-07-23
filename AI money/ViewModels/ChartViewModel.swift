//
//  ChartViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftUI

struct CategoryTotal: Hashable {
    let category: String
    let total: Double
}

class ChartViewModel: ObservableObject {
    @Published var sortOrder: SortOrder = .defaultOrder
    @Published var selectedYear: Int
    @Published var selectedMonth: Int
    @Published var isShowingYearMonthPicker = false

    enum SortOrder: String, CaseIterable, Identifiable {
        case defaultOrder = "기본순"
        case highToLow = "높은 순"
        case lowToHigh = "낮은 순"

        var id: String { self.rawValue }
    }

    private var expenseViewModel: ExpenseCalendarViewModel

    private static let plainNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    init(expenseViewModel: ExpenseCalendarViewModel) {
        self.expenseViewModel = expenseViewModel
        let now = Date()
        let calendar = Calendar.current
        _selectedYear = Published(initialValue: calendar.component(.year, from: now))
        _selectedMonth = Published(initialValue: calendar.component(.month, from: now))
    }

    var allCategories: [String] {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        return predefinedCategories + expenseViewModel.customCategories
    }

    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        return expenseViewModel.expenses.filter { expense in
            let expenseDate = calendar.dateComponents([.year, .month], from: expense.date)
            return expenseDate.year == selectedYear && expenseDate.month == selectedMonth
        }
    }

    var sortedCategoryTotals: [CategoryTotal] {
        let totals = filteredExpenses.reduce(into: [String: Double]()) { result, expense in
            result[expense.category, default: 0.0] += expense.amount
        }

        let completeTotals = allCategories.reduce(into: [String: Double]()) { result, category in
            result[category] = totals[category, default: 0.0]
        }

        let sorted: [CategoryTotal]
        switch sortOrder {
        case .highToLow:
            sorted = completeTotals.sorted {
                if $0.value == $1.value {
                    return allCategories.firstIndex(of: $0.key)! < allCategories.firstIndex(of: $1.key)!
                }
                return $0.value > $1.value
            }.map { CategoryTotal(category: $0.key, total: $0.value) }
        case .lowToHigh:
            sorted = completeTotals.sorted {
                if $0.value == $1.value {
                    return allCategories.firstIndex(of: $0.key)! < allCategories.firstIndex(of: $1.key)!
                }
                return $0.value < $1.value
            }.map { CategoryTotal(category: $0.key, total: $0.value) }
        case .defaultOrder:
            sorted = allCategories.map { CategoryTotal(category: $0, total: completeTotals[$0] ?? 0.0) }
        }
        return sorted
    }

    func resetToCurrentDate() {
        let now = Date()
        let calendar = Calendar.current
        selectedYear = calendar.component(.year, from: now)
        selectedMonth = calendar.component(.month, from: now)
        sortOrder = .defaultOrder
    }

    func setYearMonth(year: Int, month: Int) {
        selectedYear = year
        selectedMonth = month
        sortOrder = .defaultOrder
    }

    func formatYear(_ year: Int) -> String {
        return Self.plainNumberFormatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }
}
