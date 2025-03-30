//
//  Untitled.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData
import SwiftUI

struct BudgetSettingView: View {
    @Environment(\.modelContext) private var context
    @Query private var budgets: [Budget]

    @State private var selectedCategory: ExpenseCategory = .food
    @State private var budgetAmount: String = ""

    var body: some View {
        VStack {
            Text("카테고리별 예산 설정 💰")
                .font(.title)
                .bold()
                .padding()

            Picker("카테고리 선택", selection: $selectedCategory) {
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            TextField("예산 금액 입력", text: $budgetAmount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("예산 저장") {
                if let amount = Double(budgetAmount) {
                    let newBudget = Budget(category: selectedCategory, limit: amount)
                    context.insert(newBudget)
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
    }
}
