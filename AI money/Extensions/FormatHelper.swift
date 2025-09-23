//
//  FormatHelper.swift
//  AI money
//
//  Created by 조준희 on 9/23/25.
//

import Foundation

struct FormatHelper {
    
    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        return formatter
    }()
    
    private static let calendarDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일 EEEE"
        return formatter
    }()
    
    private static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    
    private static let dayStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd(E)"
        return formatter
    }()
    
    private static let monthStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()
    
    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private static let plainNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    private static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    static func formatSelectedDate(_ date: Date) -> String {
        return selectedDateFormatter.string(from: date)
    }
    
    static func formatCalendarDate(_ date: Date) -> String {
        return calendarDateFormatter.string(from: date)
    }
    
    static func formatYearMonth(_ date: Date) -> String {
        return yearMonthFormatter.string(from: date)
    }
    
    static func formatYearMonth(year: Int, month: Int) -> String {
        return "\(year)년 \(month)월"
    }
    
    static func formatDayString(_ date: Date) -> String {
        return dayStringFormatter.string(from: date)
    }
    
    static func formatMonthString(_ date: Date) -> String {
        return monthStringFormatter.string(from: date)
    }
    
    static func formatAmount(_ amount: Double) -> String {
        guard let formattedString = amountFormatter.string(from: NSNumber(value: amount)) else {
            return "0원"
        }
        return formattedString + "원"
    }
    
    static func formatAmountWithoutCurrency(_ amount: Double) -> String {
        return amountFormatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    static func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        return amountFormatter.string(from: NSNumber(value: number)) ?? numberString
    }
    
    static func formatWithComma(_ number: Double) -> String {
        return amountFormatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    static func formatPlainNumber(_ number: Int) -> String {
        return plainNumberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    static func formatPercentage(_ value: Double) -> String {
        guard let formattedString = percentageFormatter.string(from: NSNumber(value: value)) else {
            return "0.0%"
        }
        return formattedString + "%"
    }
    
    static func formatChangeRate(_ rate: Double) -> String {
        let prefix = rate >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", rate))%"
    }
    
    static func formatChangeRateSubtitle(_ rate: Double) -> String {
        return rate >= 0 ? "증가" : "감소"
    }
    
    static func parseAmountString(_ input: String) -> Double? {
        let filtered = input.replacingOccurrences(of: ",", with: "")
        return Double(filtered)
    }
    
    static func isValidAmount(_ amount: String) -> Bool {
        guard let value = parseAmountString(amount), value > 0 else {
            return false
        }
        return value <= 10_000_000 // 최대 천만원
    }
    
    static func formatCategoryWithAmount(category: String, amount: Double) -> String {
        return "\(category): \(formatAmount(amount))"
    }
    
    static func formatPeriodDisplay(year: Int, month: Int) -> String {
        return "\(year)년 \(String(format: "%02d", month))월"
    }
}

extension Double {
    var formattedAmount: String {
        return FormatHelper.formatAmount(self)
    }
    
    var formattedAmountWithoutCurrency: String {
        return FormatHelper.formatAmountWithoutCurrency(self)
    }
    
    var formattedPercentage: String {
        return FormatHelper.formatPercentage(self)
    }
    
    var formattedChangeRate: String {
        return FormatHelper.formatChangeRate(self)
    }
}

extension Date {
    var formattedSelectedDate: String {
        return FormatHelper.formatSelectedDate(self)
    }
    
    var formattedCalendarDate: String {
        return FormatHelper.formatCalendarDate(self)
    }
    
    var formattedYearMonth: String {
        return FormatHelper.formatYearMonth(self)
    }
    
    var formattedDayString: String {
        return FormatHelper.formatDayString(self)
    }
    
    var formattedMonthString: String {
        return FormatHelper.formatMonthString(self)
    }
}

extension Int {
    var formattedPlainNumber: String {
        return FormatHelper.formatPlainNumber(self)
    }
}
