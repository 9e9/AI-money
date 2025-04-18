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
    @State private var categoryToDelete: String?

    var body: some View {
        NavigationView {
            VStack {
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
                                Text(category)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    categoryToDelete = category
                                    showingAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()

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
            .navigationBarItems(trailing: Button("완료") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("삭제 확인"),
                    message: Text("정말로 '\(categoryToDelete ?? "")'를 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        if let category = categoryToDelete {
                            deleteCategory(named: category)
                        }
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            }
        }
    }

    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        viewModel.addCustomCategory(trimmedName)
        newCategoryName = ""
    }

    private func deleteCategory(named category: String) {
        viewModel.removeCustomCategory(category)
    }
}
