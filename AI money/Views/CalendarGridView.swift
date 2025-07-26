//
//  CalendarGridView.swift
//  AI money
//
//  Created by 조준희 on 7/26/25.
//

import SwiftUI

struct CalendarGridView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    let year: Int
    let month: Int
    let selectedDate: Date?
    let showHeaders: Bool
    let onSelect: (Date) -> Void
    let content: (Date, Bool) -> DateView

    private var days: [(date: Date, isInCurrentMonth: Bool)] {
        let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonthDate)!.count

        var result: [(Date, Bool)] = []
        for i in stride(from: weekdayOfFirst - 2, through: 0, by: -1) {
            let d = calendar.date(from: DateComponents(year: prevMonthDate.year, month: prevMonthDate.month, day: daysInPrevMonth - i))!
            result.append((d, false))
        }
        for day in 1...daysInMonth {
            let d = calendar.date(from: DateComponents(year: year, month: month, day: day))!
            result.append((d, true))
        }
        let rest = (result.count % 7 == 0) ? 0 : (7 - (result.count % 7))
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
        if rest > 0 {
            for day in 1...rest {
                let d = calendar.date(from: DateComponents(year: nextMonthDate.year, month: nextMonthDate.month, day: day))!
                result.append((d, false))
            }
        }
        while result.count < 42 {
            let day = result.count - (daysInMonth + weekdayOfFirst - 1) + 1
            let d = calendar.date(from: DateComponents(year: nextMonthDate.year, month: nextMonthDate.month, day: day))!
            result.append((d, false))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            if showHeaders {
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbol(for: index))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(index == 0 ? .red : (index == 6 ? .blue : .primary))
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(days.indices, id: \.self) { idx in
                    let day = days[idx]
                    if day.isInCurrentMonth {
                        Button(action: {
                            onSelect(day.date)
                        }) {
                            content(day.date, true)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(
                                    selectedDate != nil && calendar.isDate(day.date, equalTo: selectedDate!, toGranularity: .day)
                                    ? Color.blue.opacity(0.2)
                                    : Color.clear
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        content(day.date, false)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .opacity(0.4)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 8)
        .shadow(color: Color(.systemGray4).opacity(0.12), radius: 4, x: 0, y: 2)
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
}
