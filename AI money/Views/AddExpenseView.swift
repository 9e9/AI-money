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
    @State private var category = ""
    @State private var amount = ""
    @State private var formattedAmount = ""
    var selectedDate: Date

    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("날짜")
                        .font(.headline)
                    Spacer()
                    Text(formatDate(selectedDate))
                        .foregroundColor(.secondary)
                }

                TextField("카테고리", text: $category)

                TextField("금액", text: $formattedAmount)
                    .keyboardType(.decimalPad)
                    .onChange(of: formattedAmount) {
                        amount = formattedAmount.filter { $0.isNumber }
                        formattedAmount = formatWithComma(amount)
                    }
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let newExpense = Expense(date: selectedDate, category: category, amount: Double(amount) ?? 0.0, note: "")
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        return formatter.string(from: date)
    }

    private func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0 // 소수점 제거
        return formatter.string(from: NSNumber(value: number)) ?? numberString
    }
}

/*
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView(viewModel: ExpenseViewModel(), selectedDate: Date())
    }
}
*/
