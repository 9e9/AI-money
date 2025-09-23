//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @StateObject private var vm: ChartViewModel
    @State private var showChart = true
    @State private var showList = true
    @State private var selectedCategory: String? = nil
    @State private var showAllCategories = false
    @State private var animateChart = false
    @State private var scrollOffset: CGFloat = 0

    private let maxVisibleItems = 4

    init(viewModel: ExpenseCalendarViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _vm = StateObject(wrappedValue: ChartViewModel(expenseService: viewModel))
    }

    var body: some View {
        ZStack {
            // 심플한 배경
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // 메인 스크롤뷰
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // 헤더 (스크롤 오프셋 추적용)
                    headerSection
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
                    
                    // 차트 메인 섹션
                    chartMainSection
                    
                    // 인사이트 카드들
                    insightCardsSection
                    
                    // 카테고리 상세 리스트
                    categoryDetailSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .coordinateSpace(name: "scroll")
            
            // 상단 네비게이션 바 (스크롤 시 나타남)
            VStack {
                ZStack {
                    // 블러 배경
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .top)
                    
                    // 네비게이션 내용
                    HStack {
                        Text("분석")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 액션 버튼들 (심플 버전)
                        HStack(spacing: 8) {
                            // 정렬 메뉴
                            Menu {
                                Button("기본 순서") { animateSortChange(to: .defaultOrder) }
                                Button("높은 금액순") { animateSortChange(to: .highToLow) }
                                Button("낮은 금액순") { animateSortChange(to: .lowToHigh) }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color(.systemGray6)))
                            }
                            
                            // 리셋 버튼
                            Button(action: resetAll) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color(.systemGray6)))
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateChart = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("지출 분석")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Button(action: { vm.isShowingYearMonthPicker = true }) {
                    HStack(spacing: 6) {
                        Text("\(vm.formatYear(vm.selectedYear))년 \(vm.selectedMonth)월")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 심플한 액션 버튼들
            HStack(spacing: 8) {
                // 정렬 메뉴
                Menu {
                    Button("기본 순서") { animateSortChange(to: .defaultOrder) }
                    Button("높은 금액순") { animateSortChange(to: .highToLow) }
                    Button("낮은 금액순") { animateSortChange(to: .lowToHigh) }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                }
                
                // 리셋 버튼
                Button(action: resetAll) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
    }
    
    // MARK: - Chart Main Section
    private var chartMainSection: some View {
        VStack(spacing: 24) {
            // 선택된 카테고리 헤더
            if let selected = selectedCategory {
                selectedCategoryHeader(selected)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // 차트 컨테이너
            ZStack {
                // 심플한 배경 카드
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                
                if vm.filteredExpenses.isEmpty {
                    EmptyChartView()
                        .frame(height: 280)
                } else {
                    VStack(spacing: 20) {
                        // 중앙 통계
                        centerStats
                        
                        // 차트
                        CleanPieChart(
                            data: Dictionary(uniqueKeysWithValues: vm.sortedCategoryTotals.map { ($0.category, $0.total) }),
                            highlightedCategory: selectedCategory
                        )
                        .frame(height: 200)
                        .scaleEffect(animateChart ? 1.0 : 0.8)
                        .opacity(animateChart ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateChart)
                    }
                    .padding(24)
                }
            }
        }
    }
    
    private var centerStats: some View {
        VStack(spacing: 8) {
            Text("총 지출")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(FormatHelper.formatAmount(vm.totalAmount))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("\(vm.filteredExpenses.count)건의 지출")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private func selectedCategoryHeader(_ category: String) -> some View {
        let categoryTotal = vm.sortedCategoryTotals.first { $0.category == category }
        let percentage = vm.totalAmount > 0 ? ((categoryTotal?.total ?? 0) / vm.totalAmount) * 100 : 0
        
        return HStack {
            HStack(spacing: 12) {
                // 카테고리 아이콘 (단순화)
                ZStack {
                    Circle()
                        .fill(categoryColor(for: category).opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: categoryIcon(for: category))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(categoryColor(for: category))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text("\(String(format: "%.1f", percentage))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(categoryColor(for: category))
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(FormatHelper.formatAmount(categoryTotal?.total ?? 0))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedCategory = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
    
    // MARK: - Insight Cards Section
    private var insightCardsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("한눈에 보기")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // 가장 많이 쓴 카테고리
                SimpleInsightCard(
                    title: "최고 지출",
                    value: topCategory?.category ?? "없음",
                    subtitle: FormatHelper.formatAmount(topCategory?.total ?? 0)
                )
                
                // 평균 지출
                SimpleInsightCard(
                    title: "평균 지출",
                    value: vm.filteredExpenses.isEmpty ? "0원" : FormatHelper.formatAmount(vm.totalAmount / Double(vm.filteredExpenses.count)),
                    subtitle: "건당 평균"
                )
            }
        }
    }
    
    private var topCategory: CategoryTotal? {
        vm.sortedCategoryTotals.filter { $0.total > 0 }.max { $0.total < $1.total }
    }
    
    // MARK: - Category Detail Section
    private var categoryDetailSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("상세 내역")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if vm.sortedCategoryTotals.count > maxVisibleItems {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showAllCategories.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(showAllCategories ? "접기" : "더보기")
                                .font(.system(size: 12, weight: .medium))
                            
                            Image(systemName: showAllCategories ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(visibleCategories.enumerated()), id: \.element.category) { index, categoryTotal in
                    CleanCategoryRow(
                        categoryTotal: categoryTotal,
                        isSelected: selectedCategory == categoryTotal.category,
                        totalAmount: vm.totalAmount,
                        animationDelay: Double(index) * 0.1
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if selectedCategory == categoryTotal.category {
                                selectedCategory = nil
                            } else if categoryTotal.total > 0 {
                                selectedCategory = categoryTotal.category
                            }
                        }
                    }
                }
            }
            .opacity(showList ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showList)
        }
    }
    
    // MARK: - Helper Properties & Methods
    private var visibleCategories: [CategoryTotal] {
        if showAllCategories {
            return vm.sortedCategoryTotals
        } else {
            return Array(vm.sortedCategoryTotals.prefix(maxVisibleItems))
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
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "식비": return "fork.knife"
        case "교통": return "car.fill"
        case "쇼핑": return "bag.fill"
        case "여가": return "gamecontroller.fill"
        case "기타": return "ellipsis"
        default: return "questionmark"
        }
    }
    
    private func resetAll() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showChart = false
            showList = false
            selectedCategory = nil
            animateChart = false
        }
        vm.resetToCurrentDate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showChart = true
                showList = true
                animateChart = true
            }
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

// MARK: - Clean Category Row
struct CleanCategoryRow: View {
    let categoryTotal: CategoryTotal
    let isSelected: Bool
    let totalAmount: Double
    let animationDelay: Double
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
    
    private var categoryIcon: String {
        switch categoryTotal.category {
        case "식비": return "fork.knife"
        case "교통": return "car.fill"
        case "쇼핑": return "bag.fill"
        case "여가": return "gamecontroller.fill"
        case "기타": return "ellipsis"
        default: return "questionmark"
        }
    }
    
    private var hasExpense: Bool {
        return categoryTotal.total > 0
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 단순한 아이콘
                ZStack {
                    Circle()
                        .fill(hasExpense ? categoryColor.opacity(0.1) : Color(.systemGray6))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(hasExpense ? categoryColor : .secondary)
                }
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // 정보
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(categoryTotal.category)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if hasExpense {
                            Text("\(String(format: "%.1f", percentage))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.systemGray6))
                                )
                            
                            if isSelected {
                                Circle()
                                    .fill(categoryColor)
                                    .frame(width: 8, height: 8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    
                    Text(FormatHelper.formatAmount(categoryTotal.total))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(hasExpense ? .primary : .secondary)
                    
                    // 단순한 프로그레스 바
                    if hasExpense {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(categoryColor)
                                    .frame(width: geometry.size.width * (percentage / 100), height: 4)
                                    .animation(.easeInOut(duration: 1.0).delay(animationDelay), value: percentage)
                            }
                        }
                        .frame(height: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray6))
                            .frame(height: 4)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? categoryColor.opacity(0.3) : Color(.systemGray6),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.06),
                        radius: 6,
                        x: 0,
                        y: 2
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!hasExpense)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Simple Insight Card
struct SimpleInsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: isAnimating ? 0.7 : 0)
                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("지출 내역 없음")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("지출을 추가하면 차트가 나타납니다")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 280)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Clean Pie Chart
struct CleanPieChart: View {
    let data: [String: Double]
    let highlightedCategory: String?
    
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
    
    private func categoryOpacity(for category: String) -> Double {
        guard let highlighted = highlightedCategory else { return 1.0 }
        return category == highlighted ? 1.0 : 0.4
    }
    
    private func outerRadius(for category: String) -> Double {
        guard let highlighted = highlightedCategory else { return 0.8 }
        return category == highlighted ? 0.85 : 0.8
    }
    
    var body: some View {
        Chart {
            ForEach(data.keys.sorted(), id: \.self) { category in
                SectorMark(
                    angle: .value("Amount", data[category] ?? 0.0),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(outerRadius(for: category)),
                    angularInset: 1.5
                )
                .foregroundStyle(categoryColor(for: category))
                .opacity(categoryOpacity(for: category))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: highlightedCategory)
    }
}
