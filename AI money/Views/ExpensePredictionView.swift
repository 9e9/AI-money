//
//  ExpensePredictionView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpensePredictionView: View {
    @State private var selectedDate = Date()
    @State private var selectedCategory = "Food"
    @State private var predictedAmount: Double?
    
    let predictor = ExpensePredictor()
    let aiManager = ExpenseAIManager()

    var body: some View {
        VStack {
            Text("미래 소비 예측 🔮")
                .font(.title)
                .bold()
                .padding()

            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                .padding()

            Picker("카테고리 선택", selection: $selectedCategory) {
                Text("Food").tag("Food")
                Text("Transport").tag("Transport")
                Text("Shopping").tag("Shopping")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Button("예측하기") {
                if let amount = predictor?.predictExpense(date: selectedDate, category: selectedCategory) {
                    predictedAmount = amount
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            if let predictedAmount = predictedAmount {
                Text("예상 지출: \(predictedAmount, specifier: "%.2f")원")
                    .font(.title2)
                    .bold()
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("AI 소비 예측")
        
        VStack {
            Text("예산 관리 📊")
                .font(.title)
                .bold()
                .padding()

            Button("AI 예산 분석 실행") {
                let isOverBudget = aiManager.checkBudgetWarning()
                if isOverBudget {
                    BudgetAlertManager.shared.sendBudgetWarning()
                }
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            BudgetAlertManager.shared.requestNotificationPermission()
        }
    }
}
