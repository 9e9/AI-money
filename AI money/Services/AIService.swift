//
//  AIService.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation
import CoreML
import SwiftData

struct ConversationContext {
    var period: Period?
    var category: String?
    var questionType: QuestionType?
}

struct ParsedQuery {
    var period: Period?
    var category: String?
    var questionType: QuestionType?
    var referenceDate: Date?
    var isCompare: Bool
}

enum Period {
    case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth, thisYear, lastYear, custom(Date, Date), specificDay(Date), recentNDays(Int)
}

enum QuestionType: Equatable {
    case totalAmount
    case byCategory
    case count
    case summary
    case topCategory
    case minCategory
    case topDay
    case minDay
    case remainedBudget
    case overspent
    case trend
    case paymentType(String)
    case none
}

final class AIService {
    static let shared = AIService()
    private let classifier: ExpenseClassifier

    private static let appKeywords: Set<String> = [
        "지출", "카테고리", "얼마", "가장", "쇼핑", "교통", "카드", "현금", "예산", "합계", "최대", "최소", "요약", "내역", "많이", "적게", "건수", "횟수", "추세", "통계"
    ]
    private static let meaningless: Set<String> = [
        "?", "네", "그래", "응", "ㅇㅋ", "좋아", "오키", "ok", "okay"
    ]

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd(E)"
        return f
    }()
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월"
        return f
    }()
    private static let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
    private static let specificDateRegex = try! NSRegularExpression(pattern: #"(\d{1,2})월(\d{1,2})일"#)
    private static let monthRegex = try! NSRegularExpression(pattern: #"(\d{1,2})월"#)

    private init() {
        guard let classifier = try? ExpenseClassifier(configuration: MLModelConfiguration()) else {
            fatalError("ExpenseClassifier 모델 로드 실패")
        }
        self.classifier = classifier
    }

    func reply(
        to userInput: String,
        context: ModelContext,
        conversationContext: inout ConversationContext
    ) async -> String {
        if !isRelatedToApp(userInput) {
            return "앱 사용과 관련된 지출/소비/예산 질문을 해주세요!"
        }
        if isNotAValidQuestion(userInput) {
            return "앱 사용과 관련된 지출/소비/예산 질문을 해주세요!"
        }

        let parsed = parseUserInput(
            userInput: userInput,
            context: context,
            previousContext: conversationContext
        )

        if parsed.questionType == .none && parsed.category == nil && parsed.period == nil {
            return "앱 사용과 관련된 지출/소비/예산 질문을 해주세요!"
        }

        if let p = parsed.period { conversationContext.period = p }
        if let c = parsed.category { conversationContext.category = c }
        if let q = parsed.questionType, q != .none { conversationContext.questionType = q }

        return await answer(for: parsed, context: context, conversationContext: conversationContext)
    }

    private func isRelatedToApp(_ input: String) -> Bool {
        let lower = input.lowercased()
        return AIService.appKeywords.contains(where: { lower.contains($0) })
    }

    private func isNotAValidQuestion(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return AIService.meaningless.contains(trimmed)
    }

    private func parseUserInput(
        userInput: String,
        context: ModelContext,
        previousContext: ConversationContext
    ) -> ParsedQuery {
        let lower = userInput.replacingOccurrences(of: " ", with: "").lowercased()
        let now = Date()
        let calendar = Calendar.current

        var period: Period? = nil
        var category: String? = nil
        var questionType: QuestionType? = nil
        var refDate: Date? = nil
        var isCompare = false

        if let date = Self.parseSpecificDate(text: lower) {
            period = .specificDay(date)
            refDate = date
        } else if lower.contains("오늘") {
            period = .today
        } else if lower.contains("어제") || lower.contains("어재") {
            period = .yesterday
        } else if lower.contains("이번주") {
            period = .thisWeek
        } else if lower.contains("지난주") {
            period = .lastWeek
        } else if lower.contains("이번달") || lower.contains("이번월") || lower.contains("이달") || lower.contains("금월") {
            period = .thisMonth
        } else if lower.contains("지난달") || lower.contains("저번달") || lower.contains("전월") || lower.contains("이전달") {
            period = .lastMonth
        } else if let customMonth = Self.parseMonth(text: lower) {
            let start = customMonth
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            period = .custom(start, end)
        } else if lower.contains("최근일주일") || lower.contains("최근7일") {
            period = .recentNDays(7)
        } else if lower.contains("주말") {
            period = .custom(now.previous(.saturday), now.next(.sunday))
        }

        if lower.contains("더썼") || lower.contains("늘었") || lower.contains("증가") || lower.contains("비교") || lower.contains("초과") || lower.contains("아껴졌") || lower.contains("줄었") {
            isCompare = true
        }

        let categories = extractAllCategories(context: context)
        if let found = categories.first(where: { lower.contains($0.replacingOccurrences(of: " ", with: "").lowercased()) }) {
            category = found
        }

        if lower.contains("카드") {
            questionType = .paymentType("카드")
        } else if lower.contains("현금") {
            questionType = .paymentType("현금")
        }

        if lower.contains("가장많이") || lower.contains("제일많이") || lower.contains("최대") {
            if lower.contains("날") || lower.contains("요일") {
                questionType = .topDay
            } else {
                questionType = .topCategory
            }
        } else if lower.contains("가장적게") || lower.contains("제일작은") || lower.contains("가장작은") || lower.contains("최소") {
            if lower.contains("날") || lower.contains("요일") {
                questionType = .minDay
            } else {
                questionType = .minCategory
            }
        } else if lower.contains("횟수") || lower.contains("몇번") || lower.contains("건수") || lower.contains("몇건") {
            questionType = .count
        } else if lower.contains("요약") || lower.contains("내역") {
            questionType = .summary
        } else if lower.contains("남은예산") || lower.contains("남은돈") || lower.contains("얼마남았") || lower.contains("이달에쓸돈") {
            questionType = .remainedBudget
        } else if lower.contains("초과") {
            questionType = .overspent
        } else if lower.contains("추세") {
            questionType = .trend
        } else if lower.contains("총지출") || lower.contains("지출알려줘") || lower.contains("얼마") {
            questionType = .totalAmount
        }

        if period == nil { period = previousContext.period }
        if category == nil { category = previousContext.category }
        if questionType == nil { questionType = previousContext.questionType }
        if questionType == nil { questionType = .none }

        return ParsedQuery(period: period, category: category, questionType: questionType, referenceDate: refDate, isCompare: isCompare)
    }

    private func answer(
        for parsed: ParsedQuery,
        context: ModelContext,
        conversationContext: ConversationContext
    ) async -> String {
        guard let period = parsed.period ?? conversationContext.period else {
            return "질문에서 기간(예: 이번달, 지난달 등)을 명확히 말씀해 주세요."
        }
        let dateRange = dateRange(for: period)
        let expenses = await fetchExpenses(from: dateRange.0, to: dateRange.1, context: context)
        let filtered: [Expense]
        if let cat = parsed.category ?? conversationContext.category {
            filtered = expenses.filter { $0.category == cat }
        } else {
            filtered = expenses
        }

        let questionType = parsed.questionType ?? conversationContext.questionType ?? .totalAmount

        switch questionType {
        case .totalAmount:
            let sum = filtered.reduce(0) { $0 + $1.amount }
            if let cat = parsed.category ?? conversationContext.category {
                return "\(Self.format(period: period)) \(cat) 총 지출은 \(Self.format(amount: sum))원입니다."
            }
            return "\(Self.format(period: period)) 총 지출은 \(Self.format(amount: sum))원입니다."
        case .byCategory, .summary:
            let sums = Dictionary(grouping: filtered, by: { $0.category }).mapValues { $0.reduce(0) { $0 + $1.amount } }
            if sums.isEmpty { return "지출 내역이 없습니다." }
            let sorted = sums.sorted { $0.value > $1.value }
            let lines = sorted.map { "\($0.key): \(Self.format(amount: $0.value))원" }
            return "\(Self.format(period: period)) 소비 요약\n" + lines.joined(separator: "\n")
        case .topCategory:
            let sums = Dictionary(grouping: filtered, by: { $0.category }).mapValues { $0.reduce(0) { $0 + $1.amount } }
            if let top = sums.max(by: { $0.value < $1.value }) {
                return "\(Self.format(period: period)) 가장 많이 쓴 카테고리는 '\(top.key)' (\(Self.format(amount: top.value))원)입니다."
            }
            return "지출 내역이 없습니다."
        case .minCategory:
            let sums = Dictionary(grouping: filtered, by: { $0.category }).mapValues { $0.reduce(0) { $0 + $1.amount } }
            if let min = sums.min(by: { $0.value < $1.value }) {
                return "\(Self.format(period: period)) 가장 적게 쓴 항목은 '\(min.key)' (\(Self.format(amount: min.value))원)입니다."
            }
            return "지출 내역이 없습니다."
        case .topDay:
            let sums = Dictionary(grouping: filtered, by: { Self.dayString($0.date) }).mapValues { $0.reduce(0) { $0 + $1.amount } }
            if let top = sums.max(by: { $0.value < $1.value }) {
                return "\(Self.format(period: period)) 가장 많이 쓴 날은 \(top.key) (\(Self.format(amount: top.value))원)입니다."
            }
            return "지출 내역이 없습니다."
        case .minDay:
            let sums = Dictionary(grouping: filtered, by: { Self.dayString($0.date) }).mapValues { $0.reduce(0) { $0 + $1.amount } }
            if let min = sums.min(by: { $0.value < $1.value }) {
                return "\(Self.format(period: period)) 가장 적게 쓴 날은 \(min.key) (\(Self.format(amount: min.value))원)입니다."
            }
            return "지출 내역이 없습니다."
        case .count:
            let count = filtered.count
            if let cat = parsed.category ?? conversationContext.category {
                return "\(Self.format(period: period)) \(cat) 지출은 총 \(count)회입니다."
            }
            return "\(Self.format(period: period)) 지출 건수는 총 \(count)회입니다."
        case .remainedBudget:
            let budget: Double = 800_000
            let sum = filtered.reduce(0) { $0 + $1.amount }
            let remain = max(0, budget - sum)
            return "\(Self.format(period: period)) 남은 예산은 \(Self.format(amount: remain))원입니다."
        case .overspent:
            let budget: Double = 800_000
            let sum = filtered.reduce(0) { $0 + $1.amount }
            if sum > budget {
                return "\(Self.format(period: period)) 예산을 \(Self.format(amount: sum-budget))원 초과했습니다."
            } else {
                return "\(Self.format(period: period)) 예산을 초과하지 않았습니다."
            }
        case .trend:
            var trendLines: [String] = []
            for i in (0..<6).reversed() {
                let cal = Calendar.current
                let month = cal.date(byAdding: .month, value: -i, to: Date())!
                let start = cal.date(from: cal.dateComponents([.year, .month], from: month))!
                let end = cal.date(byAdding: .month, value: 1, to: start)!
                let expenses = await fetchExpenses(from: start, to: end, context: context)
                let sum = (parsed.category ?? conversationContext.category) == nil
                    ? expenses.reduce(0) { $0 + $1.amount }
                    : expenses.filter { $0.category == (parsed.category ?? conversationContext.category) }
                        .reduce(0) { $0 + $1.amount }
                trendLines.append("\(Self.monthString(start)): \(Self.format(amount: sum))원")
            }
            return "월별 소비 추세\n" + trendLines.joined(separator: "\n")
        case .paymentType(let type):
            let filteredPay = filtered.filter { $0.note.contains(type) }
            let sum = filteredPay.reduce(0) { $0 + $1.amount }
            return "\(Self.format(period: period)) \(type) 사용 금액은 \(Self.format(amount: sum))원입니다."
        case .none:
            return "앱 사용과 관련된 지출/소비/예산 질문을 해주세요!"
        }
    }

    private func dateRange(for period: Period) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .yesterday:
            let today = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -1, to: today)!
            let end = today
            return (start, end)
        case .thisWeek:
            let weekday = calendar.component(.weekday, from: now)
            let start = calendar.date(byAdding: .day, value: -(weekday-1), to: calendar.startOfDay(for: now))!
            let end = calendar.date(byAdding: .day, value: 7-weekday+1, to: start)!
            return (start, end)
        case .lastWeek:
            let weekday = calendar.component(.weekday, from: now)
            let thisWeekStart = calendar.date(byAdding: .day, value: -(weekday-1), to: calendar.startOfDay(for: now))!
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
            let lastWeekEnd = thisWeekStart
            return (lastWeekStart, lastWeekEnd)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .lastMonth:
            let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
            return (lastMonth, thisMonth)
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        case .lastYear:
            let thisYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let lastYear = calendar.date(byAdding: .year, value: -1, to: thisYear)!
            return (lastYear, thisYear)
        case .custom(let start, let end):
            return (start, end)
        case .specificDay(let day):
            let start = Calendar.current.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .recentNDays(let n):
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            let start = calendar.date(byAdding: .day, value: -n+1, to: end)!
            return (start, end)
        }
    }

    private func fetchExpenses(from: Date, to: Date, context: ModelContext) async -> [Expense] {
        let request = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= from && $0.date < to }
        )
        return (try? context.fetch(request)) ?? []
    }

    private func extractAllCategories(context: ModelContext) -> [String] {
        let request = FetchDescriptor<Expense>()
        let expenses = (try? context.fetch(request)) ?? []
        let unique = Set(expenses.map { $0.category })
        return Array(unique)
    }

    private static func dayString(_ date: Date) -> String {
        return dayFormatter.string(from: date)
    }

    private static func monthString(_ date: Date) -> String {
        return monthFormatter.string(from: date)
    }

    private static func format(amount: Double) -> String {
        return amountFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private static func format(period: Period) -> String {
        switch period {
        case .today: return "오늘"
        case .yesterday: return "어제"
        case .thisWeek: return "이번 주"
        case .lastWeek: return "지난주"
        case .thisMonth: return "이번 달"
        case .lastMonth: return "지난달"
        case .thisYear: return "올해"
        case .lastYear: return "작년"
        case .custom(let s, _): return monthString(s)
        case .specificDay(let d): return dayString(d)
        case .recentNDays(let n): return "최근 \(n)일"
        }
    }

    private static func parseSpecificDate(text: String) -> Date? {
        if let match = specificDateRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let monthRange = Range(match.range(at: 1), in: text),
           let dayRange = Range(match.range(at: 2), in: text) {
            let month = Int(text[monthRange])!
            let day = Int(text[dayRange])!
            let calendar = Calendar.current
            let now = Date()
            let year = calendar.component(.year, from: now)
            return calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
        return nil
    }

    private static func parseMonth(text: String) -> Date? {
        if let match = monthRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let monthRange = Range(match.range(at: 1), in: text) {
            let month = Int(text[monthRange])!
            let calendar = Calendar.current
            let now = Date()
            let year = calendar.component(.year, from: now)
            return calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
        return nil
    }
}

extension Date {
    func previous(_ weekday: Weekday) -> Date {
        return get(.previous, weekday)
    }
    func next(_ weekday: Weekday) -> Date {
        return get(.next, weekday)
    }
    private func get(_ direction: SearchDirection, _ weekday: Weekday) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(weekday: weekday.rawValue)
        switch direction {
        case .next:
            return calendar.nextDate(after: self, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)!
        case .previous:
            return calendar.nextDate(after: self.addingTimeInterval(-86400), matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)!
        }
    }
    enum SearchDirection {
        case next
        case previous
    }
    enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
}
