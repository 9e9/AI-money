//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Combine // Combine 프레임워크 임포트 - 리액티브 프로그래밍 및 퍼블리셔 패턴 사용

/// 지출 추가 및 편집 화면을 담당하는 메인 뷰
/// 여러 지출 항목을 카드 형태로 관리하며, 카테고리별로 분류하여 입력할 수 있음
struct AddExpenseView: View {
    // MARK: - 외부 의존성 및 환경 변수
    @ObservedObject var viewModel: ExpenseCalendarViewModel // 캘린더 뷰모델 관찰 - 지출 데이터 관리 및 캘린더 상태 동기화
    @StateObject private var vm = AddExpenseViewModel() // 지출 추가 전용 뷰모델 - 이 화면의 상태와 로직을 담당
    @Environment(\.presentationMode) var presentationMode // 화면 닫기를 위한 SwiftUI 환경 변수
    
    // MARK: - 로컬 상태 변수들
    @State private var deletingIndex: Int? = nil // 현재 삭제 대상 항목의 인덱스 (nil이면 삭제 진행 중이 아님)
    @State private var showCategoryManagement = false // 카테고리 관리 시트 표시 여부 제어
    @State private var isEditing = false // 편집 모드 활성화 상태 (편집 모드에서만 삭제/복사 버튼 표시)
    @State private var keyboardHeight: CGFloat = 0 // 현재 키보드의 높이 추적 (UI 레이아웃 조정용)
    @State private var focusedCardIndex: Int? = nil // 현재 사용자가 포커스한 카드의 인덱스 (시각적 강조 및 스크롤 제어)
    
    // MARK: - 입력 파라미터
    var selectedDate: Date // 부모 뷰에서 전달받은 선택된 날짜 (지출이 발생한 날짜)

