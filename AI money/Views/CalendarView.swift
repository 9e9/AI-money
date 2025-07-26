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
    let content: (Date, Bool) -> DateView

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
                    withAnimation { moveToPreviousMonth() }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }

                Button(action: {
                    withAnimation { resetToCurrentDate() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }

                Button(action: {
                    withAnimation { moveToNextMonth() }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            ZStack {
                CalendarGridView(
                    year: selectedYear,
                    month: selectedMonth,
                    selectedDate: selectedDate,
                    showHeaders: showHeaders,
                    onSelect: { date in selectedDate = date },
                    content: content
                )
                .id("\(selectedYear)-\(selectedMonth)")
                .transition(.opacity)
                .animation(.easeInOut, value: selectedYear)
                .animation(.easeInOut, value: selectedMonth)
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
    }

    private func moveToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        selectedDate = nil
    }

    private func moveToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        selectedDate = nil
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

extension Date {
    var year: Int { Calendar.current.component(.year, from: self) }
    var month: Int { Calendar.current.component(.month, from: self) }
}
