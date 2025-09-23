//
//  ExpenseCalendarModels.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation

struct CalendarConfiguration {
    static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
    static let calendarGridRows = 6
    static let daysPerWeek = 7
    static let totalCalendarDays = calendarGridRows * daysPerWeek
}

struct CalendarDay {
    let date: Date
    let isInCurrentMonth: Bool
    let dayNumber: Int
    let totalExpense: Double
    
    var hasExpense: Bool {
        totalExpense > 0
    }
    
    var formattedExpense: String {
        if totalExpense <= 0 { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: totalExpense)) ?? "0") + "원"
    }
}

struct DailyExpenseSummary {
    let date: Date
    let expenses: [Expense]
    let totalAmount: Double
    
    var isEmpty: Bool {
        expenses.isEmpty
    }
    
    var categoryBreakdown: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var mostExpensiveCategory: String? {
        categoryBreakdown.max(by: { $0.value < $1.value })?.key
    }
    
    init(date: Date, expenses: [Expense]) {
        self.date = date
        self.expenses = expenses
        self.totalAmount = expenses.reduce(0) { $0 + $1.amount }
    }
}

struct ExpenseCardData {
    let expense: Expense
    let formattedAmount: String
    let hasNote: Bool
    
    init(expense: Expense) {
        self.expense = expense
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        self.formattedAmount = (formatter.string(from: NSNumber(value: expense.amount)) ?? "0") + "원"
        self.hasNote = !expense.note.isEmpty
    }
}

enum CalendarState {
    case noDateSelected
    case dateSelectedWithExpenses(DailyExpenseSummary)
    case dateSelectedWithoutExpenses(Date)
    
    var selectedDate: Date? {
        switch self {
        case .noDateSelected:
            return nil
        case .dateSelectedWithExpenses(let summary):
            return summary.date
        case .dateSelectedWithoutExpenses(let date):
            return date
        }
    }
    
    var hasExpenses: Bool {
        switch self {
        case .dateSelectedWithExpenses:
            return true
        default:
            return false
        }
    }
}

struct CalendarAnimationConfiguration {
    static let monthTransitionDuration: Double = 0.3
    static let selectionAnimationDuration: Double = 0.2
    static let expenseListAnimationDuration: Double = 0.25
}
