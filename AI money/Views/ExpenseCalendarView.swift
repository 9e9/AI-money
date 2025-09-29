//
//  ExpenseCalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

// 지출 캘린더 메인 화면을 구성하는 SwiftUI View
// 캘린더 형태로 날짜를 표시하고, 선택한 날짜의 지출 내역을 보여주는 화면
struct ExpenseCalendarView: View {
    // 캘린더 뷰모델을 관찰하여 데이터 변경사항을 실시간으로 반영
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    // 지출 추가 시트 표시 여부를 관리하는 상태
    @State private var showingAddExpense = false
    // 지출 삭제 확인 알림 표시 여부를 관리하는 상태
    @State private var showingDeleteAlert = false
    // 정보 화면 표시 여부를 관리하는 상태
    @State private var showInformationView = false
    // 년월 선택 피커 표시 여부를 관리하는 상태
    @State private var showingPicker = false
    // 현재 삭제 대상인 지출 객체를 저장하는 상태
    @State private var expenseToDelete: Expense? = nil
    // 스크롤 위치를 추적하여 상단 네비게이션 바 표시 여부를 결정하는 상태
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // 전체 화면의 배경색 설정 (시스템 그룹 배경색)
            Color(.systemGroupedBackground)
                .ignoresSafeArea() // 안전 영역까지 배경색 확장
            
