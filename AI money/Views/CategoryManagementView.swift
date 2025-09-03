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
    @State private var deletingCategories: Set<String> = []
    @State private var trashPressed: String? = nil
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isEditingMode {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.handleSelectionAction()
                            }
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
                            .opacity(viewModel.selectedCategories.isEmpty ? 0 : 1)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategories.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                if viewModel.customCategories.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("카테고리가 없습니다")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(Array(viewModel.customCategories.enumerated()), id: \.element) { index, category in
                                CategoryRowView(
                                    category: category,
                                    isEditingMode: viewModel.isEditingMode,
                                    isSelected: viewModel.selectedCategories.contains(category),
                                    isDeleting: deletingCategories.contains(category),
                                    trashPressed: trashPressed,
                                    onToggleSelection: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            viewModel.toggleSelection(for: category)
                                        }
                                    },
                                    onDelete: {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            trashPressed = category
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                trashPressed = nil
                                            }
                                        }
                                        viewModel.askDeleteCategory(category)
                                    }
                                )
                                .opacity(deletingCategories.contains(category) ? 0 : 1)
                                .animation(.easeInOut(duration: 0.4), value: deletingCategories)
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.customCategories)
                    }
                }
                
                if showTextField {
                    VStack(spacing: 12) {
                        Divider()
                            .transition(.opacity)
                        
                        HStack(spacing: 12) {
                            TextField("새 카테고리 이름", text: $viewModel.newCategoryName, onCommit: {
                                addCategoryWithEffect()
                            })
                            .focused($isTextFieldFocused)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            
                            Button(action: addCategoryWithEffect) {
                                Text("추가")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                                    )
                            }
                            .disabled(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.newCategoryName.isEmpty)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showTextField = false
                                    isTextFieldFocused = false
                                }
                                viewModel.newCategoryName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                }
                
                if !showTextField {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTextField = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("카테고리 추가")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer(minLength: 0)
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
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.isEditingMode.toggle()
                            if viewModel.isEditingMode {
                                showTextField = false
                                isTextFieldFocused = false
                                viewModel.newCategoryName = ""
                            }
                        }
                    }) {
                        Text(viewModel.isEditingMode ? "완료" : "편집")
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
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    deletingCategories = viewModel.selectedCategories
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    viewModel.handleAlertDelete()
                                    deletingCategories = []
                                }
                            } else if let target = viewModel.categoryToDelete {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    deletingCategories = [target]
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
        let trimmedName = viewModel.newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            viewModel.addCategory()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showTextField = false
                isTextFieldFocused = false
            }
            viewModel.newCategoryName = ""
        }
    }
}

struct CategoryRowView: View {
    let category: String
    let isEditingMode: Bool
    let isSelected: Bool
    let isDeleting: Bool
    let trashPressed: String?
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if isEditingMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.system(size: 22))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                .buttonStyle(BorderlessButtonStyle())
                .opacity(isEditingMode ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: isEditingMode)
            }
            
            Text(category)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditingMode {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.red)
                        .opacity(trashPressed == category ? 0.4 : 1.0)
                        .scaleEffect(trashPressed == category ? 0.9 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: trashPressed)
                }
                .buttonStyle(BorderlessButtonStyle())
                .opacity(isEditingMode ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: isEditingMode)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(isDeleting ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDeleting)
    }
}
