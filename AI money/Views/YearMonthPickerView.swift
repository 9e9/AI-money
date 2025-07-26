//
//  YearMonthPickerView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct YearMonthPickerView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showingPicker: Bool

    var onComplete: ((Int, Int) -> Void)? = nil

    @State private var totalExpense: Double = 0
    @State private var mostSpentCategory: String = ""
    @State private var mostSpentAmount: Double = 0
    @State private var averageMonthlyExpense: Double = 0
    @State private var prevYearSameMonthExpense: Double = 0
    @State private var expenseChangeRate: Double = 0

    private let availableYears = Array(2000...2100)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                HStack(spacing: 20) {
                    VStack {
                        Text("연도")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Picker("연도 선택", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(String(format: "%d년", year))
                                    .font(.title3)
                                    .tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .onChange(of: selectedYear) { _ in
                            updateExpenseStats()
                        }
                    }
                    VStack {
                        Text("월")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Picker("월 선택", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)월")
                                    .font(.title3)
                                    .tag(month)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .onChange(of: selectedMonth) { _ in
                            updateExpenseStats()
                        }
                    }
                }
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color(.systemGray4).opacity(0.16), radius: 6, x: 0, y: 2)
                )
                .padding(.top, 20)
                
                VStack(spacing: 10) {
                    Text("총 지출")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalExpense)) 원")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                    Divider().padding(.vertical, 3)

                    if mostSpentCategory != "" {
                        HStack {
                            Text("가장 많이 쓴 카테고리")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(mostSpentCategory)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("(\(Int(mostSpentAmount)) 원)")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }

                    HStack {
                        Text("최근 3개월 평균 지출")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(averageMonthlyExpense)) 원")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("작년 같은 달 지출")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(prevYearSameMonthExpense)) 원")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("증감률(작년 동월 대비)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(expenseChangeRate >= 0 ? "+" : "")\(String(format: "%.1f", expenseChangeRate))%")
                            .font(.headline)
                            .foregroundColor(expenseChangeRate >= 0 ? .red : .blue)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray5))
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(Text("연도 및 월 선택"))
            .navigationBarItems(trailing: Button("완료") {
                onComplete?(selectedYear, selectedMonth)
                showingPicker = false
            }
            .font(.title3))
            .onAppear {
                updateExpenseStats()
            }
        }
    }
    
    private func updateExpenseStats() {
        DispatchQueue.main.async {
            let calendar = Calendar.current
            let filteredExpenses = viewModel.expenses.filter { expense in
                let components = calendar.dateComponents([.year, .month], from: expense.date)
                return components.year == selectedYear && components.month == selectedMonth
            }
            totalExpense = filteredExpenses.reduce(0) { $0 + $1.amount }

            let categoryGroups = Dictionary(grouping: filteredExpenses, by: { $0.category })
            let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } }
            if let (category, amount) = categorySums.max(by: { $0.value < $1.value }), amount > 0 {
                mostSpentCategory = category
                mostSpentAmount = amount
            } else {
                mostSpentCategory = ""
                mostSpentAmount = 0
            }

            var lastThreeMonthsExpense: [Double] = []
            for offset in 0..<3 {
                let targetDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth))!
                let targetMonth = calendar.date(byAdding: .month, value: -offset, to: targetDate)!
                let y = calendar.component(.year, from: targetMonth)
                let m = calendar.component(.month, from: targetMonth)
                let expenses = viewModel.expenses.filter { expense in
                    let comp = calendar.dateComponents([.year, .month], from: expense.date)
                    return comp.year == y && comp.month == m
                }
                lastThreeMonthsExpense.append(expenses.reduce(0) { $0 + $1.amount })
            }
            averageMonthlyExpense = lastThreeMonthsExpense.isEmpty ? 0 : lastThreeMonthsExpense.reduce(0, +) / Double(lastThreeMonthsExpense.count)

            let prevYearExpenses = viewModel.expenses.filter { expense in
                let comp = calendar.dateComponents([.year, .month], from: expense.date)
                return comp.year == selectedYear - 1 && comp.month == selectedMonth
            }
            prevYearSameMonthExpense = prevYearExpenses.reduce(0) { $0 + $1.amount }

            if prevYearSameMonthExpense > 0 {
                expenseChangeRate = ((totalExpense - prevYearSameMonthExpense) / prevYearSameMonthExpense) * 100
            } else {
                expenseChangeRate = totalExpense > 0 ? 100 : 0
            }
        }
    }
}
