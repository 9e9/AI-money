//
//  CategoryManagementView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

struct CategoryManagementView: View {
    @State private var customCategories = UserDefaults.standard.customCategories
    @State private var newCategoryName = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(customCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            Button(action: {
                                deleteCategory(named: category)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .onDelete(perform: deleteCategory(at:))
                }
                .listStyle(PlainListStyle())

                HStack {
                    TextField("새 카테고리", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .alert("중복된 카테고리 이름", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("같은 이름의 카테고리가 이미 존재합니다.")
            }
        }
    }

    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !customCategories.contains(trimmedName) else {
            showingAlert = true
            return
        }
        customCategories.append(trimmedName)
        UserDefaults.standard.customCategories = customCategories
        newCategoryName = ""
    }

    private func deleteCategory(at offsets: IndexSet) {
        offsets.forEach { index in
            let category = customCategories[index]
            deleteCategory(named: category)
        }
    }

    private func deleteCategory(named category: String) {
        if let index = customCategories.firstIndex(of: category) {
            customCategories.remove(at: index)
            UserDefaults.standard.customCategories = customCategories
        }
    }
}
