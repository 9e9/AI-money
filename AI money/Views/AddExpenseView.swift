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
    @State private var selectedCategory = "기타" // 기본 선택값
    @State private var amount = ""
    @State private var formattedAmount = ""
    var selectedDate: Date

    // 사전에 정의된 카테고리 목록
    let categories = ["식비", "교통", "쇼핑", "여가", "기타"]

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

                Picker("카테고리", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle()) // 드롭다운 스타일

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
                        let newExpense = Expense(date: selectedDate, category: selectedCategory, amount: Double(amount) ?? 0.0, note: "")
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
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? numberString
    }
}
