//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts // Charts 프레임워크 임포트 (차트 생성용)

struct ChartView: View { // 지출 차트를 표시하는 뷰 구조체
    @ObservedObject var viewModel: ExpenseCalendarViewModel // 지출 캘린더 뷰모델 관찰
    @StateObject private var vm: ChartViewModel // 차트 전용 뷰모델 상태 관리
    @State private var showChart = true // 차트 표시 여부 상태
    @State private var showList = true // 리스트 표시 여부 상태
    @State private var selectedCategory: String? = nil // 선택된 카테고리 상태
    @State private var showAllCategories = false // 모든 카테고리 표시 여부 상태
    @State private var animateChart = false // 차트 애니메이션 상태
    @State private var scrollOffset: CGFloat = 0 // 스크롤 오프셋 추적용 상태

    private let maxVisibleItems = 4 // 최대 표시 항목 수 (더보기 기능용)

    init(viewModel: ExpenseCalendarViewModel) { // 초기화 함수
        _viewModel = ObservedObject(wrappedValue: viewModel) // 지출 뷰모델 연결
        _vm = StateObject(wrappedValue: ChartViewModel(expenseService: viewModel)) // 차트 뷰모델 초기화
    }

    var body: some View {
        ZStack { // 레이아웃을 겹쳐서 배치
            // 심플한 배경
            Color(.systemGroupedBackground) // 시스템 그룹 배경색 사용
                .ignoresSafeArea() // 안전 영역 무시하고 전체 채우기
            
            // 메인 스크롤뷰
            ScrollView(showsIndicators: false) { // 스크롤 인디케이터 숨김
                VStack(spacing: 32) { // 수직 스택 (32포인트 간격)
                    // 헤더 (스크롤 오프셋 추적용)
                    headerSection // 헤더 섹션
                        .background( // 배경에 지오메트리 리더 추가
                            GeometryReader { geometry in // 지오메트리 변화 감지
                                Color.clear // 투명한 색상
                                    .onAppear { // 뷰가 나타날 때
                                        scrollOffset = geometry.frame(in: .global).minY // 초기 스크롤 오프셋 설정
                                    }
                                    .onChange(of: geometry.frame(in: .global).minY) { value in // 프레임 변화 감지
                                        scrollOffset = value // 스크롤 오프셋 업데이트
                                    }
                            }
                        )
                    
                    // 차트 메인 섹션
                    chartMainSection // 차트 메인 섹션
                    
                    // 인사이트 카드들
                    insightCardsSection // 인사이트 카드 섹션
                    
                    // 카테고리 상세 리스트
                    categoryDetailSection // 카테고리 상세 섹션
                    
                    Spacer(minLength: 50) // 최소 50포인트 여백 추가
                }
                .padding(.horizontal, 20) // 좌우 20포인트 패딩
                .padding(.top, 10) // 상단 10포인트 패딩
            }
            .coordinateSpace(name: "scroll") // 스크롤 좌표 공간 설정
            
            // 상단 네비게이션 바 (스크롤 시 나타남)
            VStack { // 수직 스택
                ZStack { // 레이아웃 겹치기
                    // 블러 배경
                    Rectangle() // 사각형 배경
                        .fill(.ultraThinMaterial) // 울트라 얇은 머티리얼 효과
                        .ignoresSafeArea(edges: .top) // 상단 안전 영역 무시
                    
                    // 네비게이션 내용
                    HStack { // 수평 스택
                        Text("분석") // 제목 텍스트
                            .font(.system(size: 17, weight: .semibold)) // 17포인트 세미볼드 폰트
                            .foregroundColor(.primary) // 기본 전경색
                        
                        Spacer() // 공간 채우기
                        
                        // 액션 버튼들 (심플 버전)
                        HStack(spacing: 8) { // 수평 스택 (8포인트 간격)
                            // 정렬 메뉴
                            Menu { // 드롭다운 메뉴
                                Button("기본 순서") { animateSortChange(to: .defaultOrder) } // 기본 순서 버튼
                                Button("높은 금액순") { animateSortChange(to: .highToLow) } // 높은 금액순 버튼
                                Button("낮은 금액순") { animateSortChange(to: .lowToHigh) } // 낮은 금액순 버튼
                            } label: { // 메뉴 라벨
                                Image(systemName: "slider.horizontal.3") // 슬라이더 아이콘
                                    .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                                    .foregroundColor(.primary) // 기본 전경색
                                    .frame(width: 32, height: 32) // 32x32 프레임
                                    .background(Circle().fill(Color(.systemGray6))) // 원형 배경
                            }
                            
                            // 리셋 버튼
                            Button(action: resetAll) { // 리셋 액션
                                Image(systemName: "arrow.clockwise") // 새로고침 아이콘
                                    .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                                    .foregroundColor(.primary) // 기본 전경색
                                    .frame(width: 32, height: 32) // 32x32 프레임
                                    .background(Circle().fill(Color(.systemGray6))) // 원형 배경
                            }
                        }
                    }
                    .padding(.horizontal, 20) // 좌우 20포인트 패딩
                    .padding(.bottom, 8) // 하단 8포인트 패딩
                }
                .frame(height: 44) // 44포인트 높이 고정
                .opacity(scrollOffset < -60 ? 1 : 0) // 스크롤 오프셋에 따른 투명도 조절
                .animation(.easeInOut(duration: 0.2), value: scrollOffset) // 스크롤 오프셋 변화 애니메이션
                
                Spacer() // 공간 채우기
            }
        }
        .sheet(isPresented: $vm.isShowingYearMonthPicker) { // 시트 모달 표시
            YearMonthPickerView( // 연월 선택 뷰
                viewModel: viewModel, // 뷰모델 전달
                selectedYear: $vm.selectedYear, // 선택된 년도 바인딩
                selectedMonth: $vm.selectedMonth, // 선택된 월 바인딩
                showingPicker: $vm.isShowingYearMonthPicker, // 피커 표시 상태 바인딩
                onComplete: { year, month in // 완료 콜백
                    vm.setYearMonth(year: year, month: month) // 년월 설정
                }
            )
        }
        .onAppear { // 뷰가 나타날 때
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3초 지연 후
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { // 스프링 애니메이션
                    animateChart = true // 차트 애니메이션 시작
                }
            }
        }
    }
    
    // MARK: - 헤더 부분
    private var headerSection: some View { // 헤더 섹션 뷰
        HStack { // 수평 스택
            VStack(alignment: .leading, spacing: 4) { // 수직 스택 (왼쪽 정렬, 4포인트 간격)
                Text("지출 분석") // 제목
                    .font(.system(size: 32, weight: .bold)) // 32포인트 볼드 폰트
                    .foregroundColor(.primary) // 기본 전경색
                
                Button(action: { vm.isShowingYearMonthPicker = true }) { // 연월 선택 버튼
                    HStack(spacing: 6) { // 수평 스택 (6포인트 간격)
                        Text("\(vm.formatYear(vm.selectedYear))년 \(vm.selectedMonth)월") // 선택된 연월 표시
                            .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                            .foregroundColor(.secondary) // 보조 전경색
                        
                        Image(systemName: "chevron.down") // 아래 화살표 아이콘
                            .font(.system(size: 12, weight: .medium)) // 12포인트 미디엄 폰트
                            .foregroundColor(.secondary) // 보조 전경색
                    }
                }
            }
            
            Spacer() // 공간 채우기
            
            // 심플한 액션 버튼들
            HStack(spacing: 8) { // 수평 스택 (8포인트 간격)
                // 정렬 메뉴
                Menu { // 드롭다운 메뉴
                    Button("기본 순서") { animateSortChange(to: .defaultOrder) } // 기본 순서
                    Button("높은 금액순") { animateSortChange(to: .highToLow) } // 높은 금액순
                    Button("낮은 금액순") { animateSortChange(to: .lowToHigh) } // 낮은 금액순
                } label: { // 메뉴 라벨
                    Image(systemName: "slider.horizontal.3") // 슬라이더 아이콘
                        .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                        .foregroundColor(.primary) // 기본 전경색
                        .frame(width: 40, height: 40) // 40x40 프레임
                        .background( // 배경
                            Circle() // 원형
                                .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                        )
                }
                
                // 리셋 버튼
                Button(action: resetAll) { // 리셋 액션
                    Image(systemName: "arrow.clockwise") // 새로고침 아이콘
                        .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                        .foregroundColor(.primary) // 기본 전경색
                        .frame(width: 40, height: 40) // 40x40 프레임
                        .background( // 배경
                            Circle() // 원형
                                .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                        )
                }
            }
        }
    }
    
    // MARK: - 차트 메인 섹션
    private var chartMainSection: some View { // 차트 메인 섹션 뷰
        VStack(spacing: 24) { // 수직 스택 (24포인트 간격)
            // 선택된 카테고리 헤더
            if let selected = selectedCategory { // 선택된 카테고리가 있을 때
                selectedCategoryHeader(selected) // 선택된 카테고리 헤더 표시
                    .transition(.asymmetric( // 비대칭 트랜지션
                        insertion: .move(edge: .top).combined(with: .opacity), // 삽입 시 위에서 나타남
                        removal: .move(edge: .top).combined(with: .opacity) // 제거 시 위로 사라짐
                    ))
            }
            
            // 차트 컨테이너
            ZStack { // 레이아웃 겹치기
                // 심플한 배경 카드
                RoundedRectangle(cornerRadius: 20) // 둥근 사각형 (20포인트 반지름)
                    .fill(Color(.systemBackground)) // 시스템 배경색
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4) // 그림자 효과
                
                if vm.filteredExpenses.isEmpty { // 필터된 지출이 없을 때
                    EmptyChartView() // 빈 차트 뷰 표시
                        .frame(height: 280) // 280포인트 높이
                } else { // 지출 데이터가 있을 때
                    VStack(spacing: 20) { // 수직 스택 (20포인트 간격)
                        // 중앙 통계
                        centerStats // 중앙 통계 뷰
                        
                        // 차트
                        CleanPieChart( // 깔끔한 파이 차트
                            data: Dictionary(uniqueKeysWithValues: vm.sortedCategoryTotals.map { ($0.category, $0.total) }), // 카테고리별 총액 데이터
                            highlightedCategory: selectedCategory // 강조할 카테고리
                        )
                        .frame(height: 200) // 200포인트 높이
                        .scaleEffect(animateChart ? 1.0 : 0.8) // 애니메이션 스케일 효과
                        .opacity(animateChart ? 1.0 : 0.0) // 애니메이션 투명도 효과
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateChart) // 스프링 애니메이션 (0.2초 지연)
                    }
                    .padding(24) // 24포인트 패딩
                }
            }
        }
    }
    
    private var centerStats: some View { // 중앙 통계 뷰
        VStack(spacing: 8) { // 수직 스택 (8포인트 간격)
            Text("총 지출") // 총 지출 라벨
                .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                .foregroundColor(.secondary) // 보조 전경색
            
            Text(FormatHelper.formatAmount(vm.totalAmount)) // 포맷된 총 금액
                .font(.system(size: 24, weight: .bold, design: .rounded)) // 24포인트 볼드 라운드 폰트
                .foregroundColor(.primary) // 기본 전경색
            
            Text("\(vm.filteredExpenses.count)건의 지출") // 지출 건수
                .font(.system(size: 12, weight: .medium)) // 12포인트 미디엄 폰트
                .foregroundColor(.secondary) // 보조 전경색
        }
    }
    
    private func selectedCategoryHeader(_ category: String) -> some View { // 선택된 카테고리 헤더 뷰
        let categoryTotal = vm.sortedCategoryTotals.first { $0.category == category } // 선택된 카테고리의 총액 찾기
        let percentage = vm.totalAmount > 0 ? ((categoryTotal?.total ?? 0) / vm.totalAmount) * 100 : 0 // 백분율 계산
        
        return HStack { // 수평 스택 반환
            HStack(spacing: 12) { // 수평 스택 (12포인트 간격)
                // 카테고리 아이콘 (단순화)
                ZStack { // 레이아웃 겹치기
                    Circle() // 원형
                        .fill(categoryColor(for: category).opacity(0.1)) // 카테고리 색상 (투명도 0.1)
                        .frame(width: 44, height: 44) // 44x44 프레임
                    
                    Image(systemName: categoryIcon(for: category)) // 카테고리 아이콘
                        .font(.system(size: 18, weight: .medium)) // 18포인트 미디엄 폰트
                        .foregroundColor(categoryColor(for: category)) // 카테고리 색상
                }
                
                VStack(alignment: .leading, spacing: 4) { // 수직 스택 (왼쪽 정렬, 4포인트 간격)
                    Text(category) // 카테고리 이름
                        .font(.system(size: 18, weight: .semibold)) // 18포인트 세미볼드 폰트
                        .foregroundColor(.primary) // 기본 전경색
                    
                    HStack(spacing: 8) { // 수평 스택 (8포인트 간격)
                        Text("\(String(format: "%.1f", percentage))%") // 백분율 표시
                            .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                            .foregroundColor(categoryColor(for: category)) // 카테고리 색상
                        
                        Text("•") // 구분자
                            .foregroundColor(.secondary) // 보조 전경색
                        
                        Text(FormatHelper.formatAmount(categoryTotal?.total ?? 0)) // 포맷된 총액
                            .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                            .foregroundColor(.secondary) // 보조 전경색
                    }
                }
            }
            
            Spacer() // 공간 채우기
            
            Button(action: { // 닫기 버튼
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { // 스프링 애니메이션
                    selectedCategory = nil // 선택된 카테고리 초기화
                }
            }) {
                Image(systemName: "xmark.circle.fill") // X 아이콘
                    .font(.system(size: 20)) // 20포인트 폰트
                    .foregroundColor(.secondary) // 보조 전경색
            }
        }
        .padding(.horizontal, 20) // 좌우 20포인트 패딩
        .padding(.vertical, 16) // 상하 16포인트 패딩
        .background( // 배경
            RoundedRectangle(cornerRadius: 12) // 둥근 사각형 (12포인트 반지름)
                .fill(Color(.systemGray6).opacity(0.5)) // 시스템 그레이6 (투명도 0.5)
        )
    }
    
    // MARK: - 한눈에 보기 섹션
    private var insightCardsSection: some View { // 인사이트 카드 섹션 뷰
        VStack(spacing: 16) { // 수직 스택 (16포인트 간격)
            HStack { // 수평 스택
                Text("한눈에 보기") // 섹션 제목
                    .font(.system(size: 18, weight: .semibold)) // 18포인트 세미볼드 폰트
                    .foregroundColor(.primary) // 기본 전경색
                
                Spacer() // 공간 채우기
            }
            
            HStack(spacing: 12) { // 수평 스택 (12포인트 간격)
                // 가장 많이 쓴 카테고리
                SimpleInsightCard( // 단순한 인사이트 카드
                    title: "최고 지출", // 제목
                    value: topCategory?.category ?? "없음", // 최고 지출 카테고리 (없으면 "없음")
                    subtitle: FormatHelper.formatAmount(topCategory?.total ?? 0) // 포맷된 금액
                )
                
                // 평균 지출
                SimpleInsightCard( // 단순한 인사이트 카드
                    title: "평균 지출", // 제목
                    value: vm.filteredExpenses.isEmpty ? "0원" : FormatHelper.formatAmount(vm.totalAmount / Double(vm.filteredExpenses.count)), // 평균 계산 (빈 경우 0원)
                    subtitle: "건당 평균" // 부제목
                )
            }
        }
    }
    
    private var topCategory: CategoryTotal? { // 최고 지출 카테고리 계산
        vm.sortedCategoryTotals.filter { $0.total > 0 }.max { $0.total < $1.total } // 0보다 큰 총액 중 최대값
    }
    
    // MARK: - 카테고리 상세 내역 섹션
    private var categoryDetailSection: some View { // 카테고리 상세 섹션 뷰
        VStack(spacing: 16) { // 수직 스택 (16포인트 간격)
            HStack { // 수평 스택
                Text("상세 내역") // 섹션 제목
                    .font(.system(size: 18, weight: .semibold)) // 18포인트 세미볼드 폰트
                    .foregroundColor(.primary) // 기본 전경색
                
                Spacer() // 공간 채우기
                
                if vm.sortedCategoryTotals.count > maxVisibleItems { // 최대 표시 항목보다 많을 때
                    Button(action: { // 더보기/접기 버튼
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { // 스프링 애니메이션
                            showAllCategories.toggle() // 모든 카테고리 표시 토글
                        }
                    }) {
                        HStack(spacing: 4) { // 수평 스택 (4포인트 간격)
                            Text(showAllCategories ? "접기" : "더보기") // 상태에 따른 텍스트
                                .font(.system(size: 12, weight: .medium)) // 12포인트 미디엄 폰트
                            
                            Image(systemName: showAllCategories ? "chevron.up" : "chevron.down") // 상태에 따른 아이콘
                                .font(.system(size: 10, weight: .medium)) // 10포인트 미디엄 폰트
                        }
                        .foregroundColor(.primary) // 기본 전경색
                        .padding(.horizontal, 10) // 좌우 10포인트 패딩
                        .padding(.vertical, 6) // 상하 6포인트 패딩
                        .background( // 배경
                            RoundedRectangle(cornerRadius: 8) // 둥근 사각형 (8포인트 반지름)
                                .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                        )
                    }
                }
            }
            
            LazyVStack(spacing: 8) { // 지연 로딩 수직 스택 (8포인트 간격)
                ForEach(Array(visibleCategories.enumerated()), id: \.element.category) { index, categoryTotal in // 표시할 카테고리 반복
                    CleanCategoryRow( // 깔끔한 카테고리 행
                        categoryTotal: categoryTotal, // 카테고리 총액
                        isSelected: selectedCategory == categoryTotal.category, // 선택 여부
                        totalAmount: vm.totalAmount, // 전체 금액
                        animationDelay: Double(index) * 0.1 // 애니메이션 지연 (인덱스 * 0.1초)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { // 스프링 애니메이션
                            if selectedCategory == categoryTotal.category { // 이미 선택된 카테고리면
                                selectedCategory = nil // 선택 해제
                            } else if categoryTotal.total > 0 { // 지출이 있는 카테고리면
                                selectedCategory = categoryTotal.category // 선택
                            }
                        }
                    }
                }
            }
            .opacity(showList ? 1 : 0) // 리스트 표시 상태에 따른 투명도
            .animation(.easeInOut(duration: 0.4), value: showList) // 리스트 표시 애니메이션
        }
    }
    
    // MARK: - 카테고리 표시 속성 및 설정 메서드
    private var visibleCategories: [CategoryTotal] { // 표시할 카테고리 목록
        if showAllCategories { // 모든 카테고리 표시 상태면
            return vm.sortedCategoryTotals // 전체 카테고리 반환
        } else {
            return Array(vm.sortedCategoryTotals.prefix(maxVisibleItems)) // 최대 표시 개수만큼 반환
        }
    }
    
    private func categoryColor(for category: String) -> Color { // 카테고리별 색상 반환
        switch category {
        case "식비": return .red // 식비는 빨간색
        case "교통": return .blue // 교통은 파란색
        case "쇼핑": return .green // 쇼핑은 녹색
        case "여가": return .orange // 여가는 주황색
        case "기타": return .purple // 기타는 보라색
        default: return .gray // 그 외는 회색
        }
    }
    
    private func categoryIcon(for category: String) -> String { // 카테고리별 아이콘 반환
        switch category {
        case "식비": return "fork.knife" // 식비는 포크나이프 아이콘
        case "교통": return "car.fill" // 교통은 자동차 아이콘
        case "쇼핑": return "bag.fill" // 쇼핑은 가방 아이콘
        case "여가": return "gamecontroller.fill" // 여가는 게임컨트롤러 아이콘
        case "기타": return "ellipsis" // 기타는 점 3개 아이콘
        default: return "questionmark" // 그 외는 물음표 아이콘
        }
    }
    
    private func resetAll() { // 전체 리셋 함수
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { // 스프링 애니메이션
            showChart = false // 차트 숨기기
            showList = false // 리스트 숨기기
            selectedCategory = nil // 선택된 카테고리 초기화
            animateChart = false // 차트 애니메이션 초기화
        }
        vm.resetToCurrentDate() // 뷰모델 날짜 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3초 지연 후
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { // 스프링 애니메이션
                showChart = true // 차트 다시 표시
                showList = true // 리스트 다시 표시
                animateChart = true // 차트 애니메이션 시작
            }
        }
    }
    
    private func animateSortChange(to order: ChartViewModel.SortOrder) { // 정렬 변경 애니메이션 함수
        withAnimation(.easeInOut(duration: 0.3)) { // 이즈인아웃 애니메이션
            showList = false // 리스트 숨기기
            selectedCategory = nil // 선택된 카테고리 초기화
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3초 지연 후
            vm.sortOrder = order // 정렬 순서 변경
            withAnimation(.easeInOut(duration: 0.3)) { // 이즈인아웃 애니메이션
                showList = true // 리스트 다시 표시
            }
        }
    }
}

