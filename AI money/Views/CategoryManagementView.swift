//
//  CategoryManagementView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var vm = CategoryManagementViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    if vm.isEditingMode {
                        HStack {
                            Button(action: { vm.handleSelectionAction() }) {
                                Text(vm.selectionButtonTitle)
                                    .font(.headline)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .transition(.opacity)
                            }
                            Spacer()

                            if !vm.selectedCategories.isEmpty {
                                Button(action: { vm.askDeleteSelectedCategories() }) {
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
                        .animation(.easeInOut, value: vm.isEditingMode)
                    }

                    if vm.customCategories.isEmpty {
                        Spacer()
                        Text("카테고리가 없음")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(vm.customCategories, id: \.self) { category in
                                    HStack {
                                        if vm.isEditingMode {
                                            Button(action: { vm.toggleSelection(for: category) }) {
                                                Image(systemName: vm.selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
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

                                        if vm.isEditingMode {
                                            Button(action: { vm.askDeleteCategory(category) }) {
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
                        TextField("새 카테고리", text: $vm.newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical, 8)
                        Button(action: { vm.addCategory() }) {
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
                    Button(action: { withAnimation { vm.isEditingMode.toggle() } }) {
                        Text(vm.isEditingMode ? "닫기" : "수정")
                            .font(.headline)
                            .foregroundColor(vm.isEditingMode ? .red : .blue)
                    }
                }
            }
            .alert(isPresented: $vm.showingAlert) {
                if (vm.alertMessage.contains("삭제하시겠습니까")) {
                    return Alert(
                        title: Text("삭제 확인"),
                        message: Text(vm.alertMessage),
                        primaryButton: .destructive(Text("삭제")) {
                            vm.handleAlertDelete()
                        },
                        secondaryButton: .cancel(Text("취소"))
                    )
                } else {
                    return Alert(
                        title: Text("알림"),
                        message: Text(vm.alertMessage),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }
}
