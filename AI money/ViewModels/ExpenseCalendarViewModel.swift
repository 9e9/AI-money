//
//  ExpenseCalendarViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation
import SwiftData    // 데이터 저장 및 관리를 위한 SwiftData 프레임워크
import SwiftUI

// 메인 액터에서 실행되는 가계부 캘린더 뷰모델 클래스
// ObservableObject: SwiftUI와 연동하여 데이터 변경 시 자동으로 UI 업데이트
// ExpenseCalendarServiceProtocol: 캘린더 서비스 프로토콜을 준수하여 인터페이스 통일
@MainActor
class ExpenseCalendarViewModel: ObservableObject, ExpenseCalendarServiceProtocol {
    // 싱글톤 패턴으로 전역에서 하나의 인스턴스만 사용
    static let shared = ExpenseCalendarViewModel()

    // @Published: 값이 변경될 때마다 UI에 자동으로 알림을 보내는 속성 래퍼
    // private(set): 외부에서는 읽기만 가능하고 수정은 불가능
    @Published private(set) var expenses: [Expense] = []              // 모든 지출 내역을 저장하는 배열
    @Published var customCategories: [String] = []                    // 사용자가 추가한 커스텀 카테고리 목록
    @Published var calendarState: CalendarState = .noDateSelected     // 현재 캘린더 상태 (날짜 선택 여부 등)
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())    // 현재 선택된 연도
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())  // 현재 선택된 월

    // SwiftData의 ModelContext - 데이터베이스 작업을 위한 컨텍스트
    private var modelContext: ModelContext?
    // Calendar 인스턴스 - 날짜 관련 계산을 위해 사용
    private let calendar = Calendar.current
    // 한국 공휴일 서비스 - 공휴일 확인을 위한 서비스 (새로 추가된 기능)
    private let holidayService = KoreanHolidayService.shared

    // 현재 선택된 월의 지출 내역들만 필터링하여 반환하는 computed property
    var currentMonthExpenses: [Expense] {
        expenses.filter { expense in
            // 각 지출의 날짜에서 연도와 월을 추출
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            // 현재 선택된 연도/월과 일치하는지 확인
            return components.year == selectedYear && components.month == selectedMonth
        }
    }
    
    // 현재 월의 총 지출 금액을 계산하여 반환
    var monthlyTotal: Double {
        // reduce를 사용하여 모든 지출 금액을 합산 (초기값 0에서 시작)
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 캘린더 UI에 표시할 날짜 데이터들을 생성하여 반환
    var calendarDays: [CalendarDay] {
        generateCalendarDays()
    }

    // 초기화 메서드 - 옵셔널 파라미터로 ModelContext를 받음
    init(context: ModelContext? = nil) {
        self.modelContext = context
        loadExpenses()          // 저장된 지출 데이터 로드
        loadCustomCategories()  // 저장된 커스텀 카테고리 로드
        initializeCurrentDate() // 현재 날짜로 초기 설정
    }

    // ModelContext를 설정하고 지출 데이터를 다시 로드하는 메서드
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        loadExpenses()
    }
    
    // 특정 날짜를 선택했을 때의 처리 로직
    func selectDate(_ date: Date?) {
        // 날짜가 nil인 경우 선택 해제 상태로 설정
        guard let date = date else {
            calendarState = .noDateSelected
            return
        }
        
        // 선택한 날짜와 같은 날의 지출 내역들을 필터링
        let dailyExpenses = expenses.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
        
        // 해당 날짜가 공휴일인지 확인
        let holiday = holidayService.isHoliday(date: date)
        
        // 지출 내역이 없는 경우와 있는 경우를 구분하여 상태 설정
        if dailyExpenses.isEmpty {
            calendarState = .dateSelectedWithoutExpenses(date, holiday)
        } else {
            // 일일 지출 요약 객체를 생성하여 상태에 저장
            let summary = DailyExpenseSummary(date: date, expenses: dailyExpenses, holiday: holiday)
            calendarState = .dateSelectedWithExpenses(summary)
        }
    }
    
    // 이전 달로 이동하는 메서드
    func moveToPreviousMonth() {
        if selectedMonth == 1 {  // 1월인 경우
            selectedMonth = 12   // 12월로 변경
            selectedYear -= 1    // 년도를 1 감소
        } else {
            selectedMonth -= 1   // 월을 1 감소
        }
        calendarState = .noDateSelected  // 날짜 선택 해제
    }
    
    // 다음 달로 이동하는 메서드
    func moveToNextMonth() {
        if selectedMonth == 12 { // 12월인 경우
            selectedMonth = 1    // 1월로 변경
            selectedYear += 1    // 년도를 1 증가
        } else {
            selectedMonth += 1   // 월을 1 증가
        }
        calendarState = .noDateSelected  // 날짜 선택 해제
    }
    
    // 현재 날짜로 리셋하는 메서드
    func resetToCurrentDate() {
        let currentDate = Date()
        // 현재 날짜에서 연도와 월을 추출
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        selectedYear = components.year ?? selectedYear      // nil인 경우 기존 값 유지
        selectedMonth = components.month ?? selectedMonth   // nil인 경우 기존 값 유지
        selectDate(currentDate)  // 현재 날짜를 선택 상태로 설정
    }
    
    // 선택된 연도와 월을 업데이트하는 메서드
    func updateSelectedPeriod(year: Int, month: Int) {
        selectedYear = year
        selectedMonth = month
        calendarState = .noDateSelected  // 날짜 선택 해제
    }

    // 새로운 지출을 추가하는 메서드
    func addExpense(_ expense: Expense) {
        guard let context = modelContext else { return }  // ModelContext가 없으면 종료
        context.insert(expense)  // 데이터베이스에 지출 데이터 삽입
        saveContext()           // 변경사항을 데이터베이스에 저장
        loadExpenses()          // 지출 목록을 다시 로드하여 UI 업데이트
        
        // 현재 선택된 날짜와 같은 날에 추가된 지출인 경우 해당 날짜를 다시 선택하여 업데이트
        if let selectedDate = calendarState.selectedDate,
           calendar.isDate(expense.date, inSameDayAs: selectedDate) {
            selectDate(selectedDate)
        }
    }

    // 지출을 삭제하는 메서드
    func removeExpense(_ expense: Expense) {
        guard let context = modelContext else { return }  // ModelContext가 없으면 종료
        context.delete(expense)  // 데이터베이스에서 지출 데이터 삭제
        saveContext()           // 변경사항을 데이터베이스에 저장
        loadExpenses()          // 지출 목록을 다시 로드하여 UI 업데이트
        
        // 현재 선택된 날짜와 같은 날의 지출이 삭제된 경우 해당 날짜를 다시 선택하여 업데이트
        if let selectedDate = calendarState.selectedDate,
           calendar.isDate(expense.date, inSameDayAs: selectedDate) {
            selectDate(selectedDate)
        }
    }

    // 특정 카테고리의 모든 지출을 삭제하는 메서드
    func removeExpenses(for category: String) {
        guard let context = modelContext else { return }  // ModelContext가 없으면 종료
        // 해당 카테고리의 모든 지출을 찾아서 삭제
        for expense in expenses where expense.category == category {
            context.delete(expense)
        }
        saveContext()   // 변경사항을 데이터베이스에 저장
        loadExpenses()  // 지출 목록을 다시 로드하여 UI 업데이트
        
        // 현재 선택된 날짜가 있다면 다시 선택하여 업데이트 (삭제된 내역 반영)
        if let selectedDate = calendarState.selectedDate {
            selectDate(selectedDate)
        }
    }

    // 커스텀 카테고리를 추가하는 메서드
    func addCustomCategory(_ category: String) {
        guard !customCategories.contains(category) else { return }  // 이미 존재하는 카테고리면 추가하지 않음
        customCategories.append(category)  // 카테고리 배열에 추가
        UserDefaults.standard.customCategories = customCategories  // UserDefaults에 저장하여 앱 재시작 후에도 유지
    }

    // 커스텀 카테고리를 삭제하는 메서드
    func removeCustomCategory(_ category: String) {
        if let index = customCategories.firstIndex(of: category) {  // 카테고리의 인덱스를 찾음
            customCategories.remove(at: index)  // 해당 인덱스의 카테고리 삭제
            UserDefaults.standard.customCategories = customCategories  // UserDefaults에 변경사항 저장
        }
    }

    // 특정 날짜의 총 지출 금액을 계산하는 메서드
    func totalExpense(for date: Date) -> Double {
        expenses
            .filter { calendar.isDate($0.date, inSameDayAs: date) }  // 같은 날짜의 지출들만 필터링
            .map { $0.amount }      // 지출 객체에서 금액만 추출
            .reduce(0, +)           // 모든 금액을 합산
    }
    
    // 금액을 한국 원화 형식으로 포맷팅하는 메서드
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal        // 천 단위 구분자 사용
        formatter.maximumFractionDigits = 0     // 소수점 이하 표시하지 않음
        // 포맷팅된 문자열에 "원"을 추가하여 반환 (실패 시 "0원" 반환)
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + "원"
    }
    
    // 현재 월의 공휴일 목록을 반환하는 메서드 (새로 추가된 기능)
    func getHolidaysForCurrentMonth() -> [KoreanHoliday] {
        return holidayService.getHolidays(for: selectedYear).filter { holiday in
            // 공휴일의 월이 현재 선택된 월과 같은지 확인
            let holidayComponents = calendar.dateComponents([.month], from: holiday.date)
            return holidayComponents.month == selectedMonth
        }
    }
    
    // 특정 날짜가 공휴일인지 확인하는 메서드 (새로 추가된 기능)
    func isHoliday(date: Date) -> Bool {
        return holidayService.isHoliday(date: date) != nil
    }

    // 데이터베이스에서 지출 데이터를 로드하는 private 메서드
    private func loadExpenses() {
        guard let context = modelContext else { return }  // ModelContext가 없으면 종료
        let fetchRequest = FetchDescriptor<Expense>()     // Expense 타입의 모든 데이터를 가져오는 요청 생성
        do {
            expenses = try context.fetch(fetchRequest)    // 데이터베이스에서 지출 데이터 fetch
        } catch {
            print("지출 데이터를 불러오는 데 실패했습니다: \(error)")  // 에러 로깅
            expenses = []  // 실패 시 빈 배열로 초기화
        }
    }

    // ModelContext의 변경사항을 데이터베이스에 저장하는 private 메서드
    private func saveContext() {
        guard let context = modelContext else { return }  // ModelContext가 없으면 종료
        do {
            try context.save()  // 변경사항을 데이터베이스에 저장
        } catch {
            print("Context 저장 실패: \(error)")  // 에러 로깅
        }
    }

    // UserDefaults에서 커스텀 카테고리를 로드하는 private 메서드
    private func loadCustomCategories() {
        customCategories = UserDefaults.standard.customCategories
    }
    
    // 현재 날짜로 초기 설정하는 private 메서드
    private func initializeCurrentDate() {
        let currentDate = Date()
        selectDate(currentDate)  // 현재 날짜를 선택된 상태로 설정
    }
    
    // 캘린더에 표시할 날짜들을 생성하는 private 메서드
    private func generateCalendarDays() -> [CalendarDay] {
        // 현재 선택된 월의 첫 번째 날 생성
        guard let firstOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) else {
            return []  // 날짜 생성 실패 시 빈 배열 반환
        }
        
        // 첫 번째 날의 요일 (1=일요일, 2=월요일, ...)
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        // 현재 월의 총 일수
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        
        // 이전 달의 날짜 정보
        let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonthDate)!.count
        
        var result: [CalendarDay] = []
        
        // 이전 달의 마지막 날들을 캘린더 앞쪽에 추가 (회색으로 표시될 날들)
        for i in stride(from: weekdayOfFirst - 2, through: 0, by: -1) {
            let date = calendar.date(from: DateComponents(year: prevMonthDate.year, month: prevMonthDate.month, day: daysInPrevMonth - i))!
            let holiday = holidayService.isHoliday(date: date)  // 공휴일 확인
            let day = CalendarDay(
                date: date,
                isInCurrentMonth: false,  // 현재 월이 아님을 표시
                dayNumber: calendar.component(.day, from: date),
                totalExpense: totalExpense(for: date),
                holiday: holiday
            )
            result.append(day)
        }
        
        // 현재 달의 모든 날들을 추가
        for day in 1...daysInMonth {
            let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: day))!
            let holiday = holidayService.isHoliday(date: date)  // 공휴일 확인
            let calendarDay = CalendarDay(
                date: date,
                isInCurrentMonth: true,   // 현재 월임을 표시
                dayNumber: day,
                totalExpense: totalExpense(for: date),
                holiday: holiday
            )
            result.append(calendarDay)
        }
        
        // 다음 달의 첫 번째 날들을 캘린더 뒤쪽에 추가 (회색으로 표시될 날들)
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
        // 캘린더를 완전한 격자로 만들기 위해 필요한 남은 일수 계산
        let remainingDays = CalendarConfiguration.totalCalendarDays - result.count
        
        for day in 1...remainingDays {
            let date = calendar.date(from: DateComponents(year: nextMonthDate.year, month: nextMonthDate.month, day: day))!
            let holiday = holidayService.isHoliday(date: date)  // 공휴일 확인
            let calendarDay = CalendarDay(
                date: date,
                isInCurrentMonth: false,  // 현재 월이 아님을 표시
                dayNumber: day,
                totalExpense: totalExpense(for: date),
                holiday: holiday
            )
            result.append(calendarDay)
        }
        
        return result
    }
}