    var body: some View {
        NavigationView { // iOS 네비게이션 구조 제공 (상단 바, 타이틀 등)
            GeometryReader { geometry in // 화면 크기와 안전 영역 정보를 얻기 위한 컨테이너
                ZStack { // 여러 뷰를 겹쳐서 배치하는 컨테이너 (배경 + 메인 컨텐츠 + 플로팅 바)
                    // 배경색 설정 (시스템 그룹화된 배경색 사용으로 라이트/다크 모드 자동 대응)
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea() // 안전 영역까지 배경색 확장
                    
                    // 스크롤 위치를 프로그래밍적으로 제어하기 위한 ScrollViewReader
                    ScrollViewReader { scrollProxy in
                        ScrollView { // 세로 스크롤 가능한 컨테이너
                            // 성능 최적화를 위한 LazyVStack 사용 (화면에 보이는 부분만 렌더링)
                            LazyVStack(spacing: 20) {
                                // 화면 상단의 헤더 섹션 (제목, 날짜, 저장 상태 표시)
                                headerSection
                                    .padding(.top, 20) // 상단 여백 추가
                                
                                // 조건부 렌더링: 총 지출이 0보다 클 때만 요약 카드 표시
                                if vm.totalAmount > 0 {
                                    summaryCard
                                }
                                
                                // 각 지출 그룹(카드)을 동적으로 생성하여 표시
                                ForEach(vm.expenseGroups.indices, id: \.self) { index in
                                    AddExpenseCardView(
                                        // 양방향 데이터 바인딩으로 각 그룹의 데이터 전달
                                        group: $vm.expenseGroups[index],
                                        index: index, // 카드 순번
                                        selectedDate: selectedDate, // 선택된 날짜
                                        isEditing: isEditing, // 편집 모드 여부
                                        allCategories: vm.allCategories, // 사용 가능한 카테고리 목록
                                        expenseGroupCount: vm.expenseGroups.count, // 전체 카드 개수
                                        isFocused: focusedCardIndex == index, // 현재 카드가 포커스되었는지 확인
                                        
                                        // 콜백 함수들 - 자식 뷰에서 발생한 이벤트를 부모에서 처리
                                        onDelete: { idx in handleDelete(at: idx) }, // 삭제 버튼 클릭 시
                                        onDuplicate: { idx in vm.duplicateGroup(at: idx) }, // 복사 버튼 클릭 시
                                        onFocus: { idx in // 카드 포커스 변경 시
                                            focusedCardIndex = idx
                                            // 부드러운 애니메이션과 함께 포커스된 카드로 스크롤 이동
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                scrollProxy.scrollTo(idx, anchor: .center)
                                            }
                                        },
                                        onApplyQuickAmount: { amount, idx in // 빠른 금액 선택 시
                                            vm.applyQuickAmount(amount, to: idx)
                                        },
                                        onShowCategoryManagement: { showCategoryManagement = true }, // 카테고리 관리 버튼 클릭 시
                                        onAmountChange: { newValue, idx in // 금액 입력 변경 시
                                            vm.updateAmountFormatting(at: idx, newValue: newValue)
                                        }
                                    )
                                    .id(index) // 스크롤 위치 식별을 위한 고유 ID 설정
                                    .padding(.horizontal, 20) // 좌우 여백
                                }
                                
                                // 키보드와 하단 플로팅 바를 위한 충분한 여백 확보
                                Spacer().frame(height: 100)
                            }
                        }
                        .scrollDismissesKeyboard(.immediately) // 스크롤 시 키보드 즉시 숨김
                    }
                    
                    // 화면 하단의 플로팅 액션 바 (추가 버튼 + 저장 버튼)
                    simpleFloatingBar
                        // 키보드 높이에 따라 플로팅 바 위치 동적 조정
                        .offset(y: -max(0, keyboardHeight - geometry.safeAreaInsets.bottom))
                }
            }
            .navigationTitle("지출 추가") // 네비게이션 바 타이틀 설정
            .navigationBarTitleDisplayMode(.inline) // 타이틀을 인라인 형태로 표시 (작게)
            .toolbar { toolbarContent } // 네비게이션 바 버튼들 구성
            
            // 각종 알림창 표시 (삭제 확인, 나가기 확인 등)
            .alert(vm.alertTitle, isPresented: $vm.showingAlert) {
                alertButtons // 알림창 버튼들을 동적으로 생성
            } message: {
                Text(vm.alertMessage) // 알림창 메시지 내용
            }
            
            // 카테고리 관리 화면을 시트 형태로 표시
            .sheet(isPresented: $showCategoryManagement, onDismiss: vm.updateCategories) {
                CategoryManagementView() // 카테고리 관리 전용 뷰
            }
            .overlay(saveOverlay) // 저장 완료 시 표시되는 오버레이 UI
            
            // 키보드 높이 변화를 감지하여 UI 조정
            .onReceive(keyboardPublisher) { height in
                withAnimation(.easeInOut(duration: 0.3)) { // 부드러운 애니메이션 적용
                    keyboardHeight = height
                }
            }
            
            // 뷰가 처음 나타날 때 초기 설정 수행
            .onAppear {
                vm.updateCategories() // 최신 카테고리 목록 로드
                focusedCardIndex = 0  // 첫 번째 카드에 초기 포커스 설정
            }
        }
    }
    
    // MARK: - 상단 헤더 섹션 UI 구성
    /// 화면 제목, 선택된 날짜, 저장 상태를 표시하는 헤더 영역
    private var headerSection: some View {
        VStack(spacing: 12) { // 세로 방향 스택 (12포인트 간격)
            HStack { // 가로 방향 스택
                VStack(alignment: .leading, spacing: 4) { // 왼쪽 정렬 세로 스택
                    // 메인 제목 텍스트
                    Text("지출 추가")
                        .font(.system(size: 24, weight: .bold)) // 24포인트 굵은 글꼴
                        .foregroundColor(.primary) // 기본 텍스트 색상 (시스템 다크모드 대응)
                    
                    // 선택된 날짜를 포맷팅하여 표시
                    Text(vm.formatSelectedDate(selectedDate))
                        .font(.system(size: 16, weight: .medium)) // 16포인트 중간 굵기
                        .foregroundColor(.secondary) // 보조 텍스트 색상 (회색 계열)
                }
                
                Spacer() // 남은 공간을 모두 차지하여 왼쪽 정렬 효과
            }
            
            // 조건부 렌더링: 저장되지 않은 변경사항이 있을 때만 경고 표시
            if vm.hasUnsavedChanges {
                HStack {
                    // 주의를 끌기 위한 작은 주황색 원형 아이콘
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8)) // 8포인트 크기
                        .foregroundColor(.orange) // 주황색
                    
                    Text("저장되지 않음")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange) // 아이콘과 동일한 주황색
                    
                    Spacer() // 왼쪽 정렬
                }
                .transition(.opacity) // 나타나고 사라질 때 투명도 애니메이션
            }
        }
        .padding(.horizontal, 20) // 좌우 20포인트 여백
    }
    
    // MARK: - 총 지출 요약 카드 UI
    /// 현재 입력된 지출들의 총합과 개수를 표시하는 요약 카드
    private var summaryCard: some View {
        HStack { // 가로 방향 레이아웃
            VStack(alignment: .leading, spacing: 4) { // 왼쪽 정렬 세로 스택
                Text("총 지출") // 라벨
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 총 금액을 포맷팅하여 표시 (예: "123,456원")
                Text("\(vm.formatAmount(vm.totalAmount))원")
                    .font(.system(size: 20, weight: .bold, design: .rounded)) // 둥근 숫자 폰트로 가독성 향상
                    .foregroundColor(.primary)
            }
            
            Spacer() // 중간 공간
            
            // 유효한 지출 항목의 개수 표시
            Text("\(vm.validExpenseCount)개")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(20) // 카드 내부 여백
        .background(
            // 카드 배경 및 테두리 스타일
            RoundedRectangle(cornerRadius: 12) // 12포인트 둥근 모서리
                .fill(Color(.systemBackground)) // 시스템 배경색
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1) // 1포인트 회색 테두리
                )
        )
        .padding(.horizontal, 20) // 좌우 여백
        .transition(.opacity) // 나타남/사라짐 애니메이션
    }
    
    // MARK: - 하단 플로팅 액션 바
    /// 지출 추가 버튼과 저장 버튼을 포함하는 플로팅 바
    private var simpleFloatingBar: some View {
        VStack { // 세로 스택으로 하단에 배치
            Spacer() // 상단 공간을 모두 차지하여 하단 고정
            
            HStack(spacing: 16) { // 가로 방향 16포인트 간격
                // 새 지출 항목 추가 버튼 (원형 플러스 버튼)
                Button(action: {
                    // 스프링 애니메이션과 함께 새 그룹 추가
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        vm.addGroup() // 뷰모델에 새 그룹 추가 요청
                        focusedCardIndex = vm.expenseGroups.count - 1 // 새로 추가된 마지막 카드에 포커스
                    }
                }) {
                    Image(systemName: "plus") // 플러스 아이콘
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44) // 44x44 터치 영역 확보
                        .background(
                            Circle()
                                .fill(Color(.systemGray6)) // 연한 회색 원형 배경
                        )
                }
                
                Spacer() // 버튼들 사이의 공간
                
                // 저장 버튼 (주요 액션 버튼)
                Button(action: handleSave) { // 저장 처리 함수 호출
                    HStack(spacing: 8) {
                        // 저장 진행 중일 때 로딩 스피너 표시
                        if vm.showingSaveAnimation {
                            ProgressView() // iOS 기본 로딩 인디케이터
                                .progressViewStyle(CircularProgressViewStyle(tint: .white)) // 흰색 스피너
                                .scaleEffect(0.8) // 크기를 80%로 축소
                        } else {
                            // 일반 상태에서는 "저장" 텍스트 표시
                            Text("저장")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white) // 흰색 텍스트
                    .padding(.horizontal, 32) // 좌우 32포인트 패딩
                    .padding(.vertical, 12) // 상하 12포인트 패딩
                    .background(
                        RoundedRectangle(cornerRadius: 22) // 22포인트 둥근 모서리 (알약 형태)
                            // 조건부 색상: 유효한 지출이 있으면 검은색, 없으면 회색
                            .fill(vm.hasValidExpenses ? Color.black : Color(.systemGray4))
                    )
                }
                // 조건부 비활성화: 유효한 지출이 없거나 저장 중일 때 터치 불가
                .disabled(!vm.hasValidExpenses || vm.showingSaveAnimation)
            }
            .padding(.horizontal, 20) // 좌우 여백
            .padding(.bottom, 20) // 하단 여백 (안전 영역 고려)
        }
    }
    
    // MARK: - 저장 완료 오버레이 UI
    /// 저장이 성공적으로 완료되었을 때 표시되는 전체 화면 오버레이
    private var saveOverlay: some View {
        Group { // 조건부 렌더링을 위한 그룹
            // 저장 애니메이션이 활성화된 경우에만 표시
            if vm.showingSaveAnimation {
                ZStack { // 겹쳐서 배치
                    // 반투명 어두운 배경
                    Color.black.opacity(0.3)
                        .ignoresSafeArea() // 전체 화면 덮기
                    
                    VStack(spacing: 20) { // 세로 스택 (20포인트 간격)
                        // 체크마크 아이콘이 있는 원형 배지
                        Circle()
                            .fill(Color.black) // 검은색 원형 배경
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "checkmark") // 체크마크 아이콘
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white) // 흰색 체크마크
                            )
                        
                        Text("저장 완료") // 완료 메시지
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(32) // 내부 여백
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThickMaterial) // iOS 15+ 블러 효과 (반투명 유리 느낌)
                    )
                }
                .transition(.opacity) // 나타남/사라짐 투명도 애니메이션
            }
        }
    }
    
    // MARK: - 네비게이션 바 툴바 구성
    /// 상단 네비게이션 바의 왼쪽/오른쪽 버튼들을 정의
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // 왼쪽 취소 버튼
        ToolbarItem(placement: .navigationBarLeading) {
            Button("취소") {
                handleCancel() // 취소 처리 함수 호출
            }
            .font(.system(size: 16, weight: .medium))
        }
        
        // 오른쪽 편집/완료 토글 버튼
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(isEditing ? "완료" : "편집") { // 현재 모드에 따라 버튼 텍스트 변경
                // 편집 모드 상태를 부드럽게 토글
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditing.toggle()
                }
            }
            .font(.system(size: 16, weight: .medium))
            // 편집 모드일 때 주황색, 일반 모드일 때 검은색
            .foregroundColor(isEditing ? .orange : .black)
        }
    }
    
    // MARK: - 동적 알림창 버튼 생성
    /// 알림창의 종류에 따라 적절한 버튼들을 동적으로 생성
    @ViewBuilder
    private var alertButtons: some View {
        // 지출 항목 삭제 확인 알림창
        if deletingIndex != nil {
            Button("삭제", role: .destructive) { // 파괴적 액션 (빨간색 표시)
                confirmDelete() // 삭제 확인 처리
            }
            Button("취소", role: .cancel) { // 취소 액션
                deletingIndex = nil // 삭제 대상 초기화
            }
        }
        // 화면 나가기 확인 알림창
        else if vm.alertTitle == "나가기" {
            Button("나가기", role: .destructive) {
                presentationMode.wrappedValue.dismiss() // 강제로 화면 닫기
            }
            Button("계속 편집", role: .cancel) { } // 아무 동작 없이 알림창만 닫기
        }
        // 일반 정보 알림창
        else {
            Button("확인", role: .cancel) { } // 단순 확인 버튼
        }
    }
    
    // MARK: - 이벤트 핸들러 함수들
    
    /// 취소 버튼 클릭 시 처리 로직
    private func handleCancel() {
        // 저장되지 않은 변경사항이 있는지 확인
        if vm.shouldShowExitAlert() {
            vm.prepareExitAlert() // 나가기 확인 알림창 준비
        } else {
            // 변경사항이 없으면 바로 화면 닫기
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// 저장 버튼 클릭 시 처리 로직
    private func handleSave() {
        // 입력 데이터 유효성 검사 및 저장 준비
        vm.validateAndPrepareForSave(selectedDate: selectedDate) { expenses, error in
            if let expenses = expenses { // 유효성 검사 통과 시
                // 각 지출 데이터를 캘린더 뷰모델에 추가
                for expense in expenses {
                    viewModel.addExpense(expense)
                }
                // 저장 완료 애니메이션 시작
                vm.completeSaveAnimation()
                // 0.5초 후 화면 자동 닫기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            // error가 있는 경우는 뷰모델에서 알림창으로 처리됨
        }
    }
    
    /// 지출 항목 삭제 버튼 클릭 시 처리 로직
    private func handleDelete(at index: Int) {
        deletingIndex = index // 삭제 대상 인덱스 저장
        vm.alertTitle = "삭제" // 알림창 제목 설정
        vm.alertMessage = "지출 \(index + 1)번을 삭제하시겠습니까?" // 알림창 메시지 (1부터 시작하는 번호)
        vm.showingAlert = true // 알림창 표시 트리거
    }
    
    /// 삭제 확인 후 실제 삭제 수행
    private func confirmDelete() {
        // 스프링 애니메이션과 함께 부드럽게 삭제
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if let index = deletingIndex {
                vm.removeGroup(at: index) // 뷰모델에서 실제 데이터 삭제
            }
            deletingIndex = nil // 삭제 대상 초기화
        }
    }
    
    /// 키보드 나타남/사라짐 이벤트를 감지하는 Combine Publisher
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        // 두 개의 알림 스트림을 병합하여 하나의 Publisher로 만듦
        Publishers.Merge(
            // 키보드가 나타날 때: 키보드 높이를 방출
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue } // 키보드 프레임 추출
                .map { $0.cgRectValue.height }, // CGRect에서 높이만 추출
            
            // 키보드가 사라질 때: 0을 방출
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) } // 항상 0 반환
        )
        .eraseToAnyPublisher() // 타입을 AnyPublisher로 변환 (타입 숨김)
    }
}

// MARK: - AddExpenseView 확장 - 정적 유틸리티 메서드
extension AddExpenseView {
    /// 날짜를 사용자 친화적인 문자열로 포맷팅하는 정적 메서드
    /// 다른 뷰에서도 동일한 포맷을 사용할 수 있도록 제공
    static func formatDate(_ date: Date) -> String {
        return FormatHelper.formatSelectedDate(date)
    }

    /// 숫자 문자열에 천 단위 구분자(콤마)를 추가하는 정적 메서드
    /// 예: "1000" -> "1,000"
    static func formatWithComma(_ numberString: String) -> String {
        return FormatHelper.formatWithComma(numberString)
    }
}
