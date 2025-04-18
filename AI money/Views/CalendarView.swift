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
            YearMonthPickerView(
                viewModel: viewModel,
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                showingPicker: $showingPicker
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
