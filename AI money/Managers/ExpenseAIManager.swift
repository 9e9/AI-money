//
//  ExpenseAIManager.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftData
import Foundation
import CoreML
import SwiftUI

class ExpenseAIManager {
    @Query private var expenses: [Expense]
    @Query private var budgetData: [Budget]
    @Query private var budgets: [Budget]

    func prepareTrainingData() -> [(date: String, category: String, amount: Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return expenses
            .sorted { $0.date < $1.date }
            .suffix(30)  // 최근 30일 데이터만 사용
            .map { (formatter.string(from: $0.date), $0.category, $0.amount) }
    }
    // 날짜별 총 소비금액 반환
    func getExpensesByDate() -> [(date: Date, totalAmount: Double)] {
        let grouped = Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }

        return grouped.map { (key, value) in
            let totalAmount = value.reduce(0) { $0 + $1.amount }
            return (date: key, totalAmount: totalAmount)
        }
        .sorted { $0.date < $1.date }
    }
    
    func checkBudgetWarning() -> Bool {
        guard let budget = budgetData.first else { return false }

        // 최근 7일간 소비 금액 평균 계산
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentExpenses = expenses.filter { $0.date >= oneWeekAgo }
        let weeklySpent = recentExpenses.reduce(0) { $0 + $1.amount }
        let dailyAvg = weeklySpent / 7

        // 예산 초과 예상 여부 확인
        let daysLeft = Calendar.current.range(of: .day, in: .month, for: Date())!.count - Calendar.current.component(.day, from: Date())
        let projectedSpending = dailyAvg * Double(daysLeft)
        return (budget.currentSpent + projectedSpending) > budget.budgetLimit
    }
    
    func getCategoryExpenses() -> [ExpenseCategory: Double] {
        var categoryTotals: [ExpenseCategory: Double] = [:]

        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
            
        return categoryTotals
    }
    
    func getCategoryComparison() -> [(category: ExpenseCategory, change: Double)] {
        let calendar = Calendar.current
        let today = Date()
            
        // 이번 달과 지난달의 시작 날짜 구하기
        let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
            
        // 카테고리별 소비 금액 계산
        var lastMonthExpenses: [ExpenseCategory: Double] = [:]
        var thisMonthExpenses: [ExpenseCategory: Double] = [:]

        for expense in expenses {
            if expense.date >= startOfThisMonth {
                thisMonthExpenses[expense.category, default: 0] += expense.amount
            } else if expense.date >= startOfLastMonth {
                lastMonthExpenses[expense.category, default: 0] += expense.amount
            }
        }

        // 변화율 계산
        var categoryChanges: [(ExpenseCategory, Double)] = []
        for category in ExpenseCategory.allCases {
            let lastMonth = lastMonthExpenses[category] ?? 0
            let thisMonth = thisMonthExpenses[category] ?? 0
            let change = lastMonth == 0 ? 100 : ((thisMonth - lastMonth) / lastMonth) * 100
            categoryChanges.append((category, change))
        }

        return categoryChanges
    }
    
    func checkBudgetAlerts() -> [String] {
        var alerts: [String] = []
        var categoryTotals: [ExpenseCategory: Double] = [:]

        // 현재 소비 총액 계산
        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }

        // 예산 초과 확인
        for budget in budgets {
            if let spent = categoryTotals[budget.category], spent > budget.limit {
                alerts.append("🚨 \(budget.category.rawValue) 예산을 초과했어요! (\(Int(spent))/\(Int(budget.limit)) 원)")
            }
        }

        return alerts
    }
}
