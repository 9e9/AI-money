//
//  chartView.swift
//  AI money
//
//  Created by 조준희 on 3/22/25.
//

import SwiftUI
import SwiftData
import Charts

struct CategorySpending: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

struct ChartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var expenses: [Expense]
    @State var expenseViewModel = ExpenseViewModel()

    var categorySpendings: [CategorySpending] {
        var spendingByCategory: [String: Double] = [:]
        for expense in expenses {
            if let category = expense.category {
                spendingByCategory[category.name, default: 0] += expense.amount
            } else {
                spendingByCategory["미분류", default: 0] += expense.amount
            }
        }
        return spendingByCategory.map { CategorySpending(category: $0.key, amount: $0.value) }
    }

    var body: some View {
        NavigationView {
            VStack { // VStack으로 묶기
                Chart {
                    ForEach(categorySpendings) { spending in
                        BarMark(
                            x: .value("카테고리", spending.category),
                            y: .value("금액", spending.amount)
                        )
                    }
                }
                .navigationTitle("카테고리별 소비")

                Divider()

                Text("다음 달 예상 지출액: \(expenseViewModel.predictNextMonthSpending(modelContext: modelContext), specifier: "%.0f") 원")
                    .font(.headline)
                    .padding()
            }
        }
    }
}
