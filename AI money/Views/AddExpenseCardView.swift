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
        VStack(alignment: .leading, spacing: 18) {
            // Date section with modern styling
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                    )
                Spacer()
                Text(AddExpenseView.formatDate(selectedDate))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Category section with enhanced styling
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.15))
                    )
                if isEditing {
                    Button(action: onShowCategoryManagement) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                Spacer()
                Picker("카테고리", selection: $group.category) {
                    ForEach(allCategories, id: \.self) { category in
                        Text(category)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.primary)
            }
            
            // Amount section with improved input styling
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                        )
                    Spacer()
                    TextField("금액 입력(필수)", text: $group.formattedAmount)
                        .keyboardType(.numberPad)
                        .onChange(of: group.formattedAmount) { oldValue, newValue in
                            group.updateAmount(newValue)
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(group.formattedAmount.isEmpty ? Color(.systemGray6) : 
                                      (group.isValid ? Color.blue.opacity(0.05) : Color.red.opacity(0.05)))
                                .stroke(group.formattedAmount.isEmpty ? Color.clear : 
                                       (group.isValid ? Color.blue.opacity(0.3) : Color.red.opacity(0.5)), lineWidth: 1.5)
                        )
                        .animation(.easeInOut(duration: 0.2), value: group.formattedAmount.isEmpty)
                        .animation(.easeInOut(duration: 0.2), value: group.isValid)
                    
                    if !group.formattedAmount.isEmpty {
                        Text("원")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Note section with enhanced styling
            HStack {
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.purple)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                    )
                Spacer()
                TextField("메모 (선택)", text: $group.note)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(group.note.isEmpty ? Color(.systemGray6) : Color.purple.opacity(0.05))
                            .stroke(group.note.isEmpty ? Color.clear : Color.purple.opacity(0.3), lineWidth: 1.5)
                    )
                    .animation(.easeInOut(duration: 0.2), value: group.note.isEmpty)
            }
            
            // Delete button with enhanced styling
            if isEditing && expenseGroupCount > 1 {
                Button(action: { onDelete(index) }) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("삭제")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .padding(.top, 8)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