            VStack(spacing: 0) {
                // 캘린더 헤더 섹션 (제목, 버튼, 월 네비게이션 포함)
                calendarHeaderSection
                    .background(
                        // 스크롤 위치를 감지하기 위한 GeometryReader
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    // 화면 로드 시 초기 스크롤 위치 설정
                                    scrollOffset = geometry.frame(in: .global).minY
                                }
                                .onChange(of: geometry.frame(in: .global).minY) { oldValue, newValue in
                                    // 스크롤 위치가 변경될 때마다 업데이트
                                    scrollOffset = newValue
                                }
                        }
                    )
                
                // 캘린더 그리드 섹션 (날짜 표시)
                calendarSection
                    .padding(.horizontal, 20) // 좌우 여백 설정
                
                // 선택된 날짜의 지출 내역을 표시하는 섹션
                expenseListSection
                    .padding(.top, 16) // 상단 여백 설정
            }
            
            // 스크롤 시 나타나는 상단 네비게이션 바 (플로팅)
            VStack {
                ZStack {
                    // 블러 효과가 적용된 반투명 배경
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .top) // 상단 안전 영역까지 확장
                    
                    HStack {
                        // 네비게이션 바 제목
                        Text("지출 내역")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer() // 제목과 버튼 사이의 공간
                        
                        // 네비게이션 바 우측 버튼들
                        HStack(spacing: 12) {
                            // 정보 버튼 (앱 정보 화면 표시)
                            Button(action: { showInformationView = true }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            
                            // 지출 추가 버튼
                            Button(action: { showingAddExpense = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 20) // 좌우 여백
                    .padding(.bottom, 8) // 하단 여백
                }
                .frame(height: 44) // 네비게이션 바 고정 높이
                // 스크롤 위치에 따라 투명도 조절 (-60 이하로 스크롤하면 나타남)
                .opacity(scrollOffset < -60 ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: scrollOffset)
                
                Spacer() // 네비게이션 바를 상단에 고정
            }
        }
        .navigationBarHidden(true) // 기본 네비게이션 바 숨김
        // 지출 추가 시트 표시
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(
                viewModel: viewModel,
                // 선택된 날짜가 있으면 해당 날짜, 없으면 오늘 날짜 전달
                selectedDate: viewModel.calendarState.selectedDate ?? Date()
            )
        }
        // 년월 선택 피커 시트 표시
        .sheet(isPresented: $showingPicker) {
            YearMonthPickerView(
                viewModel: viewModel,
                selectedYear: $viewModel.selectedYear,
                selectedMonth: $viewModel.selectedMonth,
                showingPicker: $showingPicker,
                onComplete: { year, month in
                    // 년월 선택 완료 시 뷰모델 업데이트
                    viewModel.updateSelectedPeriod(year: year, month: month)
                }
            )
        }
        // 앱 정보 시트 표시
        .sheet(isPresented: $showInformationView) {
            NavigationView {
                InformationView()
            }
        }
        // 지출 삭제 확인 알림 다이얼로그
        .alert("지출 삭제", isPresented: $showingDeleteAlert) {
            // 삭제 확인 버튼 (빨간색, 파괴적 액션)
            Button("삭제", role: .destructive) {
                if let expense = expenseToDelete {
                    // 부드러운 애니메이션과 함께 지출 삭제
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.removeExpense(expense)
                    }
                }
            }
            // 취소 버튼
            Button("취소", role: .cancel) {
                expenseToDelete = nil // 삭제 대상 초기화
            }
        } message: {
            Text("이 지출 내역을 삭제하시겠습니까?")
        }
    }
    
    // MARK: - Header Section
    // 캘린더 상단 헤더 섹션 구성
    private var calendarHeaderSection: some View {
        VStack(spacing: 20) {
            // 상단 타이틀과 액션 버튼들
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // 메인 제목과 정보 버튼을 같은 줄에 배치
                    HStack(spacing: 8) {
                        Text("지출 내역")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // 정보 버튼을 제목 바로 옆에 배치
                        Button(action: { showInformationView = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 현재 선택된 년월 표시 및 피커 버튼
                    Button(action: { showingPicker.toggle() }) {
                        HStack(spacing: 6) {
                            // 년월 텍스트 (예: "2025년 01월")
                            Text("\(String(viewModel.selectedYear))년 \(String(format: "%02d", viewModel.selectedMonth))월")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // 드롭다운 화살표 아이콘
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer() // 좌측 정보와 우측 버튼 사이 공간
                
                // 우측에는 지출 추가 버튼만 배치
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40) // 버튼 크기 고정
                        .background(Circle().fill(Color(.systemGray6))) // 원형 배경
                }
            }
            
            // 월 네비게이션 버튼들과 총 지출 표시
            HStack {
                // 월 이동 네비게이션 버튼들
                HStack(spacing: 12) {
                    // 이전 달로 이동 버튼
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
                    
                    // 현재 날짜로 돌아가기 버튼
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
                    
                    // 다음 달로 이동 버튼
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
                
                Spacer() // 네비게이션 버튼과 총 지출 표시 사이 공간
                
                // 이번 달 총 지출 표시 (지출이 있을 때만)
                if viewModel.monthlyTotal > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("이번 달 총 지출")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // 포맷된 금액 표시
                        Text(viewModel.formatAmount(viewModel.monthlyTotal))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity) // 부드러운 나타남/사라짐 효과
                }
            }
        }
        .padding(.horizontal, 20) // 좌우 여백
        .padding(.vertical, 16) // 상하 여백
    }
    
    // MARK: - Calendar Section
    // 캘린더 그리드 섹션 구성
    private var calendarSection: some View {
        VStack(spacing: 12) {
            // 요일 헤더 (일, 월, 화, 수, 목, 금, 토)
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(CalendarConfiguration.weekdaySymbols[index])
                        .font(.system(size: 13, weight: .medium))
                        // 일요일(0)은 빨간색, 토요일(6)은 파란색, 나머지는 기본색
                        .foregroundColor(index == 0 ? .red : (index == 6 ? .blue : .secondary))
                        .frame(maxWidth: .infinity) // 동일한 너비로 분할
                }
            }
            .padding(.bottom, 4) // 요일 헤더 하단 여백
            
            // 캘린더 날짜 그리드 (7열 그리드)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(viewModel.calendarDays.indices, id: \.self) { index in
                    let day = viewModel.calendarDays[index]
                    ModernCalendarDayView(
                        day: day,
                        // 현재 선택된 날짜와 일치하는지 확인
                        isSelected: viewModel.calendarState.selectedDate != nil &&
                            Calendar.current.isDate(day.date, equalTo: viewModel.calendarState.selectedDate!, toGranularity: .day),
                        onTap: {
                            // 날짜 탭 시 애니메이션과 함께 선택/해제 처리
                            withAnimation(.easeInOut(duration: 0.3)) {
                                // 이미 선택된 날짜를 다시 탭하면 선택 해제
                                if let selectedDate = viewModel.calendarState.selectedDate,
                                   Calendar.current.isDate(selectedDate, inSameDayAs: day.date) {
                                    viewModel.selectDate(nil)
                                } else {
                                    // 새로운 날짜 선택
                                    viewModel.selectDate(day.date)
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(16) // 캘린더 내부 여백
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground)) // 시스템 배경색
                // 미세한 그림자 효과 적용
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Expense List Section
    // 선택된 날짜의 지출 내역 표시 섹션
    private var expenseListSection: some View {
        VStack(spacing: 0) {
            // 캘린더 상태에 따라 다른 뷰 표시
            switch viewModel.calendarState {
            case .noDateSelected:
                // 날짜가 선택되지 않은 상태
                modernEmptyStateView(
                    icon: "calendar",
                    title: "날짜를 선택하세요",
                    subtitle: "캘린더에서 날짜를 탭하여\n지출 내역을 확인하세요"
                )
                
            case .dateSelectedWithoutExpenses(let date, let holiday):
                // 날짜는 선택되었지만 지출 내역이 없는 상태
                modernEmptyStateViewWithHoliday(
                    date: date,
                    holiday: holiday
                )
                
            case .dateSelectedWithExpenses(let summary):
                // 선택된 날짜에 지출 내역이 있는 상태
                modernExpenseListView(summary: summary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 영역 차지
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground)) // 시스템 배경색
                // 미세한 그림자 효과
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20) // 좌우 여백
        .padding(.bottom, 20) // 하단 여백
    }
    
    // MARK: - Modern Empty State Views
    // 기본 빈 상태 뷰 (아이콘 + 제목 + 부제목)
    private func modernEmptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            // 중앙 아이콘
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 6) {
                // 메인 제목
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                // 부제목 (여러 줄 가능)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center) // 중앙 정렬
                    .lineSpacing(2) // 줄 간격 설정
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 영역 차지
        .transition(.opacity) // 부드러운 페이드 전환
    }
    
    // 공휴일 정보를 포함한 빈 상태 뷰
    private func modernEmptyStateViewWithHoliday(date: Date, holiday: KoreanHoliday?) -> some View {
        VStack(spacing: 20) {
            if let holiday = holiday {
                // 공휴일이 있는 경우 특별한 UI 표시
                VStack(spacing: 16) {
                    // 공휴일 아이콘 (원형 배경 + 별 아이콘)
                    ZStack {
                        Circle()
                            .fill(getHolidayColor(for: holiday.type).opacity(0.1)) // 공휴일 타입별 색상
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(getHolidayColor(for: holiday.type))
                    }
                    
                    VStack(spacing: 8) {
                        // 공휴일 이름
                        Text(holiday.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // 선택된 날짜 표시
                        Text(formatSelectedDate(date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // 휴일 축하 메시지
                        Text("휴일이에요 🎉")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 영역 차지
                
            } else {
                // 일반 날짜의 빈 상태 (공휴일이 아닌 경우)
                modernEmptyStateView(
                    icon: "tray",
                    title: "지출 내역 없음",
                    subtitle: "\(formatSelectedDate(date))에는\n지출이 없습니다"
                )
            }
        }
        .transition(.opacity) // 부드러운 페이드 전환
    }
    
    // 지출 내역이 있는 날짜의 리스트 뷰
    private func modernExpenseListView(summary: DailyExpenseSummary) -> some View {
        VStack(spacing: 0) {
            // 날짜 및 총계 정보 헤더
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        // 선택된 날짜 표시
                        Text(formatSelectedDate(summary.date))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // 공휴일 태그 (공휴일인 경우에만 표시)
                        if let holiday = summary.holiday {
                            Text(holiday.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white) // 흰색 텍스트
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(getHolidayColor(for: holiday.type)) // 공휴일 타입별 배경색
                                )
                        }
                    }
                    
                    // 총 지출 금액과 항목 개수 표시
                    HStack(spacing: 12) {
                        Text("총 \(viewModel.formatAmount(summary.totalAmount))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•") // 구분자
                            .foregroundColor(.secondary)
                        
                        Text("\(summary.expenses.count)개 항목")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer() // 좌측 정보를 왼쪽 정렬
            }
            .padding(.horizontal, 16) // 좌우 여백
            .padding(.vertical, 12) // 상하 여백
            .background(Color(.systemGray6).opacity(0.5)) // 연한 회색 배경
            
            // 지출 내역 스크롤 리스트
            ScrollView {
                LazyVStack(spacing: 1) { // 성능 최적화를 위한 LazyVStack, 간격 1
                    ForEach(summary.expenses) { expense in
                        ModernExpenseRowView(
                            data: ExpenseCardData(expense: expense),
                            onDelete: {
                                // 삭제 버튼 클릭 시 삭제 확인 알림 표시
                                expenseToDelete = expense
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .padding(.vertical, 8) // 상하 여백
            }
        }
        .transition(.opacity) // 부드러운 페이드 전환
    }
    
    // MARK: - Helper Methods
    // 선택된 날짜를 한국어 형식으로 포맷팅 (예: "01월 15일 월요일")
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // 한국어 로케일
        formatter.dateFormat = "MM월 dd일 EEEE" // 월일요일 형식
        return formatter.string(from: date)
    }

    // 공휴일 타입에 따른 색상 반환
    private func getHolidayColor(for type: HolidayType) -> Color {
        switch type {
        case .national, .traditional: return .red      // 국경일, 전통 명절: 빨간색
        case .memorial: return .orange                 // 기념일: 주황색
        case .substitute: return .blue                 // 대체공휴일: 파란색
        }
    }
    
    // 공휴일 타입에 따른 설명 텍스트 반환
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
// 캘린더의 개별 날짜를 표시하는 현대적인 스타일의 뷰
struct ModernCalendarDayView: View {
    let day: CalendarDay        // 표시할 날짜 정보
    let isSelected: Bool        // 현재 선택된 날짜인지 여부
    let onTap: () -> Void      // 탭 시 실행될 콜백 함수
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // 날짜 숫자 표시
                Text("\(day.dayNumber)")
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(dayTextColor) // 날짜 텍스트 색상
                
                // 지출 및 공휴일 인디케이터 (점으로 표시)
                HStack(spacing: 3) {
                    // 지출이 있고 현재 달의 날짜인 경우 파란색 점 표시
                    if day.hasExpense && day.isInCurrentMonth {
                        Circle()
                            .fill(isSelected ? Color.white : Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    
                    // 공휴일이고 현재 달의 날짜인 경우 공휴일 색상 점 표시
                    if day.isHoliday && day.isInCurrentMonth {
                        Circle()
                            .fill(isSelected ? Color.white : holidayDotColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6) // 인디케이터 영역 고정 높이
            }
            .frame(width: 36, height: 40) // 날짜 셀 고정 크기
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(dayBackgroundColor) // 날짜 배경색
            )
        }
        .buttonStyle(PlainButtonStyle()) // 기본 버튼 스타일 제거
        .disabled(!day.isInCurrentMonth) // 현재 달이 아닌 날짜는 비활성화
    }
    
    // 날짜 텍스트 색상을 결정하는 계산 속성
    private var dayTextColor: Color {
        if isSelected {
            return .white // 선택된 날짜: 흰색
        } else if day.isHoliday && day.isInCurrentMonth {
            return holidayTextColor // 공휴일: 공휴일 타입별 색상
        } else if day.isInCurrentMonth {
            return .primary // 현재 달의 일반 날짜: 기본 텍스트 색상
        } else {
            return .secondary.opacity(0.5) // 이전/다음 달 날짜: 연한 회색
        }
    }
    
    // 날짜 배경색을 결정하는 계산 속성
    private var dayBackgroundColor: Color {
        if isSelected {
            return .primary // 선택된 날짜: 검은색 배경
        } else if day.isHoliday && day.isInCurrentMonth {
            return holidayTextColor.opacity(0.1) // 공휴일: 연한 공휴일 색상 배경
        } else {
            return .clear // 일반 날짜: 투명 배경
        }
    }
    
    // 공휴일 텍스트 색상을 결정하는 계산 속성
    private var holidayTextColor: Color {
        guard let holiday = day.holiday else { return .primary }
        switch holiday.type {
        case .national, .traditional: return .red    // 국경일, 전통 명절: 빨간색
        case .memorial: return .orange               // 기념일: 주황색
        case .substitute: return .blue               // 대체공휴일: 파란색
        }
    }
    
    // 공휴일 인디케이터 점 색상을 결정하는 계산 속성
    private var holidayDotColor: Color {
        guard let holiday = day.holiday else { return .clear }
        switch holiday.type {
        case .national, .traditional: return .red    // 국경일, 전통 명절: 빨간색
        case .memorial: return .orange               // 기념일: 주황색
        case .substitute: return .blue               // 대체공휴일: 파란색
        }
    }
}

// MARK: - Modern Expense Row View
// 지출 내역의 개별 항목을 표시하는 현대적인 스타일의 행 뷰
struct ModernExpenseRowView: View {
    let data: ExpenseCardData   // 표시할 지출 데이터
    let onDelete: () -> Void   // 삭제 버튼 클릭 시 실행될 콜백 함수
    
    var body: some View {
        HStack(spacing: 12) {
            // 카테고리를 나타내는 아이콘 (원형 배경 + 아이콘)
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.1)) // 카테고리별 연한 배경색
                    .frame(width: 36, height: 36)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(categoryColor) // 카테고리별 아이콘 색상
            }
            
            // 지출 정보 (카테고리명, 금액, 메모)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    // 카테고리명
                    Text(data.expense.category)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer() // 카테고리명과 금액 사이 공간
                    
                    // 포맷된 지출 금액
                    Text(data.formattedAmount)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                // 메모가 있는 경우에만 표시
                if data.hasNote {
                    Text(data.expense.note)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1) // 한 줄로 제한
                }
            }
            
            // 삭제 버튼
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red.opacity(0.7)) // 반투명 빨간색
            }
        }
        .padding(.horizontal, 16) // 좌우 여백
        .padding(.vertical, 12) // 상하 여백
        .background(Color(.systemBackground)) // 시스템 배경색
    }
    
    // 카테고리에 따른 색상을 결정하는 계산 속성
    private var categoryColor: Color {
        switch data.expense.category {
        case "식비": return .red      // 식비: 빨간색
        case "교통": return .blue     // 교통: 파란색
        case "쇼핑": return .green    // 쇼핑: 녹색
        case "여가": return .orange   // 여가: 주황색
        case "기타": return .purple   // 기타: 보라색
        default: return .gray         // 기본: 회색
        }
    }
    
    // 카테고리에 따른 아이콘을 결정하는 계산 속성
    private var categoryIcon: String {
        switch data.expense.category {
        case "식비": return "fork.knife"        // 식비: 포크나이프 아이콘
        case "교통": return "car.fill"          // 교통: 자동차 아이콘
        case "쇼핑": return "bag.fill"          // 쇼핑: 쇼핑백 아이콘
        case "여가": return "gamecontroller.fill" // 여가: 게임 컨트롤러 아이콘
        case "기타": return "ellipsis"          // 기타: 점점점 아이콘
        default: return "questionmark"          // 기본: 물음표 아이콘
        }
    }
}
