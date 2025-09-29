//
//  FormatHelper.swift
//  AI money
//
//  Created by 조준희 on 9/23/25.
//

import Foundation

// MARK: - 앱 전체에서 사용되는 포맷팅 유틸리티 구조체
struct FormatHelper {
    
    // 선택된 날짜를 "2025년 01월 15일 수요일" 형태로 포맷하는 DateFormatter
    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter() // DateFormatter 인스턴스 생성
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 로케일 설정
        formatter.dateFormat = "yyyy년 MM월 dd일 EEEE" // 연도, 월, 일, 요일 포맷 지정
        return formatter // 설정된 포맷터 반환
    }()
    
    // 캘린더에서 사용할 "01월 15일 수요일" 형태의 DateFormatter
    private static let calendarDateFormatter: DateFormatter = {
        let formatter = DateFormatter() // DateFormatter 인스턴스 생성
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 로케일 설정
        formatter.dateFormat = "MM월 dd일 EEEE" // 월, 일, 요일 포맷 지정 (연도 제외)
        return formatter // 설정된 포맷터 반환
    }()
    
    // 연월을 "2025년 1월" 형태로 포맷하는 DateFormatter
    private static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter() // DateFormatter 인스턴스 생성
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 로케일 설정
        formatter.dateFormat = "yyyy년 M월" // 연도와 월 포맷 지정 (M은 앞자리 0 제거)
        return formatter // 설정된 포맷터 반환
    }()
    
    // 일자를 "2025-01-15(수)" 형태로 포맷하는 DateFormatter
    private static let dayStringFormatter: DateFormatter = {
        let formatter = DateFormatter() // DateFormatter 인스턴스 생성
        formatter.dateFormat = "yyyy-MM-dd(E)" // ISO 날짜 형식에 요일 축약형 추가
        return formatter // 설정된 포맷터 반환
    }()
    
    // 월을 "2025년 1월" 형태로 포맷하는 DateFormatter (yearMonthFormatter와 동일)
    private static let monthStringFormatter: DateFormatter = {
        let formatter = DateFormatter() // DateFormatter 인스턴스 생성
        formatter.dateFormat = "yyyy년 M월" // 연도와 월 포맷 지정
        return formatter // 설정된 포맷터 반환
    }()
    
    // 채팅 시간을 "14:30" 형태로 포맷하는 DateFormatter
    private static let chatTimeFormatter: DateFormatter = {
        let formatter = DateFormatter() // DateFormatter 인스턴스 생성
        formatter.dateFormat = "HH:mm" // 24시간 형식의 시:분 포맷
        return formatter // 설정된 포맷터 반환
    }()
    
    // 금액을 천 단위 콤마로 포맷하는 NumberFormatter
    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter() // NumberFormatter 인스턴스 생성
        formatter.numberStyle = .decimal // 십진수 스타일 (천 단위 구분자 포함)
        formatter.maximumFractionDigits = 0 // 소수점 이하 자릿수 0으로 설정 (정수만 표현)
        return formatter // 설정된 포맷터 반환
    }()
    
    // 숫자를 포맷 없이 그대로 문자열로 변환하는 NumberFormatter
    private static let plainNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter() // NumberFormatter 인스턴스 생성
        formatter.numberStyle = .none // 아무 스타일 적용 안함 (순수 숫자)
        return formatter // 설정된 포맷터 반환
    }()
    
    // 퍼센트를 소수점 1자리까지 포맷하는 NumberFormatter
    private static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter() // NumberFormatter 인스턴스 생성
        formatter.numberStyle = .decimal // 십진수 스타일
        formatter.minimumFractionDigits = 1 // 최소 소수점 이하 1자리
        formatter.maximumFractionDigits = 1 // 최대 소수점 이하 1자리
        return formatter // 설정된 포맷터 반환
    }()
    
    // 선택된 날짜를 한국어 형태로 포맷하여 반환
    static func formatSelectedDate(_ date: Date) -> String {
        return selectedDateFormatter.string(from: date) // selectedDateFormatter를 사용해 날짜 포맷
    }
    
    // 캘린더 날짜를 한국어 형태로 포맷하여 반환
    static func formatCalendarDate(_ date: Date) -> String {
        return calendarDateFormatter.string(from: date) // calendarDateFormatter를 사용해 날짜 포맷
    }
    
    // 연월을 한국어 형태로 포맷하여 반환
    static func formatYearMonth(_ date: Date) -> String {
        return yearMonthFormatter.string(from: date) // yearMonthFormatter를 사용해 연월 포맷
    }
    
    // 연도와 월 정수값을 받아 한국어 형태로 포맷하여 반환
    static func formatYearMonth(year: Int, month: Int) -> String {
        return "\(year)년 \(month)월" // 문자열 보간을 사용해 직접 포맷
    }
    
    // 날짜를 일자 문자열 형태로 포맷하여 반환
    static func formatDayString(_ date: Date) -> String {
        return dayStringFormatter.string(from: date) // dayStringFormatter를 사용해 일자 포맷
    }
    
    // 날짜를 월 문자열 형태로 포맷하여 반환
    static func formatMonthString(_ date: Date) -> String {
        return monthStringFormatter.string(from: date) // monthStringFormatter를 사용해 월 포맷
    }
    
    // 날짜를 채팅 시간 형태로 포맷하여 반환
    static func formatChatTime(_ date: Date) -> String {
        return chatTimeFormatter.string(from: date) // chatTimeFormatter를 사용해 시간 포맷
    }
    
    // 금액을 원화 형태("12,000원")로 포맷하여 반환
    static func formatAmount(_ amount: Double) -> String {
        guard let formattedString = amountFormatter.string(from: NSNumber(value: amount)) else {
            return "0원" // 포맷 실패 시 기본값 반환
        }
        return formattedString + "원" // 포맷된 숫자에 "원" 단위 추가
    }
    
    // 금액을 통화 단위 없이 천 단위 콤마만 포함하여 반환
    static func formatAmountWithoutCurrency(_ amount: Double) -> String {
        return amountFormatter.string(from: NSNumber(value: amount)) ?? "0" // 포맷 실패 시 "0" 반환
    }
    
    // 문자열 숫자를 천 단위 콤마로 포맷하여 반환
    static func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString } // 숫자 변환 실패 시 원본 반환
        return amountFormatter.string(from: NSNumber(value: number)) ?? numberString // 포맷 실패 시 원본 반환
    }
    
    // Double 타입 숫자를 천 단위 콤마로 포맷하여 반환
    static func formatWithComma(_ number: Double) -> String {
        return amountFormatter.string(from: NSNumber(value: number)) ?? "0" // 포맷 실패 시 "0" 반환
    }
    
    // 정수를 포맷 없이 문자열로 변환하여 반환
    static func formatPlainNumber(_ number: Int) -> String {
        return plainNumberFormatter.string(from: NSNumber(value: number)) ?? "\(number)" // 포맷 실패 시 기본 문자열 변환
    }
    
    // 퍼센트 값을 "12.5%" 형태로 포맷하여 반환
    static func formatPercentage(_ value: Double) -> String {
        guard let formattedString = percentageFormatter.string(from: NSNumber(value: value)) else {
            return "0.0%" // 포맷 실패 시 기본값 반환
        }
        return formattedString + "%" // 포맷된 숫자에 "%" 기호 추가
    }
    
    // 변화율을 "+12.5%" 또는 "-5.2%" 형태로 포맷하여 반환
    static func formatChangeRate(_ rate: Double) -> String {
        let prefix = rate >= 0 ? "+" : "" // 양수일 때만 "+" 기호 추가 (음수는 자동으로 "-" 포함)
        return "\(prefix)\(String(format: "%.1f", rate))%" // 소수점 1자리까지 포맷하여 "%" 추가
    }
    
    // 변화율에 따른 설명 텍스트 반환
    static func formatChangeRateSubtitle(_ rate: Double) -> String {
        return rate >= 0 ? "증가" : "감소" // 양수면 "증가", 음수면 "감소" 반환
    }
    
    // 금액 문자열에서 콤마를 제거하고 Double 타입으로 변환
    static func parseAmountString(_ input: String) -> Double? {
        let filtered = input.replacingOccurrences(of: ",", with: "") // 콤마 제거
        return Double(filtered) // Double로 변환 (실패 시 nil 반환)
    }
    
    // 금액 문자열이 유효한지 검증 (0보다 크고 1조 이하)
    static func isValidAmount(_ amount: String) -> Bool {
        guard let value = parseAmountString(amount), value > 0 else {
            return false // 파싱 실패 또는 0 이하인 경우 false
        }
        return value <= 1_000_000_000_000 // 1조 이하인지 확인
    }
    
    // 카테고리와 금액을 "식비: 50,000원" 형태로 포맷하여 반환
    static func formatCategoryWithAmount(category: String, amount: Double) -> String {
        return "\(category): \(formatAmount(amount))" // 카테고리와 포맷된 금액을 조합
    }
    
    // 연도와 월을 "2025년 01월" 형태로 포맷하여 반환
    static func formatPeriodDisplay(year: Int, month: Int) -> String {
        return "\(year)년 \(String(format: "%02d", month))월" // 월은 2자리 숫자로 포맷 (01, 02, ...)
    }
}

