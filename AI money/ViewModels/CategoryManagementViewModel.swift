//
//  CategoryManagementViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

@MainActor
class CategoryManagementViewModel: ObservableObject {
    @Published var newCategoryName = ""
    @Published var alertMessage = ""
    @Published var categoryToDelete: String?
    @Published var selectedCategories: Set<String> = []

    private let expenseService: ExpenseServiceProtocol

    init(expenseService: ExpenseServiceProtocol) {
        self.expenseService = expenseService
    }

    var customCategories: [String] {
        expenseService.customCategories
    }

    var selectionButtonTitle: String {
        if selectedCategories.isEmpty {
            return "전체 선택"
        } else if selectedCategories.count == customCategories.count {
            return "전체 해제"
        } else {
            return "선택 해제"
        }
    }

    func handleSelectionAction() {
        if selectedCategories.isEmpty {
            selectedCategories = Set(customCategories)
        } else {
            selectedCategories.removeAll()
        }
    }

    func toggleSelection(for category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func validateAndAddCategory() -> ValidationResult {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            return .failure("카테고리 이름을 입력해주세요.")
        }
        
        let normalizedNewCategory = trimmedName.replacingOccurrences(of: " ", with: "").lowercased()
        let normalizedCategories = customCategories.map { $0.replacingOccurrences(of: " ", with: "").lowercased() }
        
        if normalizedCategories.contains(normalizedNewCategory) {
            alertMessage = "'\(trimmedName)' 카테고리는 이미 존재합니다."
            return .failure(alertMessage)
        }
        
        expenseService.addCustomCategory(trimmedName)
        newCategoryName = ""
        return .success
    }

    func prepareDeleteCategory(_ category: String) -> String {
        categoryToDelete = category
        alertMessage = "'\(category)' 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
        return alertMessage
    }

    func prepareDeleteSelectedCategories() -> String {
        alertMessage = "선택한 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
        return alertMessage
    }

    func deleteCategory(named category: String) {
        expenseService.removeCustomCategory(category)
        selectedCategories.remove(category)
        expenseService.removeExpenses(for: category)
    }

    func deleteSelectedCategories() {
        selectedCategories.forEach { deleteCategory(named: $0) }
        selectedCategories.removeAll()
    }

    func handleConfirmedDelete() {
        if let category = categoryToDelete {
            deleteCategory(named: category)
            categoryToDelete = nil
        } else {
            deleteSelectedCategories()
        }
    }
    
    func resetState() {
        newCategoryName = ""
        selectedCategories.removeAll()
        categoryToDelete = nil
        alertMessage = ""
    }
}

enum ValidationResult {
    case success
    case failure(String)
}
