//
//  AddExpenseCardView.swift
//  AI money
//
//  Created by 조준희 on 7/27/25.
//

import SwiftUI

struct AddExpenseCardView: View {
    @Binding var group: ExpenseGroup
    let index: Int
    let selectedDate: Date
    let isEditing: Bool
    let allCategories: [String]
    let expenseGroupCount: Int
    let onDelete: (Int) -> Void
    let onShowCategoryManagement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Spacer()
                Text(AddExpenseView.formatDate(selectedDate))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.green)
                if isEditing {
                    Button(action: onShowCategoryManagement) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                            .imageScale(.medium)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                Spacer()
                Picker("카테고리", selection: $group.category) {
                    ForEach(allCategories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.leading, 200)
            }
            
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.orange)
                Spacer()
                TextField("금액 입력(필수)", text: $group.formattedAmount)
                    .keyboardType(.numberPad)
                    .onChange(of: group.formattedAmount) { oldValue, newValue in
                        let filteredValue = newValue.replacingOccurrences(of: ",", with: "")
                        if let number = Int(filteredValue) {
                            group.formattedAmount = AddExpenseView.formatWithComma(String(number))
                            group.amount = String(number)
                        } else {
                            group.formattedAmount = ""
                            group.amount = ""
                        }
                    }
                    .multilineTextAlignment(.trailing)
                
                if !group.formattedAmount.isEmpty {
                    Text("원").foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.purple)
                Spacer()
                TextField("메모 (선택)", text: $group.note)
                    .multilineTextAlignment(.trailing)
            }
            if isEditing && expenseGroupCount > 1 {
                Button(action: { onDelete(index) }) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("삭제")
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
    }
}