// MARK: - 카테고리 선택 및 백분율
struct CleanCategoryRow: View { // 깔끔한 카테고리 행 뷰
    let categoryTotal: CategoryTotal // 카테고리 총액
    let isSelected: Bool // 선택 여부
    let totalAmount: Double // 전체 금액
    let animationDelay: Double // 애니메이션 지연
    let onTap: () -> Void // 탭 액션
    
    @State private var isVisible = false // 표시 여부 상태
    
    private var percentage: Double { // 백분율 계산
        guard totalAmount > 0 else { return 0 } // 전체 금액이 0이면 0 반환
        return (categoryTotal.total / totalAmount) * 100 // 백분율 계산
    }
    
    private var categoryColor: Color { // 카테고리 색상
        switch categoryTotal.category {
        case "식비": return .red // 식비는 빨간색
        case "교통": return .blue // 교통은 파란색
        case "쇼핑": return .green // 쇼핑은 녹색
        case "여가": return .orange // 여가는 주황색
        case "기타": return .purple // 기타는 보라색
        default: return .gray // 그 외는 회색
        }
    }
    
    private var categoryIcon: String { // 카테고리 아이콘
        switch categoryTotal.category {
        case "식비": return "fork.knife" // 식비는 포크나이프 아이콘
        case "교통": return "car.fill" // 교통은 자동차 아이콘
        case "쇼핑": return "bag.fill" // 쇼핑은 가방 아이콘
        case "여가": return "gamecontroller.fill" // 여가는 게임컨트롤러 아이콘
        case "기타": return "ellipsis" // 기타는 점 3개 아이콘
        default: return "questionmark" // 그 외는 물음표 아이콘
        }
    }
    
