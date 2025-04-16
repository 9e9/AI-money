//
//  ExpenseListView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseListView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("연도", selection: $selectedYear) {
                        ForEach(yearRange, id: \.self) { year in
                            Text("\(year)년").tag(year)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("월", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)월").tag(month)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()

                Text("총 지출: \(totalExpenseForSelectedMonth(), specifier: "%.2f") 원")
                    .font(.title2)
                    .padding(.bottom, 10)
                
                if filteredExpenses.isEmpty {
                    Text("해당 월에 지출 내역이 없습니다.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(filteredExpenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.category)
                                    .font(.headline)
                                Text(expense.note)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(expense.amount, specifier: "%.2f") 원")
                                .font(.headline)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("월별 지출 내역")
        }
    }

    private var filteredExpenses: [Expense] {
        viewModel.expenses.filter { expense in
            let components = Calendar.current.dateComponents([.year, .month], from: expense.date)
            return components.year == selectedYear && components.month == selectedMonth
        }
    }

    private func totalExpenseForSelectedMonth() -> Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear)
    }
}
