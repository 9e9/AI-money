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
    
    @StateObject private var pickerViewModel: YearMonthPickerViewModel
    
    init(viewModel: ExpenseCalendarViewModel,
         selectedYear: Binding<Int>,
         selectedMonth: Binding<Int>,
         showingPicker: Binding<Bool>,
         onComplete: ((Int, Int) -> Void)? = nil) {
        self.viewModel = viewModel
        self._selectedYear = selectedYear
        self._selectedMonth = selectedMonth
        self._showingPicker = showingPicker
        self.onComplete = onComplete
        self._pickerViewModel = StateObject(wrappedValue: YearMonthPickerViewModel(
            expenseCalendarViewModel: viewModel,
            year: selectedYear.wrappedValue,
            month: selectedMonth.wrappedValue
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    pickerSection
                    
                    statsSection
                        .opacity(pickerViewModel.showStats ? 1.0 : 0.0)
                        .scaleEffect(pickerViewModel.showStats ?
                                   AnimationConfiguration.maxScale :
                                   AnimationConfiguration.minScale)
                        .animation(.easeInOut(duration: AnimationConfiguration.scaleEffectDuration),
                                 value: pickerViewModel.showStats)
                    
                    Spacer().frame(height: 60)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("기간 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear {
                pickerViewModel.updateExpenseStatsWithAnimation()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("선택된 기간")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(pickerViewModel.selectedPeriod.displayText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    private var pickerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                VStack(spacing: 16) {
                    Text("연도")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("연도", selection: $selectedYear) {
                        ForEach(PickerConfiguration.availableYears, id: \.self) { year in
                            Text(FormatHelper.formatPlainNumber(year))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .onChange(of: selectedYear) { oldValue, newValue in
                        pickerViewModel.updatePeriod(year: newValue, month: selectedMonth)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                
                VStack(spacing: 16) {
                    Text("월")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Picker("월", selection: $selectedMonth) {
                        ForEach(PickerConfiguration.months, id: \.self) { month in
                            Text(FormatHelper.formatPlainNumber(month))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .onChange(of: selectedMonth) { oldValue, newValue in
                        pickerViewModel.updatePeriod(year: selectedYear, month: newValue)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var statsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("지출 분석")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                StatCardView(data: pickerViewModel.getMainStatCard())
                
                if let mostSpentCard = pickerViewModel.getMostSpentCategoryCard() {
                    StatCardView(data: mostSpentCard)
                }
                
                HStack(spacing: 12) {
                    StatCardView(data: pickerViewModel.getAverageExpenseCard())
                    StatCardView(data: pickerViewModel.getPrevYearCard())
                }
                
                if let changeRateCard = pickerViewModel.getChangeRateCard() {
                    StatCardView(data: changeRateCard)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("완료") {
                onComplete?(selectedYear, selectedMonth)
                showingPicker = false
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
        }
    }
}

struct StatCardView: View {
    let data: StatCardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: data.isCompact ? 8 : 12) {
            Text(data.title)
                .font(.system(size: data.isCompact ? 14 : 16, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                Text(data.value)
                    .font(.system(
                        size: data.isMain ? 24 : (data.isCompact ? 18 : 20),
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(data.isChange ? (data.isIncrease ? .red : .green) : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if data.isChange {
                    Image(systemName: data.isIncrease ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(data.isIncrease ? .red : .green)
                }
                
                Spacer()
            }
            
            if let subtitle = data.subtitle {
                Text(subtitle)
                    .font(.system(size: data.isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(data.isCompact ? 16 : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            data.isMain ? Color.black : Color(.systemGray5),
                            lineWidth: data.isMain ? 2 : 1
                        )
                )
        )
    }
}
