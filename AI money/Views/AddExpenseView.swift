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
                dateSection
                categoryPicker
                amountInput
                noteInput
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: saveExpense)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: cancelExpense)
                }
            }
            .alert("금액을 입력하세요", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("지출 금액을 입력해야 저장할 수 있습니다.")
            }
        }
    }

    private var dateSection: some View {
        HStack {
            Text("날짜")
            Spacer()
            Text(Self.formatDate(selectedDate))
                .foregroundColor(.secondary)
        }
    }

    private var categoryPicker: some View {
        Picker("카테고리", selection: $selectedCategory) {
            ForEach(categories, id: \.self) { category in
                Text(category)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }

    private var amountInput: some View {
        HStack {
            Text("금액")
            Spacer()
            HStack {
                TextField("금액 입력(필수)", text: $formattedAmount)
                    .keyboardType(.decimalPad)
                    .onChange(of: formattedAmount, perform: updateAmount)
                    .multilineTextAlignment(.trailing)
                if !formattedAmount.isEmpty {
                    Text("원").foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 200)
        }
    }

    private var noteInput: some View {
        HStack {
            Text("메모")
            Spacer()
            TextField("선택 사항", text: $note)
                .multilineTextAlignment(.trailing)
        }
    }

    private func saveExpense() {
        guard let expenseAmount = Double(amount), expenseAmount > 0 else {
            showingAlert = true
            return
        }

        let newExpense = Expense(
            date: selectedDate,
            category: selectedCategory,
            amount: expenseAmount,
            note: note
        )

        viewModel.addExpense(newExpense)
        presentationMode.wrappedValue.dismiss()
    }

    private func cancelExpense() {
        presentationMode.wrappedValue.dismiss()
    }

    private func updateAmount(_ newValue: String) {
        amount = newValue.filter { $0.isNumber }
        formattedAmount = Self.formatWithComma(amount)
    }

    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private static func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        return numberFormatter.string(from: NSNumber(value: number)) ?? numberString
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        return formatter
    }()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
