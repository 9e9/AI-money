//
//  YearMonthPickerView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

// 연도와 월을 선택하고 해당 기간의 지출 통계를 보여주는 시트 뷰
struct YearMonthPickerView: View {
    // 지출 캘린더 뷰모델을 관찰하여 데이터 변경사항 감지
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    // 선택된 연도를 부모 뷰와 양방향 바인딩
    @Binding var selectedYear: Int
    // 선택된 월을 부모 뷰와 양방향 바인딩
    @Binding var selectedMonth: Int
    // 피커 화면 표시 여부를 부모 뷰와 양방향 바인딩
    @Binding var showingPicker: Bool
    
    // 완료 버튼 클릭 시 실행될 옵셔널 클로저 (연도, 월 전달)
    var onComplete: ((Int, Int) -> Void)? = nil
    
    // 이 뷰 전용의 피커 뷰모델 (통계 계산 등 담당)
    @StateObject private var pickerViewModel: YearMonthPickerViewModel
    
    // 커스텀 이니셜라이저 - 의존성 주입 및 초기값 설정
    init(viewModel: ExpenseCalendarViewModel,
         selectedYear: Binding<Int>,
         selectedMonth: Binding<Int>,
         showingPicker: Binding<Bool>,
         onComplete: ((Int, Int) -> Void)? = nil) {
        // 전달받은 파라미터들을 인스턴스 변수에 할당
        self.viewModel = viewModel
        self._selectedYear = selectedYear
        self._selectedMonth = selectedMonth
        self._showingPicker = showingPicker
        self.onComplete = onComplete
        // 피커 뷰모델을 현재 선택값으로 초기화
        self._pickerViewModel = StateObject(wrappedValue: YearMonthPickerViewModel(
            expenseCalendarViewModel: viewModel,
            year: selectedYear.wrappedValue,    // 바인딩된 값의 실제 값 추출
            month: selectedMonth.wrappedValue   // 바인딩된 값의 실제 값 추출
        ))
    }
    
    var body: some View {
        NavigationView {
            // 전체 내용을 스크롤 가능하게 구성
            ScrollView {
                VStack(spacing: 32) { // 각 섹션 사이 32포인트 간격
                    // 상단 헤더 (선택된 기간 표시)
                    headerSection
                    
                    // 연도/월 선택 휠 피커
                    pickerSection
                    
                    // 지출 통계 섹션 (애니메이션 효과 포함)
                    statsSection
                        .opacity(pickerViewModel.showStats ? 1.0 : 0.0) // 통계 표시 여부에 따른 투명도
                        .scaleEffect(pickerViewModel.showStats ?        // 통계 표시 여부에 따른 크기
                                   AnimationConfiguration.maxScale :    // 표시시 최대 크기
                                   AnimationConfiguration.minScale)     // 숨김시 최소 크기
                        .animation(.easeInOut(duration: AnimationConfiguration.scaleEffectDuration),
                                 value: pickerViewModel.showStats) // 통계 표시 상태 변화 시 애니메이션
                    
                    // 하단 여백 (스크롤을 위한)
                    Spacer().frame(height: 60)
                }
                .padding(.top, 20) // 상단 여백
            }
            .background(Color(.systemGroupedBackground)) // 시스템 그룹 배경색
            .navigationTitle("기간 선택") // 네비게이션 타이틀
            .navigationBarTitleDisplayMode(.inline) // 인라인 타이틀 모드
            .toolbar { toolbarContent } // 툴바 내용 추가
            .onAppear {
                // 화면이 나타날 때 통계 데이터를 애니메이션과 함께 업데이트
                pickerViewModel.updateExpenseStatsWithAnimation()
            }
        }
        .presentationDetents([.large]) // 시트가 큰 크기로만 표시되도록 설정
        .presentationDragIndicator(.visible) // 드래그 인디케이터 표시
    }
    