    private var hasExpense: Bool { // 지출 여부 확인
        return categoryTotal.total > 0 // 총액이 0보다 크면 true
    }
    
    var body: some View {
        Button(action: onTap) { // 버튼으로 감싸기
            HStack(spacing: 16) { // 수평 스택 (16포인트 간격)
                // 단순한 아이콘
                ZStack { // 레이아웃 겹치기
                    Circle() // 원형
                        .fill(hasExpense ? categoryColor.opacity(0.1) : Color(.systemGray6)) // 지출 여부에 따른 색상
                        .frame(width: 44, height: 44) // 44x44 프레임
                    
                    Image(systemName: categoryIcon) // 카테고리 아이콘
                        .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                        .foregroundColor(hasExpense ? categoryColor : .secondary) // 지출 여부에 따른 색상
                }
                .scaleEffect(isSelected ? 1.05 : 1.0) // 선택 시 1.05배 확대
                .animation(.easeInOut(duration: 0.2), value: isSelected) // 선택 상태 애니메이션
                
                // 정보
                VStack(alignment: .leading, spacing: 6) { // 수직 스택 (왼쪽 정렬, 6포인트 간격)
                    HStack { // 수평 스택
                        Text(categoryTotal.category) // 카테고리 이름
                            .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                            .foregroundColor(.primary) // 기본 전경색
                        
                        Spacer() // 공간 채우기
                        
                        if hasExpense { // 지출이 있을 때
                            Text("\(String(format: "%.1f", percentage))%") // 백분율 표시
                                .font(.system(size: 12, weight: .medium)) // 12포인트 미디엄 폰트
                                .foregroundColor(.secondary) // 보조 전경색
                                .padding(.horizontal, 8) // 좌우 8포인트 패딩
                                .padding(.vertical, 3) // 상하 3포인트 패딩
                                .background( // 배경
                                    RoundedRectangle(cornerRadius: 6) // 둥근 사각형 (6포인트 반지름)
                                        .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                                )
                            
                            if isSelected { // 선택된 상태일 때
                                Circle() // 원형
                                    .fill(categoryColor) // 카테고리 색상
                                    .frame(width: 8, height: 8) // 8x8 프레임
                                    .transition(.scale.combined(with: .opacity)) // 스케일과 투명도 트랜지션
                            }
                        }
                    }
                    
                    Text(FormatHelper.formatAmount(categoryTotal.total)) // 포맷된 총액
                        .font(.system(size: 15, weight: .semibold, design: .rounded)) // 15포인트 세미볼드 라운드 폰트
                        .foregroundColor(hasExpense ? .primary : .secondary) // 지출 여부에 따른 색상
                    
                    // 단순한 프로그레스 바
                    if hasExpense { // 지출이 있을 때
                        GeometryReader { geometry in // 지오메트리 리더
                            ZStack(alignment: .leading) { // 왼쪽 정렬 ZStack
                                RoundedRectangle(cornerRadius: 2) // 둥근 사각형 (2포인트 반지름)
                                    .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                                    .frame(height: 4) // 4포인트 높이
                                
                                RoundedRectangle(cornerRadius: 2) // 둥근 사각형 (2포인트 반지름)
                                    .fill(categoryColor) // 카테고리 색상
                                    .frame(width: geometry.size.width * (percentage / 100), height: 4) // 백분율에 따른 너비, 4포인트 높이
                                    .animation(.easeInOut(duration: 1.0).delay(animationDelay), value: percentage) // 백분율 변화 애니메이션 (지연 적용)
                            }
                        }
                        .frame(height: 4) // 4포인트 높이
                    } else { // 지출이 없을 때
                        RoundedRectangle(cornerRadius: 2) // 둥근 사각형 (2포인트 반지름)
                            .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                            .frame(height: 4) // 4포인트 높이
                    }
                }
            }
            .padding(16) // 16포인트 패딩
            .background( // 배경
                RoundedRectangle(cornerRadius: 12) // 둥근 사각형 (12포인트 반지름)
                    .fill(Color(.systemBackground)) // 시스템 배경색
                    .overlay( // 오버레이
                        RoundedRectangle(cornerRadius: 12) // 둥근 사각형 (12포인트 반지름)
                            .stroke( // 테두리
                                isSelected ? categoryColor.opacity(0.3) : Color(.systemGray6), // 선택 상태에 따른 테두리 색상
                                lineWidth: 1 // 1포인트 두께
                            )
                    )
                    .shadow( // 그림자
                        color: Color.black.opacity(0.06), // 검은색 투명도 0.06
                        radius: 6, // 6포인트 반지름
                        x: 0, // X 오프셋 0
                        y: 2 // Y 오프셋 2
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0) // 선택 시 1.01배 확대
            .animation(.easeInOut(duration: 0.2), value: isSelected) // 선택 상태 애니메이션
        }
        .buttonStyle(PlainButtonStyle()) // 플레인 버튼 스타일
        .disabled(!hasExpense) // 지출이 없으면 비활성화
        .opacity(isVisible ? 1 : 0) // 표시 상태에 따른 투명도
        .offset(y: isVisible ? 0 : 15) // 표시 상태에 따른 Y 오프셋
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible) // 표시 상태 애니메이션 (지연 적용)
        .onAppear { // 뷰가 나타날 때
            isVisible = true // 표시 상태를 true로 설정
        }
    }
}

