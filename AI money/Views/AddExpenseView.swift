//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("지출 항목", text: $title)
                TextField("금액", text: $amount)
                    .keyboardType(.decimalPad)

                DatePicker("날짜", selection: $selectedDate, displayedComponents: .date)

                Button("저장") {
                    if let expenseAmount = Double(amount) {
                        let newExpense = Expense(title: title, amount: expenseAmount, date: selectedDate)
                        modelContext.insert(newExpense)
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}
