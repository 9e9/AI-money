//
//  CreateNewCategoryView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

struct CreateNewCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var newCategoryName: String = ""
    
    private var customCategories: [String] {
        get { UserDefaults.standard.customCategories }
        set { UserDefaults.standard.customCategories = newValue }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("새로운 카테고리 이름")) {
                    TextField("카테고리 이름 입력", text: $newCategoryName)
                }
            }
            .navigationTitle("새 카테고리 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveCategory()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func saveCategory() {
        let trimmedCategory = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return }
        guard !customCategories.contains(trimmedCategory) else { return }

        var updatedCategories = customCategories
        updatedCategories.append(trimmedCategory)
        UserDefaults.standard.customCategories = updatedCategories
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct CreateNewCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewCategoryView()
    }
}
