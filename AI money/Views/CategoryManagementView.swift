//
//  CategoryManagementView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

// 카테고리 관리 화면을 구성하는 SwiftUI View
struct CategoryManagementView: View {
    // 현재 뷰를 닫기 위한 환경 변수
    @Environment(\.presentationMode) var presentationMode
    
    // 지출 서비스 프로토콜 - 카테고리 데이터 관리
    private let expenseService: ExpenseServiceProtocol
    // 카테고리 관리 뷰모델 - 상태와 로직 관리
    @StateObject private var viewModel: CategoryManagementViewModel
    // 카테고리 추가 텍스트필드 표시 여부
    @State private var showTextField = false
    // 편집 모드 활성화 여부 (선택, 삭제 기능)
    @State private var isEditingMode = false
    // 알림 다이얼로그 표시 여부
    @State private var showingAlert = false
    // 현재 삭제 진행 중인 카테고리들의 집합
    @State private var deletingCategories: Set<String> = []
    // 삭제 버튼이 눌린 카테고리 (애니메이션 효과용)
    @State private var trashPressed: String? = nil
    // 텍스트필드 포커스 상태 관리
    @FocusState private var isTextFieldFocused: Bool

    // 이니셜라이저 - ExpenseService 의존성 주입
    init(expenseService: ExpenseServiceProtocol? = nil) {
        // 서비스가 제공되지 않으면 기본 싱글톤 인스턴스 사용
        let service = expenseService ?? ExpenseCalendarViewModel.shared
        self.expenseService = service
        // 뷰모델 초기화
        self._viewModel = StateObject(wrappedValue: CategoryManagementViewModel(expenseService: service))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 편집 모드일 때만 표시되는 상단 버튼 영역
                if isEditingMode {
                    HStack {
                        // 전체 선택/해제 버튼
                        Button(action: {
                            // 부드러운 애니메이션과 함께 선택 상태 토글
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.handleSelectionAction()
                            }
                        }) {
                            // 뷰모델의 상태에 따라 버튼 텍스트가 동적으로 변경됨
                            Text(viewModel.selectionButtonTitle)
                                .font(.headline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.12))
                                .cornerRadius(10)
                        }
                        
                        Spacer() // 버튼들 사이 공간 확보
                        
                        // 선택된 카테고리가 있을 때만 표시되는 삭제 버튼
                        if !viewModel.selectedCategories.isEmpty {
                            Button(action: {
                                // 선택된 카테고리들의 삭제 확인 메시지 준비
                                let _ = viewModel.prepareDeleteSelectedCategories()
                                showingAlert = true // 확인 알림 표시
                            }) {
                                HStack {
                                    Text("삭제")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                            // 선택된 항목이 없으면 투명하게, 있으면 불투명하게
                            .opacity(viewModel.selectedCategories.isEmpty ? 0 : 1)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategories.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // 카테고리가 없고 텍스트필드도 표시되지 않을 때의 빈 상태 UI
                if viewModel.customCategories.isEmpty && !showTextField {
                    Spacer() // 위쪽 공간
                    VStack(spacing: 16) {
                        // 폴더 추가 아이콘
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        // 메인 메시지
                        Text("카테고리가 없습니다")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        // 보조 메시지
                        Text("새 카테고리를 추가해보세요")
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    Spacer() // 아래쪽 공간
                } else {
                    // 카테고리 목록을 표시하는 스크롤뷰
                    ScrollView {
                        LazyVStack(spacing: 14) { // 성능을 위한 LazyVStack 사용
                            // 각 카테고리에 대한 행 생성 (인덱스와 함께)
                            ForEach(Array(viewModel.customCategories.enumerated()), id: \.element) { index, category in
                                CategoryRowView(
                                    category: category,
                                    isEditingMode: isEditingMode,
                                    isSelected: viewModel.selectedCategories.contains(category),
                                    isDeleting: deletingCategories.contains(category),
                                    trashPressed: trashPressed,
                                    onToggleSelection: {
                                        // 선택 상태 토글 애니메이션
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            viewModel.toggleSelection(for: category)
                                        }
                                    },
                                    onDelete: {
                                        // 삭제 버튼 눌림 효과 애니메이션
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            trashPressed = category
                                        }
                                        // 0.1초 후 눌림 효과 해제
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                trashPressed = nil
                                            }
                                        }
                                        // 삭제 확인 메시지 준비 및 알림 표시
                                        let _ = viewModel.prepareDeleteCategory(category)
                                        showingAlert = true
                                    }
                                )
                                // 삭제 중인 카테고리는 투명하게 처리
                                .opacity(deletingCategories.contains(category) ? 0 : 1)
                                .animation(.easeInOut(duration: 0.4), value: deletingCategories)
                                .transition(.opacity) // 페이드 전환 효과
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        // 카테고리 목록 변경시 애니메이션
                        .animation(.easeInOut(duration: 0.4), value: viewModel.customCategories)
                    }
                }
                
                // 새 카테고리 추가 텍스트필드 영역
                if showTextField {
                    VStack(spacing: 12) {
                        // 구분선
                        Divider()
                            .transition(.opacity)
                        
                        HStack(spacing: 12) {
                            // 카테고리 이름 입력 텍스트필드
                            TextField("새 카테고리 이름", text: $viewModel.newCategoryName, onCommit: {
                                addCategoryWithEffect() // 엔터키 입력시 카테고리 추가
                            })
                            .focused($isTextFieldFocused) // 포커스 상태 바인딩
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    // 포커스 상태에 따른 테두리 색상 변경
                                    .stroke(isTextFieldFocused ? Color.blue : Color(.systemGray4), lineWidth: isTextFieldFocused ? 2 : 1)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                            
                            // 추가 버튼
                            Button(action: addCategoryWithEffect) {
                                Text("추가")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            // 입력값이 있을 때만 활성화된 색상
                                            .fill(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                                    )
                            }
                            // 입력값이 없으면 비활성화
                            .disabled(viewModel.newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.newCategoryName.isEmpty)
                            
                            // 취소(X) 버튼
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showTextField = false // 텍스트필드 숨김
                                    isTextFieldFocused = false // 포커스 해제
                                }
                                viewModel.newCategoryName = "" // 입력값 초기화
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color(.systemGray5))
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .background(Color(.systemBackground))
                    // 아래에서 슬라이드업 + 페이드인 효과
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // 텍스트필드 표시 후 약간의 지연을 두고 포커스
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                }
                
                // 카테고리 추가 버튼 (텍스트필드가 숨겨져 있을 때만 표시)
                if !showTextField {
                    HStack {
                        Spacer()
                        Button(action: {
                            // 텍스트필드 표시 애니메이션
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTextField = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                // 플러스 아이콘
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("카테고리 추가")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                                    // 파란색 그림자 효과
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    // 아래에서 슬라이드업 + 페이드인 효과
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 최소한의 하단 여백
                Spacer(minLength: 0)
            }
            .navigationTitle("카테고리 관리") // 네비게이션 타이틀
            .toolbar {
                // 왼쪽 상단 완료 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.resetState() // 뷰모델 상태 초기화
                        presentationMode.wrappedValue.dismiss() // 화면 닫기
                    }) {
                        Text("완료")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                // 오른쪽 상단 편집/완료 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditingMode.toggle() // 편집 모드 토글
                            if isEditingMode {
                                // 편집 모드 진입시 텍스트필드 숨김
                                showTextField = false
                                isTextFieldFocused = false
                                viewModel.newCategoryName = ""
                            }
                        }
                    }) {
                        // 편집 모드 상태에 따른 텍스트와 색상 변경
                        Text(isEditingMode ? "완료" : "편집")
                            .font(.headline)
                            .foregroundColor(isEditingMode ? .red : .blue)
                    }
                }
            }
            // 삭제 확인 및 에러 알림 다이얼로그
            .alert(isPresented: $showingAlert) {
                // 삭제 확인 메시지인지 체크
                if (viewModel.alertMessage.contains("삭제하시겠습니까")) {
                    return Alert(
                        title: Text("삭제 확인"),
                        message: Text(viewModel.alertMessage),
                        primaryButton: .destructive(Text("삭제")) {
                            handleConfirmedDelete() // 삭제 확인시 실행
                        },
                        secondaryButton: .cancel(Text("취소")) // 취소 버튼
                    )
                } else {
                    // 일반 알림 (에러 메시지 등)
                    return Alert(
                        title: Text("알림"),
                        message: Text(viewModel.alertMessage),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }

    // 카테고리 추가 처리 함수 (애니메이션 효과 포함)
    private func addCategoryWithEffect() {
        // 뷰모델에서 유효성 검사 및 카테고리 추가 수행
        let result = viewModel.validateAndAddCategory()
        
        switch result {
        case .success:
            // 성공시 부드러운 애니메이션
            withAnimation(.easeInOut(duration: 0.2)) {
            }
            
            // 추가 후 다시 텍스트필드에 포커스 (연속 입력 가능)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
            
        case .failure(_):
            // 실패시 알림 표시 (중복 카테고리 등)
            showingAlert = true
        }
    }
    
    // 삭제 확인 후 실제 삭제 처리 함수
    private func handleConfirmedDelete() {
        // 선택된 카테고리들이 있는 경우 (다중 삭제)
        if !viewModel.selectedCategories.isEmpty {
            withAnimation(.easeInOut(duration: 0.4)) {
                deletingCategories = viewModel.selectedCategories // 삭제 애니메이션용 상태 설정
            }
            // 애니메이션 완료 후 실제 삭제 수행
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                viewModel.handleConfirmedDelete()
                deletingCategories = [] // 삭제 상태 초기화
            }
        } else if let target = viewModel.categoryToDelete {
            // 단일 카테고리 삭제인 경우
            withAnimation(.easeInOut(duration: 0.4)) {
                deletingCategories = [target] // 삭제 애니메이션용 상태 설정
            }
            // 애니메이션 완료 후 실제 삭제 수행
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                viewModel.handleConfirmedDelete()
                deletingCategories = [] // 삭제 상태 초기화
            }
        }
    }
}

// 개별 카테고리 행을 표시하는 뷰
struct CategoryRowView: View {
    let category: String // 카테고리 이름
    let isEditingMode: Bool // 편집 모드 여부
    let isSelected: Bool // 선택 상태
    let isDeleting: Bool // 삭제 진행 중 상태
    let trashPressed: String? // 삭제 버튼 눌림 상태
    let onToggleSelection: () -> Void // 선택 토글 콜백
    let onDelete: () -> Void // 삭제 버튼 콜백
    
