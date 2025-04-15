//
//  CalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct CalendarView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    let showHeaders: Bool
    let content: (Date) -> DateView

    @Binding var selectedYear: Int  // 사용자가 선택한 연도
    @Binding var selectedMonth: Int // 사용자가 선택한 월

    @State private var isPickerVisible = false // Picker 표시 여부

    init(
        selectedYear: Binding<Int>,
        selectedMonth: Binding<Int>,
        showHeaders: Bool = true,
        @ViewBuilder content: @escaping (Date) -> DateView
    ) {
        self._selectedYear = selectedYear
        self._selectedMonth = selectedMonth
        self.showHeaders = showHeaders
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // 연도와 월 표시 UI (고정된 위치)
            HStack {
                Text("\(selectedYear)년 \(selectedMonth)월")
                    .font(.title)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isPickerVisible.toggle() // Picker 열기/닫기
                        }
                    }
                Spacer()
            }

            // Picker가 열리면 아래로 밀려 내려가는 UI
            if isPickerVisible {
                VStack {
                    HStack {
                        Picker("연도", selection: $selectedYear) {
                            ForEach(2000...2100, id: \.self) { year in
                                Text("\(year)년").tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 150)
                        .clipped()

                        Picker("월", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)월").tag(month)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                        .clipped()
                    }

                    Button(action: {
                        withAnimation(.easeInOut) {
                            isPickerVisible = false // Picker 닫기
                        }
                    }) {
                        Text("확인")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 10)
                }
                .transition(.move(edge: .top)) // Picker가 아래로 열린다
                .padding(.top, 10)
            }

            // 캘린더 그리드
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                if showHeaders {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbol(for: index))
                            .padding(.bottom, 5)
                    }
                }
                ForEach(calendar.generateDates(inside: calendar.dateInterval(of: .month, for: calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth))!)!, matching: DateComponents(hour: 0)), id: \.self) { date in
                    content(date)
                        .padding(4)
                        .background(calendar.isDate(date, equalTo: Date(), toGranularity: .day) ? Color.blue.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                        .frame(maxWidth: .infinity)
                }
            }
            .opacity(isPickerVisible ? 0.3 : 1) // Picker가 열릴 때 캘린더 투명도 낮춤
            .disabled(isPickerVisible) // Picker가 열리면 캘린더와 상호작용 비활성화
            .padding(.top, isPickerVisible ? 20 : 0) // Picker가 열리면 아래로 이동
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

// Calendar Extension for Date Generation
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
