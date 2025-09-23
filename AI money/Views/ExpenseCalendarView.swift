//
//  ExpenseCalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseCalendarView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @State private var showingAddExpense = false
    @State private var showingDeleteAlert = false
    @State private var showInformationView = false
    @State private var showingPicker = false
    @State private var expenseToDelete: Expense? = nil
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 배경
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더 (스크롤 오프셋 추적용)
                calendarHeaderSection
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    scrollOffset = geometry.frame(in: .global).minY
                                }
                                .onChange(of: geometry.frame(in: .global).minY) { value in
                                    scrollOffset = value
                                }
                        }
                    )
                
                calendarSection
                    .padding(.horizontal, 20)
                
                expenseListSection
                    .padding(.top, 16)
            }
            
            // 상단 네비게이션 바 (스크롤 시 나타남)
            VStack {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .top)
                    
                    HStack {
                        Text("지출 내역")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: { showInformationView = true }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: { showingAddExpense = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .frame(height: 44)
                .opacity(scrollOffset < -60 ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: scrollOffset)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(
                viewModel: viewModel,
                selectedDate: viewModel.calendarState.selectedDate ?? Date()
            )
        }
        .sheet(isPresented: $showingPicker) {
            YearMonthPickerView(
                viewModel: viewModel,
                selectedYear: $viewModel.selectedYear,
                selectedMonth: $viewModel.selectedMonth,
                showingPicker: $showingPicker,
                onComplete: { year, month in
                    viewModel.updateSelectedPeriod(year: year, month: month)
                }
            )
        }
        .sheet(isPresented: $showInformationView) {
            NavigationView {
                InformationView()
            }
        }
        .alert("지출 삭제", isPresented: $showingDeleteAlert) {
            Button("삭제", role: .destructive) {
                if let expense = expenseToDelete {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.removeExpense(expense)
                    }
                }
            }
            Button("취소", role: .cancel) {
                expenseToDelete = nil
            }
        } message: {
            Text("이 지출 내역을 삭제하시겠습니까?")
        }
    }
    
    // MARK: - Header Section
    private var calendarHeaderSection: some View {
        VStack(spacing: 20) {
            // 상단 타이틀과 버튼들
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("지출 내역")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Button(action: { showingPicker.toggle() }) {
                        HStack(spacing: 6) {
                            Text("\(String(viewModel.selectedYear))년 \(String(format: "%02d", viewModel.selectedMonth))월")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showInformationView = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.blue))
                    }
                }
            }
            
            // 월 네비게이션과 총액
            HStack {
                // 월 네비게이션 버튼들
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.moveToPreviousMonth()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.resetToCurrentDate()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.moveToNextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                }
                
                Spacer()
                
                // 총 지출 표시
                if viewModel.monthlyTotal > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("이번 달 총 지출")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formatAmount(viewModel.monthlyTotal))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: 12) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(CalendarConfiguration.weekdaySymbols[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(index == 0 ? .red : (index == 6 ? .blue : .secondary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            // 캘린더 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(viewModel.calendarDays.indices, id: \.self) { index in
                    let day = viewModel.calendarDays[index]
                    ModernCalendarDayView(
                        day: day,
                        isSelected: viewModel.calendarState.selectedDate != nil &&
                            Calendar.current.isDate(day.date, equalTo: viewModel.calendarState.selectedDate!, toGranularity: .day),
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if let selectedDate = viewModel.calendarState.selectedDate,
                                   Calendar.current.isDate(selectedDate, inSameDayAs: day.date) {
                                    viewModel.selectDate(nil)
                                } else {
                                    viewModel.selectDate(day.date)
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Expense List Section
    private var expenseListSection: some View {
        VStack(spacing: 0) {
            switch viewModel.calendarState {
            case .noDateSelected:
                modernEmptyStateView(
                    icon: "calendar",
                    title: "날짜를 선택하세요",
                    subtitle: "캘린더에서 날짜를 탭하여\n지출 내역을 확인하세요"
                )
                
            case .dateSelectedWithoutExpenses(let date, let holiday):
                modernEmptyStateViewWithHoliday(
                    date: date,
                    holiday: holiday
                )
                
            case .dateSelectedWithExpenses(let summary):
                modernExpenseListView(summary: summary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Modern Empty State Views
    private func modernEmptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
    
    private func modernEmptyStateViewWithHoliday(date: Date, holiday: KoreanHoliday?) -> some View {
        VStack(spacing: 20) {
            if let holiday = holiday {
                VStack(spacing: 16) {
                    // 공휴일 아이콘
                    ZStack {
                        Circle()
                            .fill(getHolidayColor(for: holiday.type).opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(getHolidayColor(for: holiday.type))
                    }
                    
                    VStack(spacing: 8) {
                        Text(holiday.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(formatSelectedDate(date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("휴일이에요 🎉")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                modernEmptyStateView(
                    icon: "tray",
                    title: "지출 내역 없음",
                    subtitle: "\(formatSelectedDate(date))에는\n지출이 없습니다"
                )
            }
        }
        .transition(.opacity)
    }
    
    private func modernExpenseListView(summary: DailyExpenseSummary) -> some View {
        VStack(spacing: 0) {
            // 날짜 헤더
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(formatSelectedDate(summary.date))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // 공휴일 태그
                        if let holiday = summary.holiday {
                            Text(holiday.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(getHolidayColor(for: holiday.type))
                                )
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Text("총 \(viewModel.formatAmount(summary.totalAmount))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("\(summary.expenses.count)개 항목")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.5))
            
            // 지출 리스트
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(summary.expenses) { expense in
                        ModernExpenseRowView(
                            data: ExpenseCardData(expense: expense),
                            onDelete: {
                                expenseToDelete = expense
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Helper Methods
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일 EEEE"
        return formatter.string(from: date)
    }

    private func getHolidayColor(for type: HolidayType) -> Color {
        switch type {
        case .national, .traditional: return .red
        case .memorial: return .orange
        case .substitute: return .blue
        }
    }
    
    private func getHolidayTypeDescription(for type: HolidayType) -> String {
        switch type {
        case .national: return "국경일"
        case .traditional: return "전통 명절"
        case .memorial: return "기념일"
        case .substitute: return "대체공휴일"
        }
    }
}

// MARK: - Modern Calendar Day View
struct ModernCalendarDayView: View {
    let day: CalendarDay
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(day.dayNumber)")
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(dayTextColor)
                
                // 인디케이터
                HStack(spacing: 3) {
                    if day.hasExpense && day.isInCurrentMonth {
                        Circle()
                            .fill(isSelected ? Color.white : Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    
                    if day.isHoliday && day.isInCurrentMonth {
                        Circle()
                            .fill(isSelected ? Color.white : holidayDotColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(width: 36, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(dayBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!day.isInCurrentMonth)
    }
    
    private var dayTextColor: Color {
        if isSelected {
            return .white
        } else if day.isHoliday && day.isInCurrentMonth {
            return holidayTextColor
        } else if day.isInCurrentMonth {
            return .primary
        } else {
            return .secondary.opacity(0.5)
        }
    }
    
    private var dayBackgroundColor: Color {
        if isSelected {
            return .primary
        } else if day.isHoliday && day.isInCurrentMonth {
            return holidayTextColor.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var holidayTextColor: Color {
        guard let holiday = day.holiday else { return .primary }
        switch holiday.type {
        case .national, .traditional: return .red
        case .memorial: return .orange
        case .substitute: return .blue
        }
    }
    
    private var holidayDotColor: Color {
        guard let holiday = day.holiday else { return .clear }
        switch holiday.type {
        case .national, .traditional: return .red
        case .memorial: return .orange
        case .substitute: return .blue
        }
    }
}

// MARK: - Modern Expense Row View
struct ModernExpenseRowView: View {
    let data: ExpenseCardData
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 카테고리 아이콘
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(categoryColor)
            }
            
            // 지출 정보
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(data.expense.category)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(data.formattedAmount)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                if data.hasNote {
                    Text(data.expense.note)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // 삭제 버튼
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var categoryColor: Color {
        switch data.expense.category {
        case "식비": return .red
        case "교통": return .blue
        case "쇼핑": return .green
        case "여가": return .orange
        case "기타": return .purple
        default: return .gray
        }
    }
    
    private var categoryIcon: String {
        switch data.expense.category {
        case "식비": return "fork.knife"
        case "교통": return "car.fill"
        case "쇼핑": return "bag.fill"
        case "여가": return "gamecontroller.fill"
        case "기타": return "ellipsis"
        default: return "questionmark"
        }
    }
}
