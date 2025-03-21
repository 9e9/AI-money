//
//  AddExpenseViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    @State private var amount: Double?
    @State private var memo = ""
    @State private var categoryName = ""
    @Query var categories: [Category]
    @State private var selectedCategory: Category?
    @State var expenseViewModel = ExpenseViewModel()

    var body: some View {
        NavigationView {
            Form {
                DatePicker("날짜", selection: $date, displayedComponents: .date)
                TextField("금액", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                TextField("내용", text: $memo)
                Picker("카테고리", selection: $selectedCategory) {
                    Text("없음").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }

                Section {
                    Button("저장") {
                        if let amount = amount {
                            expenseViewModel.addExpense(modelContext: modelContext, date: date, amount: amount, memo: memo, category: selectedCategory)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("새 지출 추가")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}