// MARK: - 카테고리 카드 속성
struct SimpleInsightCard: View { // 단순한 인사이트 카드 뷰
    let title: String // 제목
    let value: String // 값
    let subtitle: String // 부제목
    
    var body: some View {
        VStack(spacing: 8) { // 수직 스택 (8포인트 간격)
            Text(title) // 제목
                .font(.system(size: 12, weight: .medium)) // 12포인트 미디엄 폰트
                .foregroundColor(.secondary) // 보조 전경색
            
            Text(value) // 값
                .font(.system(size: 16, weight: .semibold)) // 16포인트 세미볼드 폰트
                .foregroundColor(.primary) // 기본 전경색
                .lineLimit(1) // 1줄로 제한
                .minimumScaleFactor(0.8) // 최소 스케일 0.8
            
            Text(subtitle) // 부제목
                .font(.system(size: 11, weight: .medium)) // 11포인트 미디엄 폰트
                .foregroundColor(.secondary) // 보조 전경색
                .lineLimit(1) // 1줄로 제한
        }
        .frame(maxWidth: .infinity) // 최대 너비로 확장
        .padding(16) // 16포인트 패딩
        .background( // 배경
            RoundedRectangle(cornerRadius: 12) // 둥근 사각형 (12포인트 반지름)
                .fill(Color(.systemBackground)) // 시스템 배경색
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2) // 그림자 효과
        )
    }
}

