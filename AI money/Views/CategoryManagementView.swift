//
//  CategoryManagementView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ExpenseViewModel = ExpenseViewModel.shared
    @State private var newCategoryName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var categoryToDelete: String?
    @State private var selectedCategories: Set<String> = []
    @State private var isEditingMode = false

    var body: some View {
        NavigationView {
            VStack {
                // 선택 삭제 및 전체 선택/해제 버튼
                if isEditingMode {
                    HStack {
                        Button(action: handleSelectionAction) {
                            Text(selectionButtonTitle())
                                .font(.headline)
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        Spacer()

                        if !selectedCategories.isEmpty {
                            Button(action: {
                                showingAlert = true
                                alertMessage = "선택한 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
                            }) {
                                Text("삭제")
                                    .font(.headline)
                                    .padding(8)
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 카테고리 목록
                if viewModel.customCategories.isEmpty {
                    Spacer()
                    Text("카테고리가 없음")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.customCategories, id: \.self) { category in
                            HStack {
                                // 체크박스 표시
                                if isEditingMode {
                                    Button(action: {
                                        toggleSelection(for: category)
                                    }) {
                                        Image(systemName: selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }

                                Text(category)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()

                                // 개별 삭제 버튼
                                if isEditingMode {
                                    Button(action: {
                                        categoryToDelete = category
                                        showingAlert = true
                                        alertMessage = "'\(category)' 카테고리를 삭제하시겠습니까? 관련된 지출 내역도 삭제됩니다."
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()

                // 새 카테고리 추가 영역
                HStack {
                    TextField("새 카테고리", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 8)
                    Button(action: addCategory) {
                        Text("추가")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("카테고리 관리")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // 취소 버튼
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("취소")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 수정 버튼
                    if isEditingMode {
                        Button(action: { isEditingMode.toggle() }) {
                            Text("닫기")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: { isEditingMode.toggle() }) {
                            Text("수정")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    // 완료 버튼
                    Button("완료") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                if alertMessage.contains("삭제하시겠습니까") {
                    return Alert(
                        title: Text("삭제 확인"),
                        message: Text(alertMessage),
                        primaryButton: .destructive(Text("삭제")) {
                            if let category = categoryToDelete {
                                deleteCategory(named: category) // 개별 삭제
                            } else {
                                deleteSelectedCategories() // 선택 삭제
                            }
                        },
                        secondaryButton: .cancel(Text("취소"))
                    )
                } else {
                    return Alert(
                        title: Text("알림"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }

    // 전체 선택, 전체 해제, 선택 해제 버튼 제목
    private func selectionButtonTitle() -> String {
        if selectedCategories.isEmpty {
            return "전체 선택"
        } else if selectedCategories.count == viewModel.customCategories.count {
            return "전체 해제"
        } else {
            return "선택 해제"
        }
    }

    // 전체 선택/해제 로직
    private func handleSelectionAction() {
        if selectedCategories.isEmpty {
            selectedCategories = Set(viewModel.customCategories)
        } else if selectedCategories.count == viewModel.customCategories.count {
            selectedCategories.removeAll()
        } else {
            selectedCategories.removeAll()
        }
    }

    // 개별 선택 토글
    private func toggleSelection(for category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    // 새 카테고리 추가
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let normalizedNewCategory = trimmedName.replacingOccurrences(of: " ", with: "").lowercased()
        let normalizedCategories = viewModel.customCategories.map { $0.replacingOccurrences(of: " ", with: "").lowercased() }
        
        if normalizedCategories.contains(normalizedNewCategory) {
            showingAlert = true
            alertMessage = "'\(trimmedName)' 카테고리는 이미 존재합니다."
            return
        }
        
        viewModel.addCustomCategory(trimmedName)
        newCategoryName = ""
    }

    // 개별 삭제
    private func deleteCategory(named category: String) {
        viewModel.removeCustomCategory(category)
        selectedCategories.remove(category)
        viewModel.removeExpenses(for: category)
    }

    // 선택 삭제
    private func deleteSelectedCategories() {
        for category in selectedCategories {
            deleteCategory(named: category)
        }
        selectedCategories.removeAll()
    }
}
