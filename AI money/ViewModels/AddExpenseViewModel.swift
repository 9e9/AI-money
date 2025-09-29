//
//  AddExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftUI

// MARK: - 지출 입력 그룹 구조체
/// 하나의 지출 항목을 나타내는 데이터 구조체
struct ExpenseGroup {
    var category: String = "기타" // 지출 카테고리 (기본값: "기타")
    var amount: String = "" // 사용자가 입력한 금액 문자열
    var formattedAmount: String = "" // 천 단위 콤마가 적용된 금액 문자열
    var note: String = "" // 지출에 대한 메모
}

// MARK: - 지출 추가 화면 뷰모델
/// 지출 추가 화면의 비즈니스 로직과 상태를 관리하는 클래스
class AddExpenseViewModel: ObservableObject {
    // MARK: - Published 프로퍼티들 (UI 바인딩용)
    @Published var expenseGroups: [ExpenseGroup] = [ExpenseGroup()] // 지출 그룹 배열 (기본 1개)
    @Published var allCategories: [String] = [] // 사용 가능한 모든 카테고리 목록
    @Published var totalAmount: Double = 0 // 모든 지출의 합계 금액
    @Published var hasUnsavedChanges: Bool = false // 저장되지 않은 변경사항 여부
    @Published var showingAlert: Bool = false // 알림창 표시 여부
    @Published var alertTitle: String = "" // 알림창 제목
    @Published var alertMessage: String = "" // 알림창 메시지
    @Published var showingSaveAnimation: Bool = false // 저장 애니메이션 표시 여부
    
    // MARK: - 상수 정의
    /// 빠른 금액 입력을 위한 미리 정의된 금액 목록
    private let quickAmountSuggestions = ["5000", "10000", "20000", "30000", "50000", "100000"]
    
    // MARK: - 계산된 프로퍼티들
    /// 유효한 지출 개수 (금액이 입력되고 0보다 큰 지출들)
    var validExpenseCount: Int {
        expenseGroups.filter { !$0.amount.isEmpty && Double($0.amount) ?? 0 > 0 }.count
    }
    
    /// 유효한 지출이 하나라도 있는지 확인
    var hasValidExpenses: Bool {
        expenseGroups.contains { !$0.amount.isEmpty && Double($0.amount) ?? 0 > 0 }
    }
    
    /// 입력 폼이 완전히 비어있는지 확인
    var isEmpty: Bool {
        expenseGroups.count == 1 && expenseGroups.first?.amount.isEmpty == true
    }

    // MARK: - 카테고리 관리
    /// 미리 정의된 카테고리와 사용자 정의 카테고리를 합쳐서 전체 카테고리 목록을 업데이트
    func updateCategories() {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"] // 기본 카테고리들
        let customCategories = UserDefaults.standard.customCategories // 사용자가 추가한 카테고리들
        allCategories = predefinedCategories + customCategories // 두 목록을 합침
        
        // 카테고리가 비어있는 지출 그룹들에 기본 카테고리 설정
        for index in expenseGroups.indices {
            if expenseGroups[index].category.isEmpty {
                expenseGroups[index].category = allCategories.first ?? "기타"
            }
        }
        updateTotalAmount() // 전체 금액 재계산
    }

    // MARK: - 유효성 검사
    /// 모든 지출 그룹의 입력 데이터를 검증
    /// - Returns: (검증 성공 여부, 에러 메시지)
    func validate() -> (Bool, String?) {
        for (index, group) in expenseGroups.enumerated() {
            // 금액이 비어있는지 확인
            if group.amount.isEmpty {
                return (false, "지출 \(index + 1)번의 금액을 입력해주세요.")
            }
            
            // 금액이 유효한 범위인지 확인 (FormatHelper의 검증 로직 사용)
            if !FormatHelper.isValidAmount(group.amount) {
                return (false, "지출 \(index + 1)번의 금액이 올바르지 않습니다.")
            }
        }
        return (true, nil) // 모든 검증 통과
    }

    // MARK: - 데이터 변환
    /// ExpenseGroup 배열을 Expense 객체 배열로 변환
    /// - Parameter selectedDate: 지출 날짜
    /// - Returns: 유효한 Expense 객체들의 배열
    func makeExpenses(selectedDate: Date) -> [Expense] {
        expenseGroups.compactMap { group in
            // 금액을 Double로 파싱하고 0보다 큰지 확인
            guard let amount = FormatHelper.parseAmountString(group.amount), amount > 0 else { return nil }
            // Expense 객체 생성 후 반환
            return Expense(date: selectedDate, category: group.category, amount: amount, note: group.note)
        }
    }

    // MARK: - 지출 그룹 관리
    /// 특정 인덱스의 지출 그룹을 삭제 (최소 1개는 유지)
    /// - Parameter index: 삭제할 그룹의 인덱스
    func removeGroup(at index: Int) {
        guard expenseGroups.count > 1 else { return } // 최소 1개 그룹은 유지
        expenseGroups.remove(at: index) // 해당 인덱스의 그룹 삭제
        updateTotalAmount() // 전체 금액 재계산
        hasUnsavedChanges = true // 변경사항 플래그 설정
    }

    /// 새로운 지출 그룹을 추가
    func addGroup() {
        var newGroup = ExpenseGroup() // 빈 그룹 생성
        newGroup.category = allCategories.first ?? "기타" // 첫 번째 카테고리로 설정
        expenseGroups.append(newGroup) // 배열에 추가
        hasUnsavedChanges = true // 변경사항 플래그 설정
        updateTotalAmount() // 전체 금액 재계산
    }
    
