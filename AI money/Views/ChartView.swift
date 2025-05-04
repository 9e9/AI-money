//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var sortOrder: SortOrder = .defaultOrder
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var isShowingYearMonthPicker = false

    enum SortOrder: String, CaseIterable, Identifiable {
        case defaultOrder = "기본순"
        case highToLow = "높은 순"
        case lowToHigh = "낮은 순"

        var id: String { self.rawValue }
    }

    private var allCategories: [String] {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        return predefinedCategories + viewModel.customCategories
    }

    private var filteredExpenses: [Expense] {
        viewModel.expenses.filter { expense in
            let expenseDate = Calendar.current.dateComponents([.year, .month], from: expense.date)
            return expenseDate.year == selectedYear && expenseDate.month == selectedMonth
        }
    }

    private var sortedCategoryTotals: [(String, Double)] {
        let totals = filteredExpenses.reduce(into: [String: Double]()) { result, expense in
            result[expense.category, default: 0.0] += expense.amount
        }

        let completeTotals = allCategories.reduce(into: [String: Double]()) { result, category in
            result[category] = totals[category, default: 0.0]
        }

        let sorted: [(String, Double)]
        switch sortOrder {
        case .highToLow:
            sorted = completeTotals.sorted { $0.value > $1.value }
        case .lowToHigh:
            sorted = completeTotals.sorted { $0.value < $1.value }
        case .defaultOrder:
            sorted = completeTotals.sorted { $0.key < $1.key }
        }
        return sorted
    }

    var body: some View {
        VStack {
            Text("원형 차트")
                .font(.headline)

            if filteredExpenses.isEmpty {
                DottedPieChartView()
                    .frame(height: 200)
            } else {
                PieChartView(data: Dictionary(uniqueKeysWithValues: sortedCategoryTotals))
                    .frame(height: 200)
            }

            Divider()
                .padding(.vertical, 10)

            HStack {
                Text("카테고리별 총 지출")
                    .font(.headline)

                Spacer()

                Menu {
                    Button(action: { sortOrder = .defaultOrder }) {
                        Label("기본순", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { sortOrder = .highToLow }) {
                        Label("높은 순", systemImage: "arrow.down")
                    }
                    Button(action: { sortOrder = .lowToHigh }) {
                        Label("낮은 순", systemImage: "arrow.up")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal)

            Button(action: {
                isShowingYearMonthPicker = true
            }) {
                Text("\(selectedYear)년 \(selectedMonth)월")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            .sheet(isPresented: $isShowingYearMonthPicker) {
                YearMonthPickerView(
                    viewModel: viewModel,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth,
                    showingPicker: $isShowingYearMonthPicker
                )
            }

            List {
                ForEach(sortedCategoryTotals, id: \.0) { category, total in
                    HStack {
                        Text(category)
                            .font(.body)
                        Spacer()
                        Text("\(Int(total)) 원")
                            .fontWeight(.bold)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding()
    }
}

struct DottedPieChartView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray)
                .padding()
            Text("지출 없음")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
