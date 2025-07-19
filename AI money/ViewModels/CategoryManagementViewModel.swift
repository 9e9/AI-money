//
//  CategoryManagementViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

class CategoryManagementViewModel: ObservableObject {
    @Published var newCategoryName = ""
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var categoryToDelete: String?
    @Published var selectedCategories: Set<String> = []
    @Published var isEditingMode = false

    var expenseViewModel: ExpenseCalendarViewModel = ExpenseCalendarViewModel.shared

    var customCategories: [String] {
        expenseViewModel.customCategories
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

    func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let normalizedNewCategory = trimmedName.replacingOccurrences(of: " ", with: "").lowercased()
        let normalizedCategories = customCategories.map { $0.replacingOccurrences(of: " ", with: "").lowercased() }
        
        if normalizedCategories.contains(normalizedNewCategory) {
            showingAlert = true
            alertMessage = "'\(trimmedName)' 카테고리는 이미 존재합니다."
            return
        }
        expenseViewModel.addCustomCategory(trimmedName)
        newCategoryName = ""
    }

    func askDeleteCategory(_ category: String) {
        categoryToDelete = category
        showingAlert = true
        alertMessage = "'\(category)' 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
    }

    func askDeleteSelectedCategories() {
        showingAlert = true
        alertMessage = "선택한 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
    }

    func deleteCategory(named category: String) {
        expenseViewModel.removeCustomCategory(category)
        selectedCategories.remove(category)
        expenseViewModel.removeExpenses(for: category)
    }

    func deleteSelectedCategories() {
        // 최적화: Set의 forEach 사용
        selectedCategories.forEach { deleteCategory(named: $0) }
        selectedCategories.removeAll()
    }

    func handleAlertDelete() {
        if let category = categoryToDelete {
            deleteCategory(named: category)
            categoryToDelete = nil
        } else {
            deleteSelectedCategories()
        }
    }
}
