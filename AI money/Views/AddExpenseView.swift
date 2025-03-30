//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var date = Date()
    @State private var category = ""
    @State private var amount = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("날짜", selection: $date, displayedComponents: .date)
                
                TextField("카테고리", text: $category)
                
                TextField("금액", text: $amount)
                    .keyboardType(.decimalPad)
                
                TextField("메모", text: $note)
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let newExpense = Expense(date: date, category: category, amount: Double(amount) ?? 0.0, note: note)
                        viewModel.addExpense(newExpense)
                        presentationMode.wrappedValue.dismiss()
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
}

struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView(viewModel: ExpenseViewModel())
    }
}
