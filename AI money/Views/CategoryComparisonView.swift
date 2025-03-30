//
//  CategoryComparisonView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts

struct CategoryComparisonView: View {
    let aiManager = ExpenseAIManager()
    @State private var categoryChanges: [(category: ExpenseCategory, change: Double)] = []

    var body: some View {
        VStack {
            Text("카테고리별 소비 변화 📈")
                .font(.title)
                .bold()
                .padding()

            Chart(categoryChanges, id: \.category) { data in
                BarMark(
                    x: .value("카테고리", data.category.rawValue),
                    y: .value("변화율 (%)", data.change)
                )
                .foregroundStyle(data.change >= 0 ? .red : .blue)
            }
            .padding()
            .frame(height: 300)

            Spacer()
        }
        .onAppear {
            categoryChanges = aiManager.getCategoryComparison()
        }
    }
}
