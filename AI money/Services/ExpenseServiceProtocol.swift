//
//  ExpenseServiceProtocol.swift
//  AI money
//
//  Created by 조준희 on 9/22/25.
//

import Foundation

// MARK: - 지출 관리 기본 프로토콜
/// 지출 데이터의 기본적인 CRUD 작업과 카테고리 관리를 담당하는 프로토콜
/// @MainActor로 메인 스레드에서만 실행되도록 보장 (UI 업데이트 안전성)
@MainActor
protocol ExpenseServiceProtocol: AnyObject {
    // MARK: - 데이터 프로퍼티들
    /// 현재 저장된 모든 지출 데이터 배열
    var expenses: [Expense] { get }
    
    /// 사용자가 직접 추가한 커스텀 카테고리 목록
    var customCategories: [String] { get }
    
    // MARK: - 지출 데이터 관리 메서드들
    /// 새로운 지출 내역을 추가하는 메서드
    /// - Parameter expense: 추가할 지출 객체
    func addExpense(_ expense: Expense)
    
    /// 특정 지출 내역을 삭제하는 메서드
    /// - Parameter expense: 삭제할 지출 객체
    func removeExpense(_ expense: Expense)
    
    /// 특정 카테고리의 모든 지출 내역을 일괄 삭제하는 메서드
    /// - Parameter category: 삭제할 카테고리명
    func removeExpenses(for category: String)
    
    // MARK: - 카테고리 관리 메서드들
    /// 새로운 커스텀 카테고리를 추가하는 메서드
    /// - Parameter category: 추가할 카테고리명
    func addCustomCategory(_ category: String)
    
    /// 기존 커스텀 카테고리를 삭제하는 메서드
    /// - Parameter category: 삭제할 카테고리명
    func removeCustomCategory(_ category: String)
    
    // MARK: - 계산 및 유틸리티 메서드들
    /// 특정 날짜의 총 지출 금액을 계산하는 메서드
    /// - Parameter date: 계산할 날짜
    /// - Returns: 해당 날짜의 총 지출 금액
    func totalExpense(for date: Date) -> Double
    
    /// 금액을 사용자에게 보여줄 형태로 포맷하는 메서드 (천 단위 콤마, 원화 표시)
    /// - Parameter amount: 포맷할 금액
    /// - Returns: 포맷된 금액 문자열 (예: "12,345원")
    func formatAmount(_ amount: Double) -> String
}

// MARK: - 캘린더 기능이 포함된 지출 관리 프로토콜
/// ExpenseServiceProtocol을 상속받아 캘린더 뷰 관련 기능을 추가한 프로토콜
/// 달력 표시, 날짜 선택, 월별 네비게이션 등의 기능을 제공
@MainActor
protocol ExpenseCalendarServiceProtocol: ExpenseServiceProtocol {
    // MARK: - 캘린더 상태 관리 프로퍼티들
    /// 현재 캘린더의 상태 (날짜 선택 여부, 선택된 날짜의 지출 데이터 등)
    var calendarState: CalendarState { get }
    
    /// 현재 캘린더에서 표시 중인 년도
    var selectedYear: Int { get set }
    
    /// 현재 캘린더에서 표시 중인 월
    var selectedMonth: Int { get set }
    
    /// 현재 선택된 월의 모든 지출 데이터
    var currentMonthExpenses: [Expense] { get }
    
    /// 현재 선택된 월의 총 지출 금액
    var monthlyTotal: Double { get }
    
    /// 캘린더 그리드에 표시할 날짜 데이터 배열 (42개 - 6주 x 7일)
    var calendarDays: [CalendarDay] { get }
    
    // MARK: - 캘린더 인터랙션 메서드들
    /// 특정 날짜를 선택하거나 선택 해제하는 메서드
    /// - Parameter date: 선택할 날짜 (nil이면 선택 해제)
    func selectDate(_ date: Date?)
    
    /// 이전 달로 이동하는 메서드 (년도 경계도 자동 처리)
    func moveToPreviousMonth()
    
    /// 다음 달로 이동하는 메서드 (년도 경계도 자동 처리)
    func moveToNextMonth()
    
    /// 현재 날짜(오늘)가 포함된 달로 캘린더를 리셋하는 메서드
    func resetToCurrentDate()
    
    /// 특정 년도와 월로 캘린더를 직접 설정하는 메서드
    /// - Parameters:
    ///   - year: 이동할 년도
    ///   - month: 이동할 월
    func updateSelectedPeriod(year: Int, month: Int)
}