    // 상단 헤더 섹션 - 현재 선택된 기간을 표시
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 섹션 제목
            Text("선택된 기간")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            // 선택된 연도와 월을 큰 글씨로 표시
            Text(pickerViewModel.selectedPeriod.displayText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    // 연도/월 선택 피커 섹션
    private var pickerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) { // 연도와 월 피커를 가로로 배치
                // 연도 선택 피커
                VStack(spacing: 16) {
                    // 연도 레이블
                    Text("연도")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬
                    
                    // 연도 휠 피커
                    Picker("연도", selection: $selectedYear) {
                        // 설정된 연도 범위에서 각 연도를 피커 옵션으로 생성
                        ForEach(PickerConfiguration.availableYears, id: \.self) { year in
                            Text(FormatHelper.formatPlainNumber(year)) // 연도를 형식화된 텍스트로 표시
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .tag(year) // 각 옵션에 연도 값을 태그로 설정
                        }
                    }
                    .pickerStyle(WheelPickerStyle()) // 휠 스타일 피커 적용
                    .frame(height: 120) // 피커 높이 고정
                    .onChange(of: selectedYear) { oldValue, newValue in
                        // 연도가 변경되면 피커 뷰모델에 새로운 기간 업데이트
                        pickerViewModel.updatePeriod(year: newValue, month: selectedMonth)
                    }
                }
                .padding(20) // 피커 내부 여백
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground)) // 시스템 배경색
                        .stroke(Color(.systemGray5), lineWidth: 1) // 연한 회색 테두리
                )
                
                // 월 선택 피커 (연도 피커와 동일한 구조)
                VStack(spacing: 16) {
                    // 월 레이블
                    Text("월")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬
                    
                    // 월 휠 피커
                    Picker("월", selection: $selectedMonth) {
                        // 1월부터 12월까지 피커 옵션 생성
                        ForEach(PickerConfiguration.months, id: \.self) { month in
                            Text(FormatHelper.formatPlainNumber(month)) // 월을 형식화된 텍스트로 표시
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .tag(month) // 각 옵션에 월 값을 태그로 설정
                        }
                    }
                    .pickerStyle(WheelPickerStyle()) // 휠 스타일 피커 적용
                    .frame(height: 120) // 피커 높이 고정
                    .onChange(of: selectedMonth) { oldValue, newValue in
                        // 월이 변경되면 피커 뷰모델에 새로운 기간 업데이트
                        pickerViewModel.updatePeriod(year: selectedYear, month: newValue)
                    }
                }
                .padding(20) // 피커 내부 여백
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground)) // 시스템 배경색
                        .stroke(Color(.systemGray5), lineWidth: 1) // 연한 회색 테두리
                )
            }
        }
        .padding(.horizontal, 20) // 피커 섹션 가로 여백
    }
    
    // 지출 통계 섹션 - 선택된 기간의 지출 분석 정보 표시
    private var statsSection: some View {
        VStack(spacing: 20) {
            // 섹션 제목
            HStack {
                Text("지출 분석")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer() // 제목을 왼쪽 끝으로 정렬
            }
            .padding(.horizontal, 20)
            
            // 통계 카드들을 세로로 배열
            VStack(spacing: 12) {
                // 메인 통계 카드 (총 지출)
                StatCardView(data: pickerViewModel.getMainStatCard())
                
                // 최다 지출 카테고리 카드 (있는 경우만 표시)
                if let mostSpentCard = pickerViewModel.getMostSpentCategoryCard() {
                    StatCardView(data: mostSpentCard)
                }
                
                // 평균 지출과 작년 동월 지출을 가로로 나란히 배치
                HStack(spacing: 12) {
                    StatCardView(data: pickerViewModel.getAverageExpenseCard()) // 3개월 평균
                    StatCardView(data: pickerViewModel.getPrevYearCard())      // 작년 동월
                }
                
                // 변화율 카드 (작년 동월 데이터가 있는 경우만 표시)
                if let changeRateCard = pickerViewModel.getChangeRateCard() {
                    StatCardView(data: changeRateCard)
                }
            }
            .padding(.horizontal, 20) // 통계 카드들 가로 여백
        }
    }
    
    // 상단 툴바 내용 정의
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // 오른쪽 상단에 완료 버튼 배치
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("완료") {
                // 완료 클로저가 있으면 현재 선택된 연도와 월을 전달하여 호출
                onComplete?(selectedYear, selectedMonth)
                // 피커 화면 닫기
                showingPicker = false
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
        }
    }
}

// 통계 정보를 표시하는 카드 뷰
struct StatCardView: View {
    // 카드에 표시할 데이터
    let data: StatCardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: data.isCompact ? 8 : 12) { // 컴팩트 모드에 따른 간격 조정
            // 카드 제목 (예: "총 지출", "최다 지출 카테고리")
            Text(data.title)
                .font(.system(size: data.isCompact ? 14 : 16, weight: .medium)) // 컴팩트 모드에 따른 폰트 크기
                .foregroundColor(.secondary)
            
            HStack {
                // 주요 값 표시 (금액, 카테고리명 등)
                Text(data.value)
                    .font(.system(
                        size: data.isMain ? 24 : (data.isCompact ? 18 : 20), // 메인/컴팩트 여부에 따른 폰트 크기
                        weight: .bold,
                        design: .rounded // 숫자에 적합한 rounded 디자인
                    ))
                    .foregroundColor(data.isChange ? (data.isIncrease ? .red : .green) : .primary) // 변화율이면 증감에 따라 색상 변경
                    .lineLimit(1) // 한 줄로 제한
                    .minimumScaleFactor(0.8) // 공간이 부족하면 80%까지 축소 가능
                
                // 변화율 카드인 경우 증감 화살표 표시
                if data.isChange {
                    Image(systemName: data.isIncrease ? "arrow.up" : "arrow.down") // 증가/감소 화살표
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(data.isIncrease ? .red : .green) // 증가는 빨강, 감소는 초록
                }
                
                Spacer() // 나머지 공간을 채워 왼쪽 정렬 유지
            }
            
            // 부제목이 있는 경우 표시 (예: 금액 상세, 카테고리 이름)
            if let subtitle = data.subtitle {
                Text(subtitle)
                    .font(.system(size: data.isCompact ? 12 : 14, weight: .medium)) // 컴팩트 모드에 따른 폰트 크기
                    .foregroundColor(.secondary)
            }
        }
        .padding(data.isCompact ? 16 : 20) // 컴팩트 모드에 따른 패딩
        .frame(maxWidth: .infinity, alignment: .leading) // 전체 너비 사용, 내용은 왼쪽 정렬
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground)) // 시스템 배경색
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            data.isMain ? Color.black : Color(.systemGray5), // 메인 카드는 검은 테두리, 일반은 회색
                            lineWidth: data.isMain ? 2 : 1 // 메인 카드는 두꺼운 테두리
                        )
                )
        )
    }
}
