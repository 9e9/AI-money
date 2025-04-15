//
//  CalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct CalendarView<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let showHeaders: Bool
    let content: (Date) -> DateView

    @State private var showingPicker = false // Picker Sheet 표시 여부 상태

    var body: some View {
        VStack(spacing: 0) {
            // 상단 고정된 사용자 정의된 Picker
            HStack {
                // 사용자 정의 텍스트로 Picker Sheet 표시
                Button(action: {
                    showingPicker.toggle() // Picker Sheet 표시 상태 토글
                }) {
                    Text("\(formatYear(selectedYear))년 \(String(format: "%02d", selectedMonth))월") // 선택된 연도와 월을 표시
                        .font(.title2)
                        .foregroundColor(.black) // 텍스트 색상을 검정으로 설정
                }

                Spacer() // 오른쪽에 공간 추가
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .background(Color.white)

            // 캘린더 그리드
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
                        .clipShape(Circle())
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
        }
        .sheet(isPresented: $showingPicker) { // Picker를 모달로 표시
            YearMonthPicker(selectedYear: $selectedYear, selectedMonth: $selectedMonth, showingPicker: $showingPicker)
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

    // 쉼표 없는 숫자 포맷터
    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none // 쉼표 제거
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
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
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showingPicker: Bool // Picker Sheet 표시 상태

    private let availableYears = Array(2000...2100)

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("연도 선택", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)년").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)

                    Picker("월 선택", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)월").tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("연도 및 월 선택")
            .navigationBarItems(trailing: Button("완료") {
                showingPicker = false // Picker Sheet 닫기
            })
        }
    }
}
