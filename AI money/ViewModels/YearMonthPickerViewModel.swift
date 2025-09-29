//
//  YearMonthPickerViewModel.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation
import SwiftUI

// 메인 액터에서 실행되는 연/월 선택기의 뷰모델 클래스
// ObservableObject를 준수하여 SwiftUI에서 상태 변화를 관찰할 수 있음
@MainActor
class YearMonthPickerViewModel: ObservableObject {
    // 지출 통계 정보를 저장하는 Published 프로퍼티 (UI 자동 업데이트)
    @Published var statistics = ExpenseStatistics(
        totalExpense: 0,                    // 총 지출액
        mostSpentCategory: nil,             // 최다 지출 카테고리 정보
        averageMonthlyExpense: 0,           // 3개월 평균 지출액
        prevYearSameMonthExpense: 0,        // 작년 동월 지출액
        expenseChangeRate: 0                // 작년 동월 대비 변화율
    )
    
    // 통계 정보 표시 여부를 제어하는 Published 프로퍼티 (애니메이션 효과용)
    @Published var showStats: Bool = false
    
    // 현재 선택된 연도와 월 정보를 담는 Published 프로퍼티
    @Published var selectedPeriod: DatePeriod
    
    // ExpenseCalendarViewModel에 대한 참조 (지출 데이터 접근용)
    private var expenseCalendarViewModel: ExpenseCalendarViewModel
    
    // 최다 지출 카테고리가 존재하는지 확인하는 계산 프로퍼티
    var hasMostSpentCategory: Bool {
        statistics.mostSpentCategory != nil
    }
    
    // 작년 동월 데이터가 존재하는지 확인하는 계산 프로퍼티
    var hasPrevYearData: Bool {
        statistics.hasPrevYearData
    }
    
    // 초기화 메서드 - ExpenseCalendarViewModel 참조와 초기 연/월 설정
    init(expenseCalendarViewModel: ExpenseCalendarViewModel, year: Int, month: Int) {
        self.expenseCalendarViewModel = expenseCalendarViewModel
        self.selectedPeriod = DatePeriod(year: year, month: month)
    }
    
    // 선택된 연도와 월을 업데이트하고 통계를 재계산하는 메서드
    func updatePeriod(year: Int, month: Int) {
        selectedPeriod = DatePeriod(year: year, month: month)
        updateExpenseStatsWithAnimation()
    }
    
