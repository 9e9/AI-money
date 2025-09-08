//
//  YearMonthPickerViewModel.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation
import SwiftUI

@MainActor
class YearMonthPickerViewModel: ObservableObject {
    @Published var statistics = ExpenseStatistics(
        totalExpense: 0,
        mostSpentCategory: nil,
        averageMonthlyExpense: 0,
        prevYearSameMonthExpense: 0,
        expenseChangeRate: 0
    )
    @Published var showStats: Bool = false
    @Published var selectedPeriod: DatePeriod
    
    private var expenseCalendarViewModel: ExpenseCalendarViewModel
    
    var hasMostSpentCategory: Bool {
        statistics.mostSpentCategory != nil
    }
    
    var hasPrevYearData: Bool {
        statistics.hasPrevYearData
    }
    
    init(expenseCalendarViewModel: ExpenseCalendarViewModel, year: Int, month: Int) {
        self.expenseCalendarViewModel = expenseCalendarViewModel
        self.selectedPeriod = DatePeriod(year: year, month: month)
    }
    
    func updatePeriod(year: Int, month: Int) {
        selectedPeriod = DatePeriod(year: year, month: month)
        updateExpenseStatsWithAnimation()
    }
    
    func updateExpenseStatsWithAnimation() {
        withAnimation(.easeOut(duration: AnimationConfiguration.fadeOutDuration)) {
            showStats = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConfiguration.fadeOutDuration) {
            self.updateExpenseStats()
            
            withAnimation(.easeIn(duration: AnimationConfiguration.fadeInDuration)) {
                self.showStats = true
            }
        }
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedString = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return formattedString + "원"
    }
    
    func resetStats() {
        statistics = ExpenseStatistics(
            totalExpense: 0,
            mostSpentCategory: nil,
            averageMonthlyExpense: 0,
            prevYearSameMonthExpense: 0,
            expenseChangeRate: 0
        )
        showStats = false
    }
    
    private func updateExpenseStats() {
        let calendar = Calendar.current
        
        // 현재 선택된 월의 지출 계산
        let totalExpense = calculateCurrentMonthExpense(calendar: calendar)
        
        // 최다 지출 카테고리 계산
        let mostSpentCategory = calculateMostSpentCategory(calendar: calendar)
        
        // 3개월 평균 계산
        let averageMonthlyExpense = calculateAverageMonthlyExpense(calendar: calendar)
        
        // 작년 동월 지출 계산
        let prevYearSameMonthExpense = calculatePrevYearSameMonthExpense(calendar: calendar)
        
        // 변화율 계산
        let expenseChangeRate = calculateExpenseChangeRate(
            current: totalExpense,
            previous: prevYearSameMonthExpense
        )
        
        // 통계 업데이트
        statistics = ExpenseStatistics(
            totalExpense: totalExpense,
            mostSpentCategory: mostSpentCategory,
            averageMonthlyExpense: averageMonthlyExpense,
            prevYearSameMonthExpense: prevYearSameMonthExpense,
            expenseChangeRate: expenseChangeRate
        )
    }
    
    private func calculateCurrentMonthExpense(calendar: Calendar) -> Double {
        let filteredExpenses = getFilteredExpenses(
            year: selectedPeriod.year,
            month: selectedPeriod.month,
            calendar: calendar
        )
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateMostSpentCategory(calendar: Calendar) -> ExpenseCategoryInfo? {
        let filteredExpenses = getFilteredExpenses(
            year: selectedPeriod.year,
            month: selectedPeriod.month,
            calendar: calendar
        )
        let categoryGroups = Dictionary(grouping: filteredExpenses, by: { $0.category })
        let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        if let (category, amount) = categorySums.max(by: { $0.value < $1.value }), amount > 0 {
            return ExpenseCategoryInfo(category: category, amount: amount)
        }
        return nil
    }
    
    private func calculateAverageMonthlyExpense(calendar: Calendar) -> Double {
        var lastThreeMonthsExpense: [Double] = []
        
        for offset in 0..<3 {
            guard let targetDate = calendar.date(from: DateComponents(year: selectedPeriod.year, month: selectedPeriod.month)),
                  let targetMonth = calendar.date(byAdding: .month, value: -offset, to: targetDate) else {
                continue
            }
            
            let y = calendar.component(.year, from: targetMonth)
            let m = calendar.component(.month, from: targetMonth)
            let expenses = getFilteredExpenses(year: y, month: m, calendar: calendar)
            lastThreeMonthsExpense.append(expenses.reduce(0) { $0 + $1.amount })
        }
        
        return lastThreeMonthsExpense.isEmpty ? 0 :
            lastThreeMonthsExpense.reduce(0, +) / Double(lastThreeMonthsExpense.count)
    }
    
    private func calculatePrevYearSameMonthExpense(calendar: Calendar) -> Double {
        let prevYearExpenses = getFilteredExpenses(
            year: selectedPeriod.year - 1,
            month: selectedPeriod.month,
            calendar: calendar
        )
        return prevYearExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateExpenseChangeRate(current: Double, previous: Double) -> Double {
        if previous > 0 {
            return ((current - previous) / previous) * 100
        } else {
            return current > 0 ? 100 : 0
        }
    }
    
    private func getFilteredExpenses(year: Int, month: Int, calendar: Calendar) -> [Expense] {
        return expenseCalendarViewModel.expenses.filter { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return components.year == year && components.month == month
        }
    }
}

extension YearMonthPickerViewModel {
    func getMainStatCard() -> StatCardData {
        return StatCardData(
            title: "총 지출",
            value: formatAmount(statistics.totalExpense),
            isMain: true
        )
    }
    
    func getMostSpentCategoryCard() -> StatCardData? {
        guard let categoryInfo = statistics.mostSpentCategory else { return nil }
        return StatCardData(
            title: "최다 지출 카테고리",
            value: categoryInfo.category,
            subtitle: formatAmount(categoryInfo.amount)
        )
    }
    
    func getAverageExpenseCard() -> StatCardData {
        return StatCardData(
            title: "3개월 평균",
            value: formatAmount(statistics.averageMonthlyExpense),
            isCompact: true
        )
    }
    
    func getPrevYearCard() -> StatCardData {
        return StatCardData(
            title: "작년 동월",
            value: formatAmount(statistics.prevYearSameMonthExpense),
            isCompact: true
        )
    }
    
    func getChangeRateCard() -> StatCardData? {
        guard statistics.hasPrevYearData else { return nil }
        return StatCardData(
            title: "작년 동월 대비",
            value: statistics.changeRateDisplayText,
            subtitle: statistics.changeRateSubtitle,
            isChange: true,
            isIncrease: statistics.isIncreasing
        )
    }
}
