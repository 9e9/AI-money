//
//  ExpenseCalendarModels.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation

// 캘린더 관련 상수 설정을 담은 구조체
struct CalendarConfiguration {
    static let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"] // 한국어 요일 표시 배열
    static let calendarGridRows = 6 // 캘린더 그리드의 행 수 (6주)
    static let daysPerWeek = 7 // 일주일의 일수
    static let totalCalendarDays = calendarGridRows * daysPerWeek // 캘린더에 표시할 총 날짜 수 (42일)
}

// 캘린더의 하루를 나타내는 구조체
struct CalendarDay {
    let date: Date // 해당 날짜
    let isInCurrentMonth: Bool // 현재 월에 속하는 날인지 여부
    let dayNumber: Int // 날짜 숫자 (1~31)
    let totalExpense: Double // 해당 날짜의 총 지출 금액
    let holiday: KoreanHoliday? // 공휴일 정보 (있는 경우)
    
    // 해당 날짜에 지출이 있는지 확인하는 계산 프로퍼티
    var hasExpense: Bool {
        totalExpense > 0 // 총 지출이 0보다 크면 true
    }
    
    // 해당 날짜가 공휴일인지 확인하는 계산 프로퍼티
    var isHoliday: Bool {
        holiday != nil // 공휴일 정보가 있으면 true
    }
    
    // 국경일인지 확인하는 계산 프로퍼티
    var isNationalHoliday: Bool {
        holiday?.type == .national || holiday?.type == .traditional // 국경일 또는 전통명절이면 true
    }
    
    // 공휴일 표시 색상을 결정하는 계산 프로퍼티
    var holidayColor: HolidayDisplayColor {
        guard let holiday = holiday else { return .none } // 공휴일이 아니면 기본색
        
        // 공휴일 타입에 따라 다른 색상 반환
        switch holiday.type {
        case .national, .traditional: // 국경일, 전통명절
            return .red
        case .memorial: // 기념일
            return .orange
        case .substitute: // 대체공휴일
            return .blue
        }
    }
    
    // 지출 금액을 포맷된 문자열로 반환하는 계산 프로퍼티
    var formattedExpense: String {
        if totalExpense <= 0 { return "" } // 지출이 없으면 빈 문자열
        let formatter = NumberFormatter() // 숫자 포맷터 생성
        formatter.numberStyle = .decimal // 천 단위 콤마 스타일 설정
        formatter.maximumFractionDigits = 0 // 소수점 이하 표시 안함
        return (formatter.string(from: NSNumber(value: totalExpense)) ?? "0") + "원" // 포맷된 금액 + "원" 반환
    }
}

// 공휴일 표시 색상을 나타내는 열거형
enum HolidayDisplayColor {
    case none     // 일반일
    case red      // 국경일, 전통명절
    case orange   // 기념일
    case blue     // 대체공휴일
    
    // 색상을 문자열로 반환하는 계산 프로퍼티
    var color: String {
        switch self {
        case .none: return "primary"   // 기본 색상
        case .red: return "red"        // 빨간색
        case .orange: return "orange"  // 주황색
        case .blue: return "blue"      // 파란색
        }
    }
}

// 특정 날짜의 지출 요약 정보를 담는 구조체
struct DailyExpenseSummary {
    let date: Date // 날짜
    let expenses: [Expense] // 해당 날짜의 지출 목록
    let totalAmount: Double // 총 지출 금액
    let holiday: KoreanHoliday? // 공휴일 정보
    
    // 지출이 없는지 확인하는 계산 프로퍼티
    var isEmpty: Bool {
        expenses.isEmpty // 지출 배열이 비어있으면 true
    }
    
    // 공휴일인지 확인하는 계산 프로퍼티
    var isHoliday: Bool {
        holiday != nil // 공휴일 정보가 있으면 true
    }
    
