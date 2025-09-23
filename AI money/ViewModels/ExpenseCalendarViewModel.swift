//
//  ExpenseCalendarViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class ExpenseCalendarViewModel: ObservableObject, ExpenseCalendarServiceProtocol {
    static let shared = ExpenseCalendarViewModel()

    @Published private(set) var expenses: [Expense] = []
    @Published var customCategories: [String] = []
    @Published var calendarState: CalendarState = .noDateSelected
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())

    private var modelContext: ModelContext?
    private let calendar = Calendar.current

    var currentMonthExpenses: [Expense] {
        expenses.filter { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return components.year == selectedYear && components.month == selectedMonth
        }
    }
    
    var monthlyTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var calendarDays: [CalendarDay] {
        generateCalendarDays()
    }

    init(context: ModelContext? = nil) {
        self.modelContext = context
        loadExpenses()
        loadCustomCategories()
        initializeCurrentDate()
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        loadExpenses()
    }
    
    func selectDate(_ date: Date?) {
        guard let date = date else {
            calendarState = .noDateSelected
            return
        }
        
        let dailyExpenses = expenses.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
        
        if dailyExpenses.isEmpty {
            calendarState = .dateSelectedWithoutExpenses(date)
        } else {
            let summary = DailyExpenseSummary(date: date, expenses: dailyExpenses)
            calendarState = .dateSelectedWithExpenses(summary)
        }
    }
    
    func moveToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        calendarState = .noDateSelected
    }
    
    func moveToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        calendarState = .noDateSelected
    }
    
    func resetToCurrentDate() {
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        selectedYear = components.year ?? selectedYear
        selectedMonth = components.month ?? selectedMonth
        selectDate(currentDate)
    }
    
    func updateSelectedPeriod(year: Int, month: Int) {
        selectedYear = year
        selectedMonth = month
        calendarState = .noDateSelected
    }

    func addExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        context.insert(expense)
        saveContext()
        loadExpenses()
        
        if let selectedDate = calendarState.selectedDate,
           calendar.isDate(expense.date, inSameDayAs: selectedDate) {
            selectDate(selectedDate)
        }
    }

    func removeExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        context.delete(expense)
        saveContext()
        loadExpenses()
        
        if let selectedDate = calendarState.selectedDate,
           calendar.isDate(expense.date, inSameDayAs: selectedDate) {
            selectDate(selectedDate)
        }
    }

    func removeExpenses(for category: String) {
        guard let context = modelContext else { return }
        for expense in expenses where expense.category == category {
            context.delete(expense)
        }
        saveContext()
        loadExpenses()
        
        if let selectedDate = calendarState.selectedDate {
            selectDate(selectedDate)
        }
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
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + "원"
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
    
    private func initializeCurrentDate() {
        let currentDate = Date()
        selectDate(currentDate)
    }
    
    private func generateCalendarDays() -> [CalendarDay] {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) else {
            return []
        }
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        
        let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonthDate)!.count
        
        var result: [CalendarDay] = []
        
        for i in stride(from: weekdayOfFirst - 2, through: 0, by: -1) {
            let date = calendar.date(from: DateComponents(year: prevMonthDate.year, month: prevMonthDate.month, day: daysInPrevMonth - i))!
            let day = CalendarDay(
                date: date,
                isInCurrentMonth: false,
                dayNumber: calendar.component(.day, from: date),
                totalExpense: totalExpense(for: date)
            )
            result.append(day)
        }
        
        for day in 1...daysInMonth {
            let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: day))!
            let calendarDay = CalendarDay(
                date: date,
                isInCurrentMonth: true,
                dayNumber: day,
                totalExpense: totalExpense(for: date)
            )
            result.append(calendarDay)
        }
        
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
        let remainingDays = CalendarConfiguration.totalCalendarDays - result.count
        
        for day in 1...remainingDays {
            let date = calendar.date(from: DateComponents(year: nextMonthDate.year, month: nextMonthDate.month, day: day))!
            let calendarDay = CalendarDay(
                date: date,
                isInCurrentMonth: false,
                dayNumber: day,
                totalExpense: totalExpense(for: date)
            )
            result.append(calendarDay)
        }
        
        return result
    }
}
