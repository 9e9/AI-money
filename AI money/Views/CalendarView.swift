//
//  CalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct CalendarView<DateView>: View where DateView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @Environment(\.calendar) var calendar
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var selectedDate: Date?
    let showHeaders: Bool
    let content: (Date) -> DateView

    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 10) {
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
                    withAnimation {
                        resetToCurrentDate()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            ZStack {
                calendarGrid
                    .id("\(selectedYear)-\(selectedMonth)")
                    .transition(.opacity)
            }
            .animation(.easeInOut, value: selectedYear)
            .animation(.easeInOut, value: selectedMonth)

            .sheet(isPresented: $showingPicker) {
                YearMonthPickerView(
                    viewModel: viewModel,
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth,
                    showingPicker: $showingPicker
                )
            }
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                if showHeaders {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbol(for: index))
                            .padding(.bottom, 5)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                let firstOfMonth = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
                let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
                let emptySlots = weekdayOfFirst - 1
                let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

                ForEach(0..<emptySlots, id: \.self) { i in
                    Text("")
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Color.clear)
                        .id("empty-\(i)")
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: day))!
                    content(date)
                        .padding(4)
                        .background(
                            (selectedDate != nil && calendar.isDate(date, equalTo: selectedDate!, toGranularity: .day)) ?
                                Color.blue.opacity(0.3) : Color.clear
                        )
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                        .id("day-\(day)")
                }
            }
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
        selectedDate = currentDate
    }
}
