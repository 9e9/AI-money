//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseViewModel // ViewModel에서 데이터 가져오기
    
    var body: some View {
        VStack {
            Text("지출 카테고리")
                .font(.title)
                .padding()

            if viewModel.expenses.isEmpty {
                Text("지출 데이터가 없습니다.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                PieChartView(expenses: groupedExpenses())
                    .frame(height: 300)
                    .padding()
            }
        }
    }
    
    // 카테고리별로 데이터 그룹화
    private func groupedExpenses() -> [ExpenseCategory] {
        let grouped = Dictionary(grouping: viewModel.expenses) { $0.category }
        return grouped.map { category, expenses in
            ExpenseCategory(category: category, amount: expenses.reduce(0) { $0 + $1.amount })
        }
    }
}

struct PieChartView: View {
    let expenses: [ExpenseCategory]
    var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(expenses.indices, id: \.self) { index in
                    PieSliceView(geometry: geometry, index: index, expenses: expenses, total: total)
                }
            }
        }
    }
}

struct PieSliceView: View {
    let geometry: GeometryProxy
    let index: Int
    let expenses: [ExpenseCategory]
    let total: Double
    
    private var startAngle: Double {
        let previousSlices = expenses[..<index].reduce(0) { $0 + $1.amount }
        return (previousSlices / total) * 360
    }
    
    private var endAngle: Double {
        let currentSlices = expenses[...index].reduce(0) { $0 + $1.amount }
        return (currentSlices / total) * 360
    }
    
    var body: some View {
        let sliceColor: Color = Color(hue: Double(index) / Double(expenses.count), saturation: 0.7, brightness: 0.9)
        
        Path { path in
            path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
            path.addArc(
                center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                radius: min(geometry.size.width, geometry.size.height) / 2,
                startAngle: Angle(degrees: startAngle),
                endAngle: Angle(degrees: endAngle),
                clockwise: false
            )
        }
        .fill(sliceColor)
        .overlay(
            Text(expenses[index].category)
                .foregroundColor(.white)
                .font(.caption)
                .position(
                    CGPoint(
                        x: geometry.size.width / 2 + cos(CGFloat((startAngle + endAngle) / 2) * .pi / 180) * geometry.size.width / 4,
                        y: geometry.size.height / 2 + sin(CGFloat((startAngle + endAngle) / 2) * .pi / 180) * geometry.size.height / 4
                    )
                )
        )
    }
}

// 데이터 모델
struct ExpenseCategory {
    let category: String
    let amount: Double
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        // 샘플 데이터 추가
        let viewModel = ExpenseViewModel()
        viewModel.addExpense(Expense(date: Date(), category: "식비", amount: 30000, note: "점심 식사"))
        viewModel.addExpense(Expense(date: Date(), category: "교통비", amount: 20000, note: "지하철"))
        viewModel.addExpense(Expense(date: Date(), category: "식비", amount: 15000, note: "저녁 식사"))
        
        return ChartView(viewModel: viewModel)
    }
}
