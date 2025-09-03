//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @StateObject private var vm: ChartViewModel
    @State private var showChart = true
    @State private var showList = true
    @State private var selectedCategory: String? = nil
    @State private var showAllCategories = false

    private let maxVisibleItems = 6

    init(viewModel: ExpenseCalendarViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _vm = StateObject(wrappedValue: ChartViewModel(expenseViewModel: viewModel))
    }

    var body: some View {
        VStack {
            Text("원형 차트")
                .font(.headline)
            ZStack {
                if vm.filteredExpenses.isEmpty {
                    DottedPieChartView()
                        .frame(height: 200)
                        .opacity(showChart ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showChart)
                } else {
                    PieChartView(
                        data: Dictionary(uniqueKeysWithValues: vm.sortedCategoryTotals.map { ($0.category, $0.total) }),
                        highlightedCategory: selectedCategory
                    )
                        .frame(height: 200)
                        .opacity(showChart ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showChart)
                }
            }

            Divider()
                .padding(.vertical, 10)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("카테고리별 총 지출")
                        .font(.headline)
                    
                    if let selected = selectedCategory,
                       let categoryData = vm.sortedCategoryTotals.first(where: { $0.category == selected }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(categoryColor(for: selected))
                                .frame(width: 8, height: 8)
                            Text("\(selected) 선택됨")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedCategory = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                
                Spacer()
                Menu {
                    Button(action: { animateSortChange(to: .defaultOrder) }) {
                        Label("기본순", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { animateSortChange(to: .highToLow) }) {
                        Label("높은 순", systemImage: "arrow.down")
                    }
                    Button(action: { animateSortChange(to: .lowToHigh) }) {
                        Label("낮은 순", systemImage: "arrow.up")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            HStack {
                Button(action: {
                    vm.isShowingYearMonthPicker = true
                }) {
                    Text("\(vm.formatYear(vm.selectedYear))년 \(vm.selectedMonth)월")
                        .foregroundColor(.black)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showChart = false
                        showList = false
                        selectedCategory = nil
                    }
                    withAnimation(.easeInOut) {
                        vm.resetToCurrentDate()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showChart = true
                            showList = true
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(visibleCategories.enumerated()), id: \.element.category) { index, categoryTotal in
                        CategoryCardView(
                            categoryTotal: categoryTotal,
                            isSelected: selectedCategory == categoryTotal.category,
                            animationDelay: Double(index) * 0.05,
                            totalAmount: vm.totalAmount
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if selectedCategory == categoryTotal.category {
                                    selectedCategory = nil
                                } else {
                                    if categoryTotal.total > 0 {
                                        selectedCategory = categoryTotal.category
                                    }
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: showAllCategories)
                
                if vm.sortedCategoryTotals.count > maxVisibleItems {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showAllCategories.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(showAllCategories ? "접기" : "더보기 (\(vm.sortedCategoryTotals.count - maxVisibleItems)개)")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: showAllCategories ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 16)
            .opacity(showList ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showList)

            Spacer(minLength: 0)
        }
        .padding()
        .sheet(isPresented: $vm.isShowingYearMonthPicker) {
            YearMonthPickerView(
                viewModel: viewModel,
                selectedYear: $vm.selectedYear,
                selectedMonth: $vm.selectedMonth,
                showingPicker: $vm.isShowingYearMonthPicker,
                onComplete: { year, month in
                    vm.setYearMonth(year: year, month: month)
                }
            )
        }
        .onAppear {
            showChart = true
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "식비": return .red
        case "교통": return .blue
        case "쇼핑": return .green
        case "여가": return .orange
        case "기타": return .purple
        default: return .gray
        }
    }
    
    private var visibleCategories: [CategoryTotal] {
        if showAllCategories {
            return vm.sortedCategoryTotals
        } else {
            return Array(vm.sortedCategoryTotals.prefix(maxVisibleItems))
        }
    }
    
    private func animateSortChange(to order: ChartViewModel.SortOrder) {
        withAnimation(.easeInOut(duration: 0.3)) {
            showList = false
            selectedCategory = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.sortOrder = order
            withAnimation(.easeInOut(duration: 0.3)) {
                showList = true
            }
        }
    }
}

struct CategoryCardView: View {
    let categoryTotal: CategoryTotal
    let isSelected: Bool
    let animationDelay: Double
    let totalAmount: Double
    let onTap: () -> Void
    
    @State private var isVisible = false
    
    private var percentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (categoryTotal.total / totalAmount) * 100
    }
    
    private var categoryColor: Color {
        switch categoryTotal.category {
        case "식비": return .red
        case "교통": return .blue
        case "쇼핑": return .green
        case "여가": return .orange
        case "기타": return .purple
        default: return .gray
        }
    }
    
    private var hasNoExpense: Bool {
        return categoryTotal.total == 0
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if hasNoExpense {
                        Circle()
                            .stroke(categoryColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isSelected ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.25), value: isSelected)
                    } else {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: isSelected ? 16 : 12, height: isSelected ? 16 : 12)
                            .shadow(color: categoryColor.opacity(0.4), radius: isSelected ? 6 : 2)
                            .animation(.easeInOut(duration: 0.25), value: isSelected)
                    }
                    
                    Text(categoryTotal.category)
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                        .foregroundColor(hasNoExpense ? .secondary : (isSelected ? categoryColor : .secondary))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(categoryColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if hasNoExpense {
                        Text("0원")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text(formatAmount(categoryTotal.total))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    if !hasNoExpense {
                        HStack(spacing: 6) {
                            Text("\(String(format: "%.1f", percentage))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(categoryColor)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(categoryColor)
                                        .frame(width: geometry.size.width * (percentage / 100), height: 4)
                                        .animation(.easeInOut(duration: 0.8).delay(animationDelay + 0.2), value: percentage)
                                }
                            }
                            .frame(height: 4)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Text("0.0%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? categoryColor.opacity(0.15) : Color(.systemGray6))
                    .stroke(isSelected ? categoryColor.opacity(0.6) : Color.clear, lineWidth: 2)
                    .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.04), radius: isSelected ? 8 : 3, x: 0, y: isSelected ? 4 : 1.5)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: isSelected)
            .opacity(hasNoExpense ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(hasNoExpense)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: amount)) ?? "0") + "원"
    }
}

struct DottedPieChartView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray)
                .padding()
            Text("지출 없음")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
