//
//  CalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct CalendarView<DateView>: View where DateView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.calendar) var calendar
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let showHeaders: Bool
    let content: (Date) -> DateView

    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    showingPicker.toggle()
                }) {
                    Text("\(formatYear(selectedYear))년 \(String(format: "%02d", selectedMonth))월")
                        .font(.title2)
                        .foregroundColor(.black)
                }

                Spacer()

                Button(action: {
                    resetToCurrentDate()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .background(Color.white)

            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                if showHeaders {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbol(for: index))
                            .padding(.bottom, 5)
                    }
                }
                ForEach(calendar.generateDates(
                    inside: calendar.dateInterval(of: .month, for: calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth))!)!,
                    matching: DateComponents(hour: 0)
                ), id: \.self) { date in
                    content(date)
                        .padding(4)
                        .background(calendar.isDate(date, equalTo: Date(), toGranularity: .day) ? Color.blue.opacity(0.3) : Color.clear)
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
        }
        .sheet(isPresented: $showingPicker) {
            YearMonthPicker(
                viewModel: viewModel, selectedYear: $selectedYear, selectedMonth: $selectedMonth, showingPicker: $showingPicker
            )
        }
    }

    private func weekdaySymbol(for index: Int) -> String {
        switch index {
        case 0: return "일"
        case 1: return "월"
        case 2: return "화"
        case 3: return "수"
        case 4: return "목"
        case 5: return "금"
        case 6: return "토"
        default: return ""
        }
    }

    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }

    private func resetToCurrentDate() {
        let currentDate = Date()
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        selectedYear = components.year ?? selectedYear
        selectedMonth = components.month ?? selectedMonth
    }
}

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates = [interval.start]

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

struct YearMonthPicker: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showingPicker: Bool
    
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
                    .onChange(of: selectedYear) { _ in
                        updateTotalExpense()
                    }
                    
                    Picker("월 선택", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)월").tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: selectedMonth) { _ in
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
                showingPicker = false
            })
            .onAppear {
                updateTotalExpense()
            }
        }
    }
    
    private func updateTotalExpense() {
        DispatchQueue.main.async {
            print("All Expenses Before Filtering: \(viewModel.expenses)")
            print("Expenses Memory Address: \(Unmanaged.passUnretained(viewModel.expenses as AnyObject).toOpaque())")

            let filteredExpenses = viewModel.expenses.filter { expense in
                let components = Calendar.current.dateComponents([.year, .month], from: expense.date)
                return components.year == selectedYear && components.month == selectedMonth
            }

            totalExpense = filteredExpenses.reduce(0) { $0 + $1.amount }

            print("Filtered Expenses: \(filteredExpenses)")
            print("Updated Total Expense: \(totalExpense) for \(selectedYear)-\(selectedMonth)")
        }
    }
}
