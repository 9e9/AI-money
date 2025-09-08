//
//  YearMonthPickerModels.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation

struct ExpenseStatistics {
    let totalExpense: Double
    let mostSpentCategory: ExpenseCategoryInfo?
    let averageMonthlyExpense: Double
    let prevYearSameMonthExpense: Double
    let expenseChangeRate: Double
    
    var hasPrevYearData: Bool {
        prevYearSameMonthExpense > 0
    }
    
    var changeRateDisplayText: String {
        return "\(expenseChangeRate >= 0 ? "+" : "")\(String(format: "%.1f", expenseChangeRate))%"
    }
    
    var changeRateSubtitle: String {
        return expenseChangeRate >= 0 ? "증가" : "감소"
    }
    
    var isIncreasing: Bool {
        return expenseChangeRate >= 0
    }
}

struct ExpenseCategoryInfo {
    let category: String
    let amount: Double
    
    var isEmpty: Bool {
        category.isEmpty
    }
}

struct StatCardData {
    let title: String
    let value: String
    let subtitle: String?
    let isMain: Bool
    let isCompact: Bool
    let isChange: Bool
    let isIncrease: Bool
    
    init(title: String,
         value: String,
         subtitle: String? = nil,
         isMain: Bool = false,
         isCompact: Bool = false,
         isChange: Bool = false,
         isIncrease: Bool = false) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isMain = isMain
        self.isCompact = isCompact
        self.isChange = isChange
        self.isIncrease = isIncrease
    }
}

struct DatePeriod {
    let year: Int
    let month: Int
    
    var displayText: String {
        return "\(year)년 \(month)월"
    }
    
    var isValid: Bool {
        return year >= 2000 && year <= 2100 && month >= 1 && month <= 12
    }
}

struct PickerConfiguration {
    static let availableYears = Array(2000...2100)
    static let months = Array(1...12)
    static let monthNames = ["1월", "2월", "3월", "4월", "5월", "6월",
                            "7월", "8월", "9월", "10월", "11월", "12월"]
}

struct AnimationConfiguration {
    static let fadeOutDuration: Double = 0.15
    static let fadeInDuration: Double = 0.25
    static let scaleEffectDuration: Double = 0.3
    static let minScale: Double = 0.95
    static let maxScale: Double = 1.0
}
