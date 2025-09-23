//
//  ExpenseServiceProtocol.swift
//  AI money
//
//  Created by 조준희 on 9/22/25.
//

import Foundation

@MainActor
protocol ExpenseServiceProtocol: AnyObject {
    var expenses: [Expense] { get }
    var customCategories: [String] { get }
    
    func addExpense(_ expense: Expense)
    func removeExpense(_ expense: Expense)
    func removeExpenses(for category: String)
    func addCustomCategory(_ category: String)
    func removeCustomCategory(_ category: String)
    func totalExpense(for date: Date) -> Double
    func formatAmount(_ amount: Double) -> String
}

@MainActor
protocol ExpenseCalendarServiceProtocol: ExpenseServiceProtocol {
    var calendarState: CalendarState { get }
    var selectedYear: Int { get set }
    var selectedMonth: Int { get set }
    var currentMonthExpenses: [Expense] { get }
    var monthlyTotal: Double { get }
    var calendarDays: [CalendarDay] { get }
    
    func selectDate(_ date: Date?)
    func moveToPreviousMonth()
    func moveToNextMonth()
    func resetToCurrentDate()
    func updateSelectedPeriod(year: Int, month: Int)
}
