//
//  CategoryChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts

struct CategoryChartView: View {
    let aiManager = ExpenseAIManager()
    @State private var categoryData: [(category: ExpenseCategory, amount: Double)] = []

    var body: some View {
        VStack {
            Text("카테고리별 소비 분석 📊")
                .font(.title)
                .bold()
                .padding()

            Chart(categoryData, id: \.category) { data in
                SectorMark(
                    angle: .value("소비 금액", data.amount),
                    innerRadius: .ratio(0.5)
                )
                .foregroundStyle(by: .value("카테고리", data.category.rawValue))
            }
            .padding()
            .frame(height: 300)

            Spacer()
        }
        .onAppear {
            let categoryExpenses = aiManager.getCategoryExpenses()
            categoryData = categoryExpenses.map { ($0.key, $0.value) }
        }
    }
}