    // 애니메이션과 함께 지출 통계를 업데이트하는 메서드
    func updateExpenseStatsWithAnimation() {
        // 기존 통계를 페이드아웃 애니메이션과 함께 숨김
        withAnimation(.easeOut(duration: AnimationConfiguration.fadeOutDuration)) {
            showStats = false
        }
        
        // 페이드아웃 완료 후 새로운 통계 계산 및 페이드인
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConfiguration.fadeOutDuration) {
            self.updateExpenseStats() // 새로운 통계 계산
            
            // 새 통계를 페이드인 애니메이션과 함께 표시
            withAnimation(.easeIn(duration: AnimationConfiguration.fadeInDuration)) {
                self.showStats = true
            }
        }
    }
    
    // 금액을 포맷팅하는 메서드 (FormatHelper 유틸리티 사용)
    func formatAmount(_ amount: Double) -> String {
        return FormatHelper.formatAmount(amount)
    }
    
    // 통계 정보를 초기 상태로 리셋하는 메서드
    func resetStats() {
        statistics = ExpenseStatistics(
            totalExpense: 0,
            mostSpentCategory: nil,
            averageMonthlyExpense: 0,
            prevYearSameMonthExpense: 0,
            expenseChangeRate: 0
        )
        showStats = false // 통계 표시도 숨김
    }
    
    // 선택된 기간의 지출 통계를 계산하는 private 메서드
    private func updateExpenseStats() {
        let calendar = Calendar.current
        
        // 현재 선택된 월의 총 지출액 계산
        let totalExpense = calculateCurrentMonthExpense(calendar: calendar)
        
        // 가장 많이 지출한 카테고리 정보 계산
        let mostSpentCategory = calculateMostSpentCategory(calendar: calendar)
        
        // 최근 3개월 평균 지출액 계산
        let averageMonthlyExpense = calculateAverageMonthlyExpense(calendar: calendar)
        
        // 작년 같은 달 지출액 계산
        let prevYearSameMonthExpense = calculatePrevYearSameMonthExpense(calendar: calendar)
        
        // 작년 동월 대비 변화율 계산 (백분율)
        let expenseChangeRate = calculateExpenseChangeRate(
            current: totalExpense,
            previous: prevYearSameMonthExpense
        )
        
        // 계산된 모든 통계 정보로 statistics 업데이트
        statistics = ExpenseStatistics(
            totalExpense: totalExpense,
            mostSpentCategory: mostSpentCategory,
            averageMonthlyExpense: averageMonthlyExpense,
            prevYearSameMonthExpense: prevYearSameMonthExpense,
            expenseChangeRate: expenseChangeRate
        )
    }
    
    // 현재 선택된 월의 총 지출액을 계산하는 private 메서드
    private func calculateCurrentMonthExpense(calendar: Calendar) -> Double {
        let filteredExpenses = getFilteredExpenses(
            year: selectedPeriod.year,
            month: selectedPeriod.month,
            calendar: calendar
        )
        // 해당 월의 모든 지출을 합산
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 가장 많이 지출한 카테고리와 금액을 계산하는 private 메서드
    private func calculateMostSpentCategory(calendar: Calendar) -> ExpenseCategoryInfo? {
        let filteredExpenses = getFilteredExpenses(
            year: selectedPeriod.year,
            month: selectedPeriod.month,
            calendar: calendar
        )
        // 카테고리별로 지출을 그룹핑
        let categoryGroups = Dictionary(grouping: filteredExpenses, by: { $0.category })
        // 각 카테고리의 총 지출액 계산
        let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } }
        
        // 가장 많이 지출한 카테고리 찾기 (지출이 0보다 클 때만)
        if let (category, amount) = categorySums.max(by: { $0.value < $1.value }), amount > 0 {
            return ExpenseCategoryInfo(category: category, amount: amount)
        }
        return nil // 지출이 없으면 nil 반환
    }
    
    // 최근 3개월 평균 지출액을 계산하는 private 메서드
    private func calculateAverageMonthlyExpense(calendar: Calendar) -> Double {
        var lastThreeMonthsExpense: [Double] = []
        
        // 현재 월부터 이전 3개월까지 반복
        for offset in 0..<3 {
            // offset만큼 이전 월의 날짜 계산
            guard let targetDate = calendar.date(from: DateComponents(year: selectedPeriod.year, month: selectedPeriod.month)),
                  let targetMonth = calendar.date(byAdding: .month, value: -offset, to: targetDate) else {
                continue
            }
            
            // 대상 월의 연도와 월 추출
            let y = calendar.component(.year, from: targetMonth)
            let m = calendar.component(.month, from: targetMonth)
            // 해당 월의 지출 데이터 가져오기
            let expenses = getFilteredExpenses(year: y, month: m, calendar: calendar)
            // 해당 월 총 지출액을 배열에 추가
            lastThreeMonthsExpense.append(expenses.reduce(0) { $0 + $1.amount })
        }
        
        // 3개월 평균 계산 (데이터가 없으면 0 반환)
        return lastThreeMonthsExpense.isEmpty ? 0 :
            lastThreeMonthsExpense.reduce(0, +) / Double(lastThreeMonthsExpense.count)
    }
    
    // 작년 같은 달의 지출액을 계산하는 private 메서드
    private func calculatePrevYearSameMonthExpense(calendar: Calendar) -> Double {
        let prevYearExpenses = getFilteredExpenses(
            year: selectedPeriod.year - 1, // 작년
            month: selectedPeriod.month,   // 같은 월
            calendar: calendar
        )
        // 작년 동월 총 지출액 반환
        return prevYearExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 작년 동월 대비 변화율을 계산하는 private 메서드 (백분율)
    private func calculateExpenseChangeRate(current: Double, previous: Double) -> Double {
        if previous > 0 {
            // 작년 데이터가 있으면 변화율 계산: ((현재 - 이전) / 이전) * 100
            return ((current - previous) / previous) * 100
        } else {
            // 작년 데이터가 없으면: 현재 지출이 있으면 100%, 없으면 0%
            return current > 0 ? 100 : 0
        }
    }
    
    // 특정 연도와 월에 해당하는 지출 데이터를 필터링하는 private 메서드
    private func getFilteredExpenses(year: Int, month: Int, calendar: Calendar) -> [Expense] {
        return expenseCalendarViewModel.expenses.filter { expense in
            // 지출 날짜에서 연도와 월 추출
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            // 지정된 연도와 월에 해당하는 지출만 반환
            return components.year == year && components.month == month
        }
    }
}

// UI에서 사용할 통계 카드 데이터를 제공하는 익스텐션
extension YearMonthPickerViewModel {
    // 메인 통계 카드 (총 지출) 데이터 반환
    func getMainStatCard() -> StatCardData {
        return StatCardData(
            title: "총 지출",
            value: formatAmount(statistics.totalExpense),
            isMain: true // 메인 카드임을 표시
        )
    }
    
    // 최다 지출 카테고리 카드 데이터 반환 (데이터가 있을 때만)
    func getMostSpentCategoryCard() -> StatCardData? {
        guard let categoryInfo = statistics.mostSpentCategory else { return nil }
        return StatCardData(
            title: "최다 지출 카테고리",
            value: categoryInfo.category,      // 카테고리 이름
            subtitle: formatAmount(categoryInfo.amount) // 해당 카테고리 지출액
        )
    }
    
    // 3개월 평균 지출 카드 데이터 반환
    func getAverageExpenseCard() -> StatCardData {
        return StatCardData(
            title: "3개월 평균",
            value: formatAmount(statistics.averageMonthlyExpense),
            isCompact: true // 컴팩트 카드 스타일
        )
    }
    
    // 작년 동월 지출 카드 데이터 반환
    func getPrevYearCard() -> StatCardData {
        return StatCardData(
            title: "작년 동월",
            value: formatAmount(statistics.prevYearSameMonthExpense),
            isCompact: true // 컴팩트 카드 스타일
        )
    }
    
    // 작년 동월 대비 변화율 카드 데이터 반환 (작년 데이터가 있을 때만)
    func getChangeRateCard() -> StatCardData? {
        guard statistics.hasPrevYearData else { return nil }
        return StatCardData(
            title: "작년 동월 대비",
            value: statistics.changeRateDisplayText,    // 변화율 텍스트
            subtitle: statistics.changeRateSubtitle,    // 부제목
            isChange: true,                             // 변화율 카드임을 표시
            isIncrease: statistics.isIncreasing         // 증가/감소 여부
        )
    }
}
