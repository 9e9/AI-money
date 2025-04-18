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
    @State private var selectedCategory = "기타"
    @State private var amount = ""
    @State private var formattedAmount = ""
    @State private var note = ""
    @State private var showingAlert = false
    var selectedDate: Date

    let categories = ["식비", "교통", "쇼핑", "여가", "기타"]

    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("날짜")
                    Spacer()
                    Text(formatDate(selectedDate))
                        .foregroundColor(.secondary)
                }

                Picker("카테고리", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                HStack {
                    Text("금액")
                    Spacer()
                    HStack {
                        TextField("금액 입력(필수)", text: $formattedAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: formattedAmount) {
                                amount = formattedAmount.filter { $0.isNumber }
                                formattedAmount = formatWithComma(amount)
                            }
                            .multilineTextAlignment(.trailing)
                        if !formattedAmount.isEmpty {
                            Text("원")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: 200)
                }

                HStack {
                    Text("메모")
                    Spacer()
                    TextField("선택 사항", text: $note)
                        .multilineTextAlignment(.trailing)
                }
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        if amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0 {
                            showingAlert = true
                        } else {
                            let newExpense = Expense(
                                date: selectedDate,
                                category: selectedCategory,
                                amount: Double(amount) ?? 0.0,
                                note: note
                            )
                            viewModel.addExpense(newExpense)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("금액을 입력하세요", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("지출 금액을 입력해야 저장할 수 있습니다.")
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
