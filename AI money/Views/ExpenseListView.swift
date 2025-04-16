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
                // 연도와 월 선택
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
                
                // 월별 총 지출 표시
                Text("총 지출: \(totalExpenseForSelectedMonth(), specifier: "%.2f") 원")
                    .font(.title2)
                    .padding(.bottom, 10)
                
                // 지출 내역 리스트
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
    
    // 해당 월의 지출 필터링
    private var filteredExpenses: [Expense] {
        viewModel.expenses.filter { expense in
            let components = Calendar.current.dateComponents([.year, .month], from: expense.date)
            return components.year == selectedYear && components.month == selectedMonth
        }
    }
    
    // 월별 총 지출 계산
    private func totalExpenseForSelectedMonth() -> Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 연도 범위
    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear) // 최근 5년 범위
    }
}
