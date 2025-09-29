//
//  CategoryManagementViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

/// 카테고리 관리 화면의 비즈니스 로직을 담당하는 ViewModel
/// @MainActor를 통해 UI 업데이트가 메인 스레드에서 안전하게 실행되도록 보장
@MainActor
class CategoryManagementViewModel: ObservableObject {
    /// 새 카테고리 입력 필드의 텍스트를 바인딩하는 Published 속성
    @Published var newCategoryName = ""
    
    /// 알림 메시지 텍스트를 저장하고 UI에 바인딩하는 Published 속성
    @Published var alertMessage = ""
    
    /// 삭제 확인 대화상자에서 삭제할 단일 카테고리를 추적하는 옵셔널 속성
    @Published var categoryToDelete: String?
    
    /// 사용자가 선택한 카테고리들의 집합을 추적하는 Set (중복 방지)
    @Published var selectedCategories: Set<String> = []

    /// 의존성 주입을 위한 ExpenseService 프로토콜 참조
    /// 실제 데이터 조작은 이 서비스를 통해 수행
    private let expenseService: ExpenseServiceProtocol

    /// 의존성 주입을 통한 초기화
    /// - Parameter expenseService: 비용 관리 서비스 프로토콜 구현체
    init(expenseService: ExpenseServiceProtocol) {
        self.expenseService = expenseService
    }

    /// ExpenseService로부터 커스텀 카테고리 목록을 가져오는 computed property
    /// UI에서 카테고리 목록 표시에 사용
    var customCategories: [String] {
        expenseService.customCategories
    }

    /// 선택 상태에 따라 버튼 제목을 동적으로 결정하는 computed property
    /// - 아무것도 선택되지 않은 경우: "전체 선택"
    /// - 모든 항목이 선택된 경우: "전체 해제"
    /// - 일부만 선택된 경우: "선택 해제"
    var selectionButtonTitle: String {
        if selectedCategories.isEmpty {
            return "전체 선택"
        } else if selectedCategories.count == customCategories.count {
            return "전체 해제"
        } else {
            return "선택 해제"
        }
    }

    /// 선택 버튼 탭 시 실행되는 액션 핸들러
    /// 현재 선택 상태에 따라 전체 선택 또는 전체 해제를 수행
    func handleSelectionAction() {
        if selectedCategories.isEmpty {
            // 아무것도 선택되지 않은 경우 → 모든 카테고리 선택
            selectedCategories = Set(customCategories)
        } else {
            // 하나 이상 선택된 경우 → 모든 선택 해제
            selectedCategories.removeAll()
        }
    }

    /// 개별 카테고리의 선택 상태를 토글하는 함수
    /// - Parameter category: 선택 상태를 변경할 카테고리 이름
    func toggleSelection(for category: String) {
        if selectedCategories.contains(category) {
            // 이미 선택된 경우 → 선택 해제
            selectedCategories.remove(category)
        } else {
            // 선택되지 않은 경우 → 선택 추가
            selectedCategories.insert(category)
        }
    }

    /// 새 카테고리 추가 시 유효성 검증 및 추가를 수행하는 함수
    /// - Returns: 성공/실패 결과를 담은 ValidationResult enum
    func validateAndAddCategory() -> ValidationResult {
        // 공백 문자 제거 후 검증
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        
        // 빈 문자열 검증
        guard !trimmedName.isEmpty else {
            return .failure("카테고리 이름을 입력해주세요.")
        }
        
        // 중복 검사를 위해 공백 제거 및 소문자로 정규화
        let normalizedNewCategory = trimmedName.replacingOccurrences(of: " ", with: "").lowercased()
        let normalizedCategories = customCategories.map { $0.replacingOccurrences(of: " ", with: "").lowercased() }
        
        // 중복 카테고리 검증
        if normalizedCategories.contains(normalizedNewCategory) {
            alertMessage = "'\(trimmedName)' 카테고리는 이미 존재합니다."
            return .failure(alertMessage)
        }
        
        // 유효성 검증 통과 시 카테고리 추가 및 입력 필드 초기화
        expenseService.addCustomCategory(trimmedName)
        newCategoryName = ""
        return .success
    }

    /// 단일 카테고리 삭제 확인 대화상자 준비 함수
    /// - Parameter category: 삭제할 카테고리 이름
    /// - Returns: 사용자에게 표시할 확인 메시지
    func prepareDeleteCategory(_ category: String) -> String {
        categoryToDelete = category
        alertMessage = "'\(category)' 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
        return alertMessage
    }

    /// 선택된 여러 카테고리 삭제 확인 대화상자 준비 함수
    /// - Returns: 사용자에게 표시할 확인 메시지
    func prepareDeleteSelectedCategories() -> String {
        alertMessage = "선택한 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
        return alertMessage
    }

    /// 지정된 카테고리를 실제로 삭제하는 내부 함수
    /// - Parameter category: 삭제할 카테고리 이름
    /// 카테고리 삭제 + 선택 목록에서 제거 + 관련 지출 내역 삭제를 순차적으로 수행
    func deleteCategory(named category: String) {
        expenseService.removeCustomCategory(category)       // 카테고리 삭제
        selectedCategories.remove(category)                 // 선택 목록에서 제거
        expenseService.removeExpenses(for: category)        // 해당 카테고리의 모든 지출 내역 삭제
    }

    /// 선택된 모든 카테고리들을 삭제하는 함수
    /// forEach를 사용하여 각 선택된 카테고리에 대해 deleteCategory 함수 호출
    func deleteSelectedCategories() {
        selectedCategories.forEach { deleteCategory(named: $0) }
        selectedCategories.removeAll()  // 삭제 완료 후 선택 목록 초기화
    }

    /// 사용자가 삭제를 확인했을 때 실행되는 핸들러 함수
    /// categoryToDelete 값 존재 여부에 따라 단일/다중 삭제를 구분하여 처리
    func handleConfirmedDelete() {
        if let category = categoryToDelete {
            // 단일 카테고리 삭제 케이스
            deleteCategory(named: category)
            categoryToDelete = nil  // 삭제 후 상태 초기화
        } else {
            // 선택된 다중 카테고리 삭제 케이스
            deleteSelectedCategories()
        }
    }
    
    /// ViewModel의 모든 상태를 초기 상태로 리셋하는 함수
    /// 화면 전환이나 초기화가 필요한 경우 사용
    func resetState() {
        newCategoryName = ""            // 입력 필드 초기화
        selectedCategories.removeAll()  // 선택 목록 초기화
        categoryToDelete = nil          // 삭제 대상 초기화
        alertMessage = ""              // 알림 메시지 초기화
    }
}

/// 카테고리 추가 시 유효성 검증 결과를 나타내는 열거형
/// 성공과 실패(에러 메시지 포함) 두 가지 케이스로 구성
enum ValidationResult {
    case success                    // 검증 성공
    case failure(String)           // 검증 실패 (에러 메시지 포함)
}