// MARK: - Double 타입 확장: 금액 및 퍼센트 포맷팅 편의 프로퍼티
extension Double {
    // Double 값을 원화 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedAmount: String {
        return FormatHelper.formatAmount(self) // FormatHelper의 formatAmount 메서드 활용
    }
    
    // Double 값을 통화 단위 없이 천 단위 콤마만 포함하여 반환하는 계산 프로퍼티
    var formattedAmountWithoutCurrency: String {
        return FormatHelper.formatAmountWithoutCurrency(self) // FormatHelper의 formatAmountWithoutCurrency 메서드 활용
    }
    
    // Double 값을 퍼센트 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedPercentage: String {
        return FormatHelper.formatPercentage(self) // FormatHelper의 formatPercentage 메서드 활용
    }
    
    // Double 값을 변화율 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedChangeRate: String {
        return FormatHelper.formatChangeRate(self) // FormatHelper의 formatChangeRate 메서드 활용
    }
}

// MARK: - Date 타입 확장: 날짜 포맷팅 편의 프로퍼티
extension Date {
    // Date를 선택된 날짜 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedSelectedDate: String {
        return FormatHelper.formatSelectedDate(self) // FormatHelper의 formatSelectedDate 메서드 활용
    }
    
    // Date를 캘린더 날짜 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedCalendarDate: String {
        return FormatHelper.formatCalendarDate(self) // FormatHelper의 formatCalendarDate 메서드 활용
    }
    
    // Date를 연월 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedYearMonth: String {
        return FormatHelper.formatYearMonth(self) // FormatHelper의 formatYearMonth 메서드 활용
    }
    
    // Date를 일자 문자열 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedDayString: String {
        return FormatHelper.formatDayString(self) // FormatHelper의 formatDayString 메서드 활용
    }
    
    // Date를 월 문자열 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedMonthString: String {
        return FormatHelper.formatMonthString(self) // FormatHelper의 formatMonthString 메서드 활용
    }
    
    // Date를 채팅 시간 형태로 포맷하여 반환하는 계산 프로퍼티
    var formattedChatTime: String {
        return FormatHelper.formatChatTime(self) // FormatHelper의 formatChatTime 메서드 활용
    }
}

// MARK: - Int 타입 확장: 숫자 포맷팅 편의 프로퍼티
extension Int {
    // Int 값을 포맷 없이 문자열로 변환하여 반환하는 계산 프로퍼티
    var formattedPlainNumber: String {
        return FormatHelper.formatPlainNumber(self) // FormatHelper의 formatPlainNumber 메서드 활용
    }
}
