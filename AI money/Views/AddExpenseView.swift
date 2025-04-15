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
    var selectedDate: Date // 달력에서 선택한 날짜를 전달받음

    var body: some View {
        NavigationView {
            Form {
                // 선택한 날짜를 YYYY년 MM월 DD일 형식으로 표시
                HStack {
                    Text("날짜")
                        .font(.headline)
                    Spacer()
                    Text(formatDate(selectedDate))
                        .foregroundColor(.secondary)
                }

                TextField("카테고리", text: $category)

                TextField("금액", text: $amount)
                    .keyboardType(.decimalPad) // 숫자 전용 키보드
                    .onChange(of: amount) { newValue in
                        // 숫자만 입력되도록 필터링
                        amount = newValue.filter { $0.isNumber || $0 == "." }
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

    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        return formatter.string(from: date)
    }
}
/*
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseView(viewModel: ExpenseViewModel(), selectedDate: Date())
    }
}*/
