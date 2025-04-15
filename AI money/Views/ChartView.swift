//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseViewModel

    // 카테고리별 총합 계산
    private var categoryTotals: [String: Double] {
        viewModel.expenses.reduce(into: [String: Double]()) { result, expense in
            result[expense.category, default: 0.0] += expense.amount
        }
    }

    var body: some View {
        VStack {
            Text("원형 차트")
                .font(.headline)

            // 원형 그래프 (예: Swift Charts 라이브러리 사용)
            PieChartView(data: categoryTotals)

            Divider()
                .padding(.vertical, 10)

            Text("카테고리별 총 지출")
                .font(.headline)

            // 카테고리별 총 지출 목록
            List {
                ForEach(categoryTotals.keys.sorted(), id: \.self) { category in
                    HStack {
                        Text(category)
                            .font(.body)
                        Spacer()
                        Text("\(Int(categoryTotals[category]!)) 원") // 소수점 제거
                            .fontWeight(.bold)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding()
    }
}

// 원형 차트 컴포넌트 (Swift Charts 예제)
struct PieChartView: View {
    let data: [String: Double]

    var body: some View {
        Chart {
            ForEach(data.keys.sorted(), id: \.self) { category in
                SectorMark(
                    angle: .value("Amount", data[category] ?? 0.0),
                    innerRadius: .ratio(0.5),
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(by: .value("Category", category))
            }
        }
        .frame(height: 200)
    }
}
