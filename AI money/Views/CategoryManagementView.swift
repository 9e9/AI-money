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

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    if viewModel.isEditingMode {
                        HStack {
                            Button(action: { viewModel.handleSelectionAction() }) {
                                Text(viewModel.selectionButtonTitle)
                                    .font(.headline)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .transition(.opacity)
                            }
                            Spacer()

                            if !viewModel.selectedCategories.isEmpty {
                                Button(action: { viewModel.askDeleteSelectedCategories() }) {
                                    Text("삭제")
                                        .font(.headline)
                                        .padding(8)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .transition(.opacity)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .animation(.easeInOut, value: viewModel.isEditingMode)
                    }

                    if viewModel.customCategories.isEmpty {
                        Spacer()
                        Text("카테고리가 없음")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.customCategories, id: \.self) { category in
                                    HStack {
                                        if viewModel.isEditingMode {
                                            Button(action: { viewModel.toggleSelection(for: category) }) {
                                                Image(systemName: viewModel.selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(.blue)
                                                    .transition(.opacity)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }

                                        Text(category)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .transition(.opacity)
                                        Spacer()

                                        if viewModel.isEditingMode {
                                            Button(action: { viewModel.askDeleteCategory(category) }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .transition(.opacity)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .background(Color(UIColor.systemGray5))
                    }
                    Spacer()
                }
                .background(Color(UIColor.systemGray5))

                VStack {
                    Spacer()
                    HStack {
                        TextField("새 카테고리", text: $viewModel.newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical, 8)
                        Button(action: { viewModel.addCategory() }) {
                            Text("추가")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray5))
                }
            }
            .background(Color(UIColor.systemGray5))
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
                            viewModel.handleAlertDelete()
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
}
