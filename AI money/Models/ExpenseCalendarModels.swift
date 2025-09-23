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
    let holiday: KoreanHoliday?  // 새로 추가
    
    var hasExpense: Bool {
        totalExpense > 0
    }
    
    var isHoliday: Bool {  // 새로 추가
        holiday != nil
    }
    
    var isNationalHoliday: Bool {  // 국경일인지 확인
        holiday?.type == .national || holiday?.type == .traditional
    }
    
    var holidayColor: HolidayDisplayColor {  // 공휴일 표시 색상
        guard let holiday = holiday else { return .none }
        
        switch holiday.type {
        case .national, .traditional:
            return .red
        case .memorial:
            return .orange
        case .substitute:
            return .blue
        }
    }
    
    var formattedExpense: String {
        if totalExpense <= 0 { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: totalExpense)) ?? "0") + "원"
    }
}

enum HolidayDisplayColor {
    case none
    case red      // 국경일, 전통명절
    case orange   // 기념일
    case blue     // 대체공휴일
    
    var color: String {
        switch self {
        case .none: return "primary"
        case .red: return "red"
        case .orange: return "orange"
        case .blue: return "blue"
        }
    }
}

struct DailyExpenseSummary {
    let date: Date
    let expenses: [Expense]
    let totalAmount: Double
    let holiday: KoreanHoliday?  // 새로 추가
    
    var isEmpty: Bool {
        expenses.isEmpty
    }
    
    var isHoliday: Bool {  // 새로 추가
        holiday != nil
    }
    
    var categoryBreakdown: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var mostExpensiveCategory: String? {
        categoryBreakdown.max(by: { $0.value < $1.value })?.key
    }
    
    init(date: Date, expenses: [Expense], holiday: KoreanHoliday? = nil) {
        self.date = date
        self.expenses = expenses
        self.totalAmount = expenses.reduce(0) { $0 + $1.amount }
        self.holiday = holiday
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
    case dateSelectedWithoutExpenses(Date, KoreanHoliday?)  // 공휴일 정보 추가
    
    var selectedDate: Date? {
        switch self {
        case .noDateSelected:
            return nil
        case .dateSelectedWithExpenses(let summary):
            return summary.date
        case .dateSelectedWithoutExpenses(let date, _):
            return date
        }
    }
    
    var selectedHoliday: KoreanHoliday? {  // 새로 추가
        switch self {
        case .noDateSelected:
            return nil
        case .dateSelectedWithExpenses(let summary):
            return summary.holiday
        case .dateSelectedWithoutExpenses(_, let holiday):
            return holiday
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
