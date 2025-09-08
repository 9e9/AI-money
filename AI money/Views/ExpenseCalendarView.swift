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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                calendarHeaderSection
                
                calendarSection
                    .padding(.horizontal, 20)
                
                expenseListSection
                    .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar { toolbarContent }
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
                        withAnimation(.easeInOut(duration: CalendarAnimationConfiguration.expenseListAnimationDuration)) {
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
    }
    
    private var calendarHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    showingPicker.toggle()
                }) {
                    Text("\(String(viewModel.selectedYear))년 \(String(format: "%02d", viewModel.selectedMonth))월")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: CalendarAnimationConfiguration.monthTransitionDuration)) {
                            viewModel.moveToPreviousMonth()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: CalendarAnimationConfiguration.monthTransitionDuration)) {
                            viewModel.resetToCurrentDate()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: CalendarAnimationConfiguration.monthTransitionDuration)) {
                            viewModel.moveToNextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            if viewModel.monthlyTotal > 0 {
                HStack {
                    Text("이번 달 총 지출")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formatAmount(viewModel.monthlyTotal))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var calendarSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(CalendarConfiguration.weekdaySymbols[index])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(index == 0 ? .red : (index == 6 ? .blue : .secondary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(viewModel.calendarDays.indices, id: \.self) { index in
                    let day = viewModel.calendarDays[index]
                    CalendarDayView(
                        day: day,
                        isSelected: viewModel.calendarState.selectedDate != nil &&
                            Calendar.current.isDate(day.date, equalTo: viewModel.calendarState.selectedDate!, toGranularity: .day),
                        onTap: {
                            withAnimation(.easeInOut(duration: CalendarAnimationConfiguration.selectionAnimationDuration)) {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var expenseListSection: some View {
        VStack(spacing: 0) {
            switch viewModel.calendarState {
            case .noDateSelected:
                emptyStateView(
                    title: "날짜를 선택하세요",
                    subtitle: "캘린더에서 날짜를 탭하여 지출 내역을 확인하세요"
                )
                
            case .dateSelectedWithoutExpenses(let date):
                emptyStateView(
                    title: "지출 내역 없음",
                    subtitle: "\(formatSelectedDate(date))에는 지출이 없습니다"
                )
                
            case .dateSelectedWithExpenses(let summary):
                expenseListView(summary: summary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func emptyStateView(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
    
    private func expenseListView(summary: DailyExpenseSummary) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatSelectedDate(summary.date))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("총 \(viewModel.formatAmount(summary.totalAmount))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(summary.expenses.count)개 항목")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(summary.expenses) { expense in
                        ExpenseRowView(
                            data: ExpenseCardData(expense: expense),
                            onDelete: {
                                expenseToDelete = expense
                                showingDeleteAlert = true
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .transition(.opacity)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button(action: {
                showInformationView = true
            }) {
                Text("AI money")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showingAddExpense = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일 EEEE"
        return formatter.string(from: date)
    }
}

struct CalendarDayView: View {
    let day: CalendarDay
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(day.dayNumber)")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(
                        isSelected ? .white :
                        (day.isInCurrentMonth ? .primary : .secondary)
                    )
                
                if day.hasExpense && day.isInCurrentMonth {
                    Circle()
                        .fill(isSelected ? Color.white : Color.blue)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 40, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.black : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!day.isInCurrentMonth)
    }
}

struct ExpenseRowView: View {
    let data: ExpenseCardData
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.expense.category)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(data.formattedAmount)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if data.hasNote {
                        Text("• \(data.expense.note)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