// MARK: - 빈 차트 뷰
struct EmptyChartView: View { // 빈 차트 뷰
    @State private var isAnimating = false // 애니메이션 상태
    
    var body: some View {
        VStack(spacing: 20) { // 수직 스택 (20포인트 간격)
            ZStack { // 레이아웃 겹치기
                Circle() // 원형
                    .stroke(Color(.systemGray5), lineWidth: 2) // 시스템 그레이5 테두리 (2포인트 두께)
                    .frame(width: 100, height: 100) // 100x100 프레임
                
                Circle() // 원형
                    .trim(from: 0, to: isAnimating ? 0.7 : 0) // 애니메이션 상태에 따른 트림
                    .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 2, lineCap: .round)) // 시스템 그레이4 테두리 (라운드 캡)
                    .frame(width: 100, height: 100) // 100x100 프레임
                    .rotationEffect(.degrees(-90)) // -90도 회전
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating) // 2초 이즈인아웃 애니메이션 (무한 반복, 자동 역방향)
                
                Image(systemName: "chart.pie") // 파이 차트 아이콘
                    .font(.system(size: 24, weight: .light)) // 24포인트 라이트 폰트
                    .foregroundColor(.secondary) // 보조 전경색
            }
            
            VStack(spacing: 8) { // 수직 스택 (8포인트 간격)
                Text("지출 내역 없음") // 메인 메시지
                    .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                    .foregroundColor(.primary) // 기본 전경색
                
                Text("지출을 추가하면 차트가 나타납니다") // 보조 메시지
                    .font(.system(size: 13, weight: .medium)) // 13포인트 미디엄 폰트
                    .foregroundColor(.secondary.opacity(0.8)) // 보조 전경색 (투명도 0.8)
                    .multilineTextAlignment(.center) // 중앙 정렬
            }
        }
        .frame(height: 280) // 280포인트 높이
        .onAppear { // 뷰가 나타날 때
            isAnimating = true // 애니메이션 시작
        }
    }
}

