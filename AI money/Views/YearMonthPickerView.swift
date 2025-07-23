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
    
    private let availableYears = Array(2000...2100)
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("연도 선택", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(format: "%d년", year)).tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedYear) {
                        updateTotalExpense()
                    }
                    
                    Picker("월 선택", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)월").tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedMonth) {
                        updateTotalExpense()
                    }
                }
                .padding()

                VStack {
                    Text("총 지출: \(Int(totalExpense)) 원")
                        .font(.title2)
                        .padding(.top, 20)
                }
                
                Spacer()
            }
            .navigationTitle("연도 및 월 선택")
            .navigationBarItems(trailing: Button("완료") {
                onComplete?(selectedYear, selectedMonth)
                showingPicker = false
            })
            .onAppear {
                updateTotalExpense()
            }
        }
    }
    
    private func updateTotalExpense() {
        DispatchQueue.main.async {
            let filteredExpenses = viewModel.expenses.filter { expense in
                let components = Calendar.current.dateComponents([.year, .month], from: expense.date)
                return components.year == selectedYear && components.month == selectedMonth
            }

            totalExpense = filteredExpenses.reduce(0) { $0 + $1.amount }
        }
    }
}