    /// 기존 지출 그룹을 복사하여 새로운 그룹 생성
    /// - Parameter index: 복사할 그룹의 인덱스
    func duplicateGroup(at index: Int) {
        guard index < expenseGroups.count else { return } // 인덱스 범위 확인
        let originalGroup = expenseGroups[index] // 원본 그룹 가져오기
        var newGroup = ExpenseGroup() // 새 그룹 생성
        newGroup.category = originalGroup.category // 카테고리 복사
        newGroup.note = originalGroup.note // 메모 복사 (금액은 복사하지 않음)
        
        expenseGroups.insert(newGroup, at: index + 1) // 원본 바로 다음에 삽입
        hasUnsavedChanges = true // 변경사항 플래그 설정
    }
    
    // MARK: - 빠른 금액 입력
    /// 미리 정의된 금액을 특정 그룹에 적용
    /// - Parameters:
    ///   - amount: 적용할 금액 문자열
    ///   - index: 대상 그룹의 인덱스
    func applyQuickAmount(_ amount: String, to index: Int) {
        guard index < expenseGroups.count else { return } // 인덱스 범위 확인
        expenseGroups[index].amount = amount // 원본 금액 설정
        expenseGroups[index].formattedAmount = FormatHelper.formatWithComma(amount) // 포맷된 금액 설정
        updateTotalAmount() // 전체 금액 재계산
        hasUnsavedChanges = true // 변경사항 플래그 설정
    }
    
    /// 빠른 금액 입력용 미리 정의된 금액 목록 반환
    /// - Returns: 금액 문자열 배열
    func getQuickAmounts() -> [String] {
        return quickAmountSuggestions
    }
    
    // MARK: - 저장 관련
    /// 데이터 검증 후 저장 준비 과정 실행
    /// - Parameters:
    ///   - selectedDate: 지출 날짜
    ///   - completion: 완료 후 실행할 클로저 (Expense 배열 또는 에러 메시지)
    func validateAndPrepareForSave(selectedDate: Date, completion: @escaping ([Expense]?, String?) -> Void) {
        let (isValid, errorMsg) = validate() // 데이터 유효성 검사
        if !isValid {
            // 검증 실패 시 알림창 표시
            alertTitle = "확인"
            alertMessage = errorMsg ?? ""
            showingAlert = true
            completion(nil, errorMsg) // 실패 결과 반환
            return
        }
        
        showingSaveAnimation = true // 저장 애니메이션 시작
        
        // 1초 후 실제 저장 로직 실행 (애니메이션 효과를 위한 딜레이)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newExpenses = self.makeExpenses(selectedDate: selectedDate) // Expense 객체 생성
            completion(newExpenses, nil) // 성공 결과 반환
        }
    }
    
    /// 저장 애니메이션 완료 처리
    func completeSaveAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showingSaveAnimation = false // 애니메이션 종료
        }
    }
    
    // MARK: - 종료 관련
    /// 화면 종료 시 경고창을 표시할지 결정
    /// - Returns: 저장되지 않은 변경사항이 있으면 true
    func shouldShowExitAlert() -> Bool {
        return hasUnsavedChanges
    }
    
    /// 종료 확인 알림창 준비
    func prepareExitAlert() {
        alertTitle = "나가기"
        alertMessage = "저장하지 않고 나가시겠습니까?"
        showingAlert = true
    }
    
    // MARK: - 포맷팅 유틸리티
    /// 선택된 날짜를 한국어 형식으로 포맷
    /// - Parameter date: 포맷할 날짜
    /// - Returns: "yyyy년 MM월 dd일 EEEE" 형식의 문자열
    func formatSelectedDate(_ date: Date) -> String {
        return FormatHelper.formatSelectedDate(date)
    }
    
    /// 금액을 통화 단위 없이 포맷 (천 단위 콤마만)
    /// - Parameter amount: 포맷할 금액
    /// - Returns: 천 단위 콤마가 있는 문자열
    func formatAmount(_ amount: Double) -> String {
        return FormatHelper.formatAmountWithoutCurrency(amount)
    }
    
    /// 특정 그룹의 금액 입력 시 실시간 포맷팅 처리
    /// - Parameters:
    ///   - index: 대상 그룹의 인덱스
    ///   - newValue: 새로 입력된 값
    func updateAmountFormatting(at index: Int, newValue: String) {
        guard index < expenseGroups.count else { return } // 인덱스 범위 확인
        
        let filteredValue = newValue.replacingOccurrences(of: ",", with: "") // 기존 콤마 제거
        if let number = Int(filteredValue), number >= 0 { // 숫자로 변환 가능하고 0 이상인 경우
            expenseGroups[index].formattedAmount = FormatHelper.formatWithComma(String(number)) // 포맷된 문자열 설정
            expenseGroups[index].amount = String(number) // 원본 숫자 문자열 설정
            hasUnsavedChanges = true // 변경사항 플래그 설정
        } else if newValue.isEmpty { // 입력값이 비어있는 경우
            expenseGroups[index].formattedAmount = "" // 포맷된 문자열도 비움
            expenseGroups[index].amount = "" // 원본 문자열도 비움
            hasUnsavedChanges = true // 변경사항 플래그 설정
        }
        updateTotalAmount() // 전체 금액 재계산
    }
    
    // MARK: - Private 메서드
    /// 모든 지출 그룹의 금액을 합계하여 totalAmount 업데이트
    private func updateTotalAmount() {
        totalAmount = expenseGroups.compactMap { FormatHelper.parseAmountString($0.amount) }.reduce(0, +)
    }
}