// MARK: - 원형 차트 속성
struct CleanPieChart: View { // 깔끔한 파이 차트 뷰
    let data: [String: Double] // 데이터 (카테고리: 금액)
    let highlightedCategory: String? // 강조할 카테고리
    
    private func categoryColor(for category: String) -> Color { // 카테고리별 색상 함수
        switch category {
        case "식비": return .red // 식비는 빨간색
        case "교통": return .blue // 교통은 파란색
        case "쇼핑": return .green // 쇼핑은 녹색
        case "여가": return .orange // 여가는 주황색
        case "기타": return .purple // 기타는 보라색
        default: return .gray // 그 외는 회색
        }
    }
    
    private func categoryOpacity(for category: String) -> Double { // 카테고리별 투명도 함수
        guard let highlighted = highlightedCategory else { return 1.0 } // 강조할 카테고리가 없으면 1.0
        return category == highlighted ? 1.0 : 0.4 // 강조할 카테고리는 1.0, 나머지는 0.4
    }
    
    private func outerRadius(for category: String) -> Double { // 카테고리별 외부 반지름 함수
        guard let highlighted = highlightedCategory else { return 0.8 } // 강조할 카테고리가 없으면 0.8
        return category == highlighted ? 0.85 : 0.8 // 강조할 카테고리는 0.85, 나머지는 0.8
    }
    
    var body: some View {
        Chart { // 차트
            ForEach(data.keys.sorted(), id: \.self) { category in // 정렬된 카테고리 키들을 반복
                SectorMark( // 섹터 마크 (파이 차트 조각)
                    angle: .value("Amount", data[category] ?? 0.0), // 각도 (금액에 비례)
                    innerRadius: .ratio(0.6), // 내부 반지름 (0.6 비율)
                    outerRadius: .ratio(outerRadius(for: category)), // 외부 반지름 (카테고리별)
                    angularInset: 1.5 // 각도 간격 (1.5포인트)
                )
                .foregroundStyle(categoryColor(for: category)) // 카테고리별 색상
                .opacity(categoryOpacity(for: category)) // 카테고리별 투명도
            }
        }
        .animation(.easeInOut(duration: 0.3), value: highlightedCategory) // 강조 카테고리 변화 애니메이션
    }
}
