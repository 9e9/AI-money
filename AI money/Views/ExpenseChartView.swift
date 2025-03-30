//
//  ExpenseChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData
import Charts

struct ExpenseChartView: View {
    @Query private var expenses: [Expense]
    let aiManager = ExpenseAIManager()
        @State private var expenseData: [(date: Date, totalAmount: Double)] = []

    var body: some View {
        VStack {
            Text("소비 패턴 분석 📊")
                .font(.title)
                .bold()
                .padding()

            Chart {
                ForEach(expenses) { expense in
                    BarMark(
                        x: .value("날짜", expense.date, unit: .day),
                        y: .value("금액", expense.amount)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 300)
            .padding()
        }
        .navigationTitle("소비 패턴")
        
        VStack {
            Text("소비 패턴 분석 📊")
                .font(.title)
                .bold()
                .padding()

            Chart(expenseData, id: \.date) { data in
                LineMark(
                    x: .value("날짜", data.date),
                    y: .value("소비 금액", data.totalAmount)
                )
                .foregroundStyle(.blue)
                .symbol(Circle())
            }
            .chartYScale(domain: 0...expenseData.map { $0.totalAmount }.max() ?? 10000)
            .padding()

            Spacer()
        }
        .onAppear {
            expenseData = aiManager.getExpensesByDate()
        }
    }
}
