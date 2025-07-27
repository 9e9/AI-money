//
//  CategoryManagementView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CategoryManagementViewModel()
    @State private var showTextField = false
    @State private var recentlyAddedCategory: String? = nil
    @State private var deletingCategories: Set<String> = []
    @State private var trashPressed: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    if viewModel.isEditingMode {
                        HStack {
                            Button(action: {
                                withAnimation { viewModel.handleSelectionAction() }
                            }) {
                                Text(viewModel.selectionButtonTitle)
                                    .font(.headline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.12))
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            
                            if !viewModel.selectedCategories.isEmpty {
                                Button(action: { viewModel.askDeleteSelectedCategories() }) {
                                    HStack {
                                        Text("삭제")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                }
                                .animation(.easeInOut(duration: 0.33), value: viewModel.selectedCategories)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    if viewModel.customCategories.isEmpty {
                        Spacer()
                        Text("카테고리가 없습니다")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(viewModel.customCategories, id: \.self) { category in
                                    HStack {
                                        if viewModel.isEditingMode {
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.toggleSelection(for: category)
                                                }
                                            }) {
                                                Image(systemName: viewModel.selectedCategories.contains(category) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(.blue)
                                                    .font(.title3)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        Text(category)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if viewModel.isEditingMode {
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2)) {
                                                    trashPressed = category
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                        trashPressed = nil
                                                    }
                                                }
                                                viewModel.askDeleteCategory(category)
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 20, weight: .regular))
                                                    .foregroundColor(.red)
                                                    .opacity(trashPressed == category ? 0.3 : 1.0)
                                                    .animation(.easeInOut(duration: 0.5), value: trashPressed)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                            .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                    Spacer()
                }
                VStack {
                    Spacer()
                    HStack {
                        if showTextField {
                            TextField("새 카테고리", text: $viewModel.newCategoryName, onCommit: {
                                addCategoryWithEffect()
                            })
                            .padding(.horizontal)
                            .frame(height: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            Button(action: addCategoryWithEffect) {
                                Text("추가")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            Button(action: {
                                withAnimation { showTextField = false }
                                viewModel.newCategoryName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 6)
                        } else {
                            Spacer()
                            Button(action: {
                                withAnimation { showTextField = true }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 54, height: 54)
                                    .foregroundColor(.blue)
                                    .shadow(radius: 6)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                }
            }
            .navigationTitle("카테고리 관리")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("취소")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { withAnimation { viewModel.isEditingMode.toggle() } }) {
                        Text(viewModel.isEditingMode ? "닫기" : "수정")
                            .font(.headline)
                            .foregroundColor(viewModel.isEditingMode ? .red : .blue)
                    }
                }
            }
            .alert(isPresented: $viewModel.showingAlert) {
                if (viewModel.alertMessage.contains("삭제하시겠습니까")) {
                    return Alert(
                        title: Text("삭제 확인"),
                        message: Text(viewModel.alertMessage),
                        primaryButton: .destructive(Text("삭제")) {
                            if !viewModel.selectedCategories.isEmpty {
                                deletingCategories = viewModel.selectedCategories
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.handleAlertDelete()
                                    deletingCategories = []
                                }
                            } else if let target = viewModel.categoryToDelete {
                                deletingCategories = [target]
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.handleAlertDelete()
                                    deletingCategories = []
                                }
                            }
                        },
                        secondaryButton: .cancel(Text("취소"))
                    )
                } else {
                    return Alert(
                        title: Text("알림"),
                        message: Text(viewModel.alertMessage),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }

    private func addCategoryWithEffect() {
        let trimmed = viewModel.newCategoryName.trimmingCharacters(in: .whitespaces)
        viewModel.addCategory()
        viewModel.newCategoryName = ""
    }
}