    // 카테고리별 지출 금액을 딕셔너리로 반환하는 계산 프로퍼티
    var categoryBreakdown: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category }) // 카테고리별로 지출을 그룹화
            .mapValues { $0.reduce(0) { $0 + $1.amount } } // 각 그룹의 총 금액 계산
    }
    
    // 가장 많이 지출한 카테고리를 반환하는 계산 프로퍼티
    var mostExpensiveCategory: String? {
        categoryBreakdown.max(by: { $0.value < $1.value })?.key // 가장 큰 값을 가진 카테고리의 키 반환
    }
    
    // 초기화 메서드
    init(date: Date, expenses: [Expense], holiday: KoreanHoliday? = nil) {
        self.date = date // 날짜 설정
        self.expenses = expenses // 지출 목록 설정
        self.totalAmount = expenses.reduce(0) { $0 + $1.amount } // 모든 지출의 합계 계산
        self.holiday = holiday // 공휴일 정보 설정
    }
}

// 지출 카드에 표시할 데이터를 담는 구조체
struct ExpenseCardData {
    let expense: Expense // 원본 지출 데이터
    let formattedAmount: String // 포맷된 금액 문자열
    let hasNote: Bool // 메모가 있는지 여부
    
    // 지출 객체를 받아 초기화하는 메서드
    init(expense: Expense) {
        self.expense = expense // 원본 지출 데이터 저장
        let formatter = NumberFormatter() // 숫자 포맷터 생성
        formatter.numberStyle = .decimal // 천 단위 콤마 스타일
        formatter.maximumFractionDigits = 0 // 소수점 표시 안함
        self.formattedAmount = (formatter.string(from: NSNumber(value: expense.amount)) ?? "0") + "원" // 포맷된 금액
        self.hasNote = !expense.note.isEmpty // 메모가 비어있지 않으면 true
    }
}

// 캘린더의 현재 상태를 나타내는 열거형
enum CalendarState {
    case noDateSelected // 날짜가 선택되지 않은 상태
    case dateSelectedWithExpenses(DailyExpenseSummary) // 지출이 있는 날짜가 선택된 상태
    case dateSelectedWithoutExpenses(Date, KoreanHoliday?) // 지출이 없는 날짜가 선택된 상태 (공휴일 정보 포함)
    
    // 선택된 날짜를 반환하는 계산 프로퍼티
    var selectedDate: Date? {
        switch self {
        case .noDateSelected:
            return nil // 선택된 날짜 없음
        case .dateSelectedWithExpenses(let summary):
            return summary.date // 지출 요약에서 날짜 반환
        case .dateSelectedWithoutExpenses(let date, _):
            return date // 직접 저장된 날짜 반환
        }
    }
    
    // 선택된 날짜의 공휴일 정보를 반환하는 계산 프로퍼티
    var selectedHoliday: KoreanHoliday? {
        switch self {
        case .noDateSelected:
            return nil // 선택된 날짜 없음
        case .dateSelectedWithExpenses(let summary):
            return summary.holiday // 지출 요약에서 공휴일 정보 반환
        case .dateSelectedWithoutExpenses(_, let holiday):
            return holiday // 직접 저장된 공휴일 정보 반환
        }
    }
    
    // 선택된 날짜에 지출이 있는지 확인하는 계산 프로퍼티
    var hasExpenses: Bool {
        switch self {
        case .dateSelectedWithExpenses:
            return true // 지출이 있는 날짜가 선택된 경우
        default:
            return false // 그 외의 경우
        }
    }
}

// 캘린더 애니메이션 관련 설정을 담은 구조체
struct CalendarAnimationConfiguration {
    static let monthTransitionDuration: Double = 0.3 // 월 전환 애니메이션 지속 시간
    static let selectionAnimationDuration: Double = 0.2 // 날짜 선택 애니메이션 지속 시간
    static let expenseListAnimationDuration: Double = 0.25 // 지출 목록 애니메이션 지속 시간
}