    var body: some View {
        HStack {
            // 편집 모드일 때만 표시되는 체크박스
            if isEditingMode {
                Button(action: onToggleSelection) {
                    // 선택 상태에 따른 아이콘 변경
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.system(size: 22))
                        .scaleEffect(isSelected ? 1.1 : 1.0) // 선택시 약간 확대
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                .buttonStyle(BorderlessButtonStyle()) // 기본 버튼 스타일 제거
                .opacity(isEditingMode ? 1 : 0) // 편집 모드에서만 표시
                .animation(.easeInOut(duration: 0.25), value: isEditingMode)
            }
            
            // 카테고리 이름 텍스트
            Text(category)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer() // 텍스트와 버튼 사이 공간
            
            // 편집 모드일 때만 표시되는 삭제 버튼
            if isEditingMode {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.red)
                        // 버튼 눌림 효과 (투명도와 크기 변화)
                        .opacity(trashPressed == category ? 0.4 : 1.0)
                        .scaleEffect(trashPressed == category ? 0.9 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: trashPressed)
                }
                .buttonStyle(BorderlessButtonStyle()) // 기본 버튼 스타일 제거
                .opacity(isEditingMode ? 1 : 0) // 편집 모드에서만 표시
                .animation(.easeInOut(duration: 0.25), value: isEditingMode)
            }
        }
        .padding(.vertical, 14) // 세로 패딩
        .padding(.horizontal, 16) // 가로 패딩
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6)) // 배경색
                // 미세한 그림자 효과
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(isDeleting ? 0.6 : 1.0) // 삭제 중일 때 반투명
        .animation(.easeInOut(duration: 0.2), value: isDeleting)
    }
}
