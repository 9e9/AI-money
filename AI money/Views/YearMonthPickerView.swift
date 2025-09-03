//
//  YearMonthPickerView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct YearMonthPickerView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showingPicker: Bool

    var onComplete: ((Int, Int) -> Void)? = nil

    @State private var totalExpense: Double = 0
    @State private var mostSpentCategory: String = ""
    @State private var mostSpentAmount: Double = 0
    @State private var averageMonthlyExpense: Double = 0
    @State private var prevYearSameMonthExpense: Double = 0
    @State private var expenseChangeRate: Double = 0
    @State private var showStats = false

    private let availableYears = Array(2000...2100)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("선택된 기간")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(selectedYear)년 \(selectedMonth)월")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        Text("기간 선택")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("연도")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                Picker("연도 선택", selection: $selectedYear) {
                                    ForEach(availableYears, id: \.self) { year in
                                        Text(String(format: "%d", year))
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .tag(year)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .clipped()
                                .onChange(of: selectedYear) { oldValue, newValue in
                                    updateExpenseStatsWithAnimation()
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.08))
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar.circle")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .medium))
                                    Text("월")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                Picker("월 선택", selection: $selectedMonth) {
                                    ForEach(1...12, id: \.self) { month in
                                        Text("\(month)")
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .tag(month)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .clipped()
                                .onChange(of: selectedMonth) { oldValue, newValue in
                                    updateExpenseStatsWithAnimation()
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green.opacity(0.08))
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 18, weight: .semibold))
                            Text("지출 분석")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            StatCard(
                                icon: "creditcard.fill",
                                iconColor: .blue,
                                title: "총 지출",
                                value: formatAmount(totalExpense),
                                subtitle: nil,
                                gradientColors: [.blue.opacity(0.1), .blue.opacity(0.05)]
                            )
                            
                            if !mostSpentCategory.isEmpty {
                                StatCard(
                                    icon: "star.fill",
                                    iconColor: .orange,
                                    title: "최다 지출 카테고리",
                                    value: mostSpentCategory,
                                    subtitle: formatAmount(mostSpentAmount),
                                    gradientColors: [.orange.opacity(0.1), .orange.opacity(0.05)]
                                )
                            }
                            
                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "chart.line.uptrend.xyaxis",
                                    iconColor: .green,
                                    title: "3개월 평균",
                                    value: formatAmount(averageMonthlyExpense),
                                    subtitle: nil,
                                    gradientColors: [.green.opacity(0.1), .green.opacity(0.05)],
                                    isCompact: true
                                )
                                
                                StatCard(
                                    icon: "clock.arrow.circlepath",
                                    iconColor: .purple,
                                    title: "작년 동월",
                                    value: formatAmount(prevYearSameMonthExpense),
                                    subtitle: nil,
                                    gradientColors: [.purple.opacity(0.1), .purple.opacity(0.05)],
                                    isCompact: true
                                )
                            }
                            
                            if prevYearSameMonthExpense > 0 {
                                StatCard(
                                    icon: expenseChangeRate >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                                    iconColor: expenseChangeRate >= 0 ? .red : .mint,
                                    title: "작년 동월 대비",
                                    value: "\(expenseChangeRate >= 0 ? "+" : "")\(String(format: "%.1f", expenseChangeRate))%",
                                    subtitle: expenseChangeRate >= 0 ? "증가" : "감소",
                                    gradientColors: expenseChangeRate >= 0 ?
                                        [.red.opacity(0.1), .red.opacity(0.05)] :
                                        [.mint.opacity(0.1), .mint.opacity(0.05)]
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(showStats ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5), value: showStats)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("기간 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        onComplete?(selectedYear, selectedMonth)
                        showingPicker = false
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                updateExpenseStatsWithAnimation()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func updateExpenseStatsWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            showStats = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            updateExpenseStats()
            
            withAnimation(.easeIn(duration: 0.3)) {
                showStats = true
            }
        }
    }
    
    private func updateExpenseStats() {
        let calendar = Calendar.current
        let filteredExpenses = viewModel.expenses.filter { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return components.year == selectedYear && components.month == selectedMonth
        }
        totalExpense = filteredExpenses.reduce(0) { $0 + $1.amount }

        let categoryGroups = Dictionary(grouping: filteredExpenses, by: { $0.category })
        let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } }
        if let (category, amount) = categorySums.max(by: { $0.value < $1.value }), amount > 0 {
            mostSpentCategory = category
            mostSpentAmount = amount
        } else {
            mostSpentCategory = ""
            mostSpentAmount = 0
        }

        var lastThreeMonthsExpense: [Double] = []
        for offset in 0..<3 {
            let targetDate = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth))!
            let targetMonth = calendar.date(byAdding: .month, value: -offset, to: targetDate)!
            let y = calendar.component(.year, from: targetMonth)
            let m = calendar.component(.month, from: targetMonth)
            let expenses = viewModel.expenses.filter { expense in
                let comp = calendar.dateComponents([.year, .month], from: expense.date)
                return comp.year == y && comp.month == m
            }
            lastThreeMonthsExpense.append(expenses.reduce(0) { $0 + $1.amount })
        }
        averageMonthlyExpense = lastThreeMonthsExpense.isEmpty ? 0 : lastThreeMonthsExpense.reduce(0, +) / Double(lastThreeMonthsExpense.count)

        let prevYearExpenses = viewModel.expenses.filter { expense in
            let comp = calendar.dateComponents([.year, .month], from: expense.date)
            return comp.year == selectedYear - 1 && comp.month == selectedMonth
        }
        prevYearSameMonthExpense = prevYearExpenses.reduce(0) { $0 + $1.amount }

        if prevYearSameMonthExpense > 0 {
            expenseChangeRate = ((totalExpense - prevYearSameMonthExpense) / prevYearSameMonthExpense) * 100
        } else {
            expenseChangeRate = totalExpense > 0 ? 100 : 0
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedString = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return formattedString + "원"
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    let gradientColors: [Color]
    var isCompact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 16 : 20, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: isCompact ? 24 : 28, height: isCompact ? 24 : 28)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                    )
                
                if !isCompact {
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: isCompact ? 16 : 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: isCompact ? 11 : 12, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
        }
        .padding(isCompact ? 12 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: iconColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
