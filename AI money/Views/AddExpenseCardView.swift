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
    let isFocused: Bool
    let onDelete: (Int) -> Void
    let onDuplicate: (Int) -> Void
    let onFocus: (Int) -> Void
    let onApplyQuickAmount: (String, Int) -> Void
    let onShowCategoryManagement: () -> Void
    let onAmountChange: (String, Int) -> Void
    
    @FocusState private var isAmountFieldFocused: Bool
    @State private var showQuickAmounts = false
    
    private let quickAmounts = ["5000", "10000", "20000", "30000", "50000", "100000"]

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            
            VStack(spacing: 24) {
                categoryRow
                amountRow
                if showQuickAmounts {
                    quickAmountGrid
                }
                noteRow
                
                if isEditing && expenseGroupCount > 1 {
                    actionRow
                }
            }
            .padding(20)
        }
        .background(cardBackground)
        .onTapGesture {
            onFocus(index)
        }
        .onChange(of: isAmountFieldFocused) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                showQuickAmounts = newValue && group.amount.isEmpty
            }
        }
    }
    
    private var cardHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isFocused ? Color.black : Color(.systemGray4))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isFocused ? .white : .secondary)
                )
            
            HStack(spacing: 12) {
                if !group.category.isEmpty {
                    Text(group.category)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                if !group.amount.isEmpty {
                    Text("\(group.formattedAmount)원")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                } else {
                    Text("금액 입력")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if isEditing && expenseGroupCount > 1 {
                Button(action: { onDelete(index) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("카테고리")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isEditing {
                    Button("관리", action: onShowCategoryManagement)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            Menu {
                ForEach(allCategories, id: \.self) { category in
                    Button(category) {
                        group.category = category
                    }
                }
            } label: {
                HStack {
                    Text(group.category)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    private var amountRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("금액")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                TextField("0", text: $group.formattedAmount)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.leading)
                    .focused($isAmountFieldFocused)
                    .onChange(of: group.formattedAmount) { oldValue, newValue in
                        onAmountChange(newValue, index)
                    }
                
                Spacer()
                
                Text("원")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isAmountFieldFocused ? Color.black : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
    }
    
    private var quickAmountGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(quickAmounts, id: \.self) { amount in
                Button(action: {
                    onApplyQuickAmount(amount, index)
                    isAmountFieldFocused = false
                }) {
                    Text("\(FormatHelper.formatWithComma(amount))원")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                        )
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var noteRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메모")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("메모 입력 (선택)", text: $group.note)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    private var actionRow: some View {
        HStack(spacing: 12) {
            Button("복사") {
                onDuplicate(index)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
            )
            
            Spacer()
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? Color.black : Color(.systemGray5),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isFocused ? 0.1 : 0.05),
                radius: isFocused ? 8 : 4,
                x: 0,
                y: 2
            )
    }
}
