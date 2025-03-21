//
//  EditEspenseView.swift
//  AI money
//
//  Created by 조준희 on 3/22/25.
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var expense: Expense
    @Query var categories: [Category]
    @State private var selectedCategory: Category?
    @StateObject var expenseViewModel = ExpenseViewModel()

    var body: some View {
        NavigationView {
            Form {
                DatePicker("날짜", selection: $expense.date, displayedComponents: .date)
                TextField("금액", value: $expense.amount, format: .number)
                    .keyboardType(.decimalPad)
                TextField("내용", text: $expense.memo)
                Picker("카테고리", selection: $selectedCategory) {
                    Text("없음").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            .navigationTitle("지출 편집")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        expenseViewModel.updateExpense(expense: expense, newDate: expense.date, newAmount: expense.amount, newMemo: expense.memo, newCategory: selectedCategory)
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedCategory = expense.category
            }
        }
    }
}
