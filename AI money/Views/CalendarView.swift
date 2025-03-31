//
//  CalenderView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct CalendarView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    let interval: DateInterval
    let showHeaders: Bool
    let content: (Date) -> DateView

    init(
        interval: DateInterval,
        showHeaders: Bool = true,
        @ViewBuilder content: @escaping (Date) -> DateView
    ) {
        self.interval = interval
        self.showHeaders = showHeaders
        self.content = content
    }

    var body: some View {
        let month = calendar.dateInterval(of: .month, for: Date())! // 현재 달로 고정
        VStack {
            HStack {
                Text("\(calendar.component(.year, from: month.start))년 \(calendar.component(.month, from: month.start))월")
                    .font(.title)
                    .padding(.horizontal)
                    .padding(.top, 10)
                Spacer()
            }
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                if showHeaders {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbol(for: index))
                            .padding(.bottom, 5)
                    }
                }
                ForEach(calendar.generateDates(inside: month, matching: DateComponents(hour: 0)), id: \.self) { date in
                    content(date)
                        .padding(4)
                        .background(calendar.isDate(date, equalTo: Date(), toGranularity: .day) ? Color.blue.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                        .frame(maxWidth: .infinity)
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

extension Date {
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
}
