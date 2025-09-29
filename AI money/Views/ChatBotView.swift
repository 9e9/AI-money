//
//  ChatBotView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI // SwiftUI 프레임워크 임포트 (UI 구성용)
import SwiftData // SwiftData 프레임워크 임포트 (데이터 관리용)
import Combine // Combine 프레임워크 임포트 (비동기 처리용)

// AI 챗봇 화면을 구성하는 메인 뷰
struct ChatBotView: View {
    @Environment(\.modelContext) private var modelContext // SwiftData 모델 컨텍스트 환경변수
    @StateObject private var viewModel = ChatBotViewModel() // 챗봇 뷰모델 상태 객체
    @State private var scrollOffset: CGFloat = 0 // 스크롤 오프셋 상태 (현재 미사용)
    @State private var selectedQuestionIndex: Int? = nil // 선택된 미리 만들어진 질문의 인덱스
    
    var body: some View {
        ZStack { // 화면 전체를 감싸는 컨테이너
            // 심플한 배경색 설정
            Color(.systemGroupedBackground) // 시스템 그룹 배경색
                .ignoresSafeArea() // 안전 영역 무시하여 전체 화면 적용
            
            VStack(spacing: 0) { // 수직 스택 (간격 0으로 설정)
                // 헤더 섹션
                headerSection
                
                // 메인 컨텐츠 (메시지 유무에 따라 조건부 렌더링)
                if viewModel.messages.isEmpty { // 메시지가 없는 경우
                    welcomeView // 환영 화면 표시
                } else { // 메시지가 있는 경우
                    messagesView // 메시지 목록 화면 표시
                }
                
                // 하단 입력 영역 (항상 표시됨)
                bottomInputSection
            }
        }
        .navigationBarHidden(true) // 네비게이션 바 숨김
    }
    
    // MARK: - Header Section
    // 화면 상단 헤더 섹션을 구성하는 뷰
    private var headerSection: some View {
        VStack(spacing: 16) { // 수직 스택 (16포인트 간격)
            HStack { // 수평 스택
                VStack(alignment: .leading, spacing: 4) { // 왼쪽 정렬 수직 스택 (4포인트 간격)
                    HStack() { // 타이틀과 베타 라벨을 위한 수평 스택
                        Text("AI 분석") // 메인 타이틀
                            .font(.system(size: 28, weight: .bold)) // 28포인트 볼드 폰트
                            .foregroundColor(.primary) // 기본 전경색
                        
                        Text("Beta") // 베타 버전 라벨
                            .font(.system(size: 15)) // 15포인트 폰트
                            .foregroundColor(.secondary) // 보조 전경색
                    }
                    
                    HStack(spacing: 6) { // 상태 표시를 위한 수평 스택 (6포인트 간격)
                        Circle() // 원형 상태 표시 점
                            .fill(Color.green) // 초록색 채우기
                            .frame(width: 6, height: 6) // 6x6 포인트 크기
                        
                        Text("지출 패턴을 분석해드릴게요") // 상태 설명 텍스트
                            .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                            .foregroundColor(.secondary) // 보조 전경색
                    }
                }
                
                Spacer() // 좌우 공간 분배를 위한 스페이서
                
                // 초기화 버튼 (메시지가 있을 때만 표시)
                if !viewModel.messages.isEmpty {
                    Button("초기화") { // 초기화 버튼
                        withAnimation(.easeInOut(duration: 0.3)) { // 0.3초 애니메이션
                            viewModel.clearMessages() // 메시지 초기화
                            selectedQuestionIndex = nil // 선택된 질문 인덱스 초기화
                        }
                    }
                    .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                    .foregroundColor(.white) // 흰색 텍스트
                    .padding(.horizontal, 12) // 수평 12포인트 패딩
                    .padding(.vertical, 6) // 수직 6포인트 패딩
                    .background( // 배경 설정
                        RoundedRectangle(cornerRadius: 8) // 8포인트 둥근 모서리 직사각형
                            .fill(Color(.systemGray4)) // 시스템 그레이4 색상
                    )
                }
            }
        }
        .padding(.horizontal, 20) // 수평 20포인트 패딩
        .padding(.vertical, 16) // 수직 16포인트 패딩
    }
    
    // MARK: - Welcome View (메시지가 없을 때)
    // 처음 진입 시 표시되는 환영 화면
    private var welcomeView: some View {
        ScrollView(showsIndicators: false) { // 스크롤 인디케이터 없는 스크롤뷰
            VStack(spacing: 24) { // 수직 스택 (24포인트 간격)
                Spacer().frame(height: 40) // 상단 40포인트 여백
                
                // 환영 메시지 섹션
                VStack(spacing: 16) { // 수직 스택 (16포인트 간격)
                    ZStack { // 겹침 스택 (아이콘 배경용)
                        Circle() // 원형 배경
                            .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                            .frame(width: 80, height: 80) // 80x80 포인트 크기
                        
                        Image(systemName: "chart.bar.fill") // 차트 바 아이콘
                            .font(.system(size: 32, weight: .medium)) // 32포인트 미디엄 폰트
                            .foregroundColor(.primary) // 기본 전경색
                    }
                    
                    VStack(spacing: 8) { // 텍스트용 수직 스택 (8포인트 간격)
                        Text("어떤걸 도와드릴까요?") // 메인 환영 메시지
                            .font(.system(size: 20, weight: .semibold)) // 20포인트 세미볼드 폰트
                            .foregroundColor(.primary) // 기본 전경색
                        
                        Text("아래 질문을 선택하거나 직접 입력해보세요") // 안내 메시지
                            .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                            .foregroundColor(.secondary) // 보조 전경색
                            .multilineTextAlignment(.center) // 중앙 정렬
                    }
                }
                
                // 미리 만들어진 질문들을 그리드 형태로 표시
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    // 2열 그리드, 유연한 크기, 12포인트 간격
                    ForEach(Array(viewModel.predefinedQuestions.enumerated()), id: \.offset) { index, question in
                        // 질문 배열을 인덱스와 함께 순회
                        PredefinedQuestionCard( // 미리 만들어진 질문 카드 컴포넌트
                            question: question, // 질문 텍스트
                            onTap: { // 탭 이벤트 핸들러
                                selectedQuestionIndex = index // 선택된 인덱스 저장
                                viewModel.sendPredefinedQuestion(question, modelContainer: modelContext.container)
                                // 미리 만들어진 질문 전송
                            }
                        )
                    }
                }
                .padding(.horizontal, 20) // 수평 20포인트 패딩
                
                Spacer().frame(height: 100) // 하단 100포인트 여백 (입력창 공간 확보)
            }
        }
    }
    
    // MARK: - Messages View
    // 채팅 메시지들을 표시하는 뷰
    private var messagesView: some View {
        ScrollViewReader { scrollViewProxy in // 스크롤 제어를 위한 프록시
            ScrollView(showsIndicators: false) { // 스크롤 인디케이터 없는 스크롤뷰
                LazyVStack(spacing: 12) { // 지연 로딩 수직 스택 (12포인트 간격)
                    ForEach(viewModel.messages) { message in // 메시지 배열 순회
                        ChatRow(message: message) // 각 메시지를 표시하는 행 컴포넌트
                            .id(message.id) // 메시지 ID로 식별자 설정 (스크롤 제어용)
                    }
                    
                    // AI가 타이핑 중일 때 표시되는 인디케이터
                    if viewModel.isTyping {
                        TypingIndicator() // 타이핑 인디케이터 컴포넌트
                            .id("typing") // 타이핑 인디케이터 식별자
                    }
                    
                    Spacer() // 하단 여백
                        .frame(height: 20) // 20포인트 높이
                }
                .padding(.horizontal, 16) // 수평 16포인트 패딩
                .padding(.top, 16) // 상단 16포인트 패딩
            }
            .onChange(of: viewModel.messages) { oldValue, newValue in
                // 메시지 배열 변경 감지
                withAnimation(.easeInOut(duration: 0.3)) { // 0.3초 애니메이션
                    if let lastId = newValue.last?.id { // 마지막 메시지 ID 가져오기
                        scrollViewProxy.scrollTo(lastId, anchor: .bottom) // 마지막 메시지로 스크롤
                    }
                }
            }
            .onChange(of: viewModel.isTyping) { oldValue, newValue in
                // 타이핑 상태 변경 감지
                if newValue { // 타이핑이 시작된 경우
                    withAnimation(.easeInOut(duration: 0.3)) { // 0.3초 애니메이션
                        scrollViewProxy.scrollTo("typing", anchor: .bottom) // 타이핑 인디케이터로 스크롤
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Input Section (새로 추가)
    // 하단 메시지 입력 영역
    private var bottomInputSection: some View {
        VStack(spacing: 0) { // 수직 스택 (간격 0)
            Rectangle() // 구분선 역할의 직사각형
                .fill(Color(.systemGray5)) // 시스템 그레이5 색상
                .frame(height: 0.5) // 0.5포인트 높이의 얇은 선
            
            HStack(spacing: 12) { // 수평 스택 (12포인트 간격)
                // 텍스트 입력 필드와 잠금 버튼을 포함하는 컨테이너
                HStack {
                    TextField("메시지를 입력하세요...", text: $viewModel.inputText) // 텍스트 입력 필드
                        .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                        .disabled(viewModel.isTextFieldLocked) // 잠금 상태에 따른 비활성화
                        .opacity(viewModel.isTextFieldLocked ? 0.5 : 1.0) // 잠금 시 투명도 변경
                        .onSubmit { // 엔터키 입력 시 실행
                            if viewModel.canSendMessage { // 메시지 전송 가능 여부 확인
                                viewModel.sendMessage(modelContainer: modelContext.container) // 메시지 전송
                            }
                        }
                    
                    // 텍스트 필드 잠금/해제 토글 버튼
                    Button(action: {
                        viewModel.toggleTextFieldLock() // 잠금 상태 토글
                    }) {
                        Image(systemName: viewModel.isTextFieldLocked ? "lock.fill" : "lock.open.fill")
                        // 잠금 상태에 따른 아이콘 변경 (잠금: lock.fill, 해제: lock.open.fill)
                            .font(.system(size: 16, weight: .medium)) // 16포인트 미디엄 폰트
                            .foregroundColor(viewModel.isTextFieldLocked ? .orange : .blue) // 상태별 색상
                    }
                }
                .padding(.horizontal, 16) // 수평 16포인트 패딩
                .padding(.vertical, 12) // 수직 12포인트 패딩
                .background( // 배경 설정
                    RoundedRectangle(cornerRadius: 20) // 20포인트 둥근 모서리
                        .fill(Color(.systemGray6)) // 시스템 그레이6 배경색
                        .overlay( // 테두리 오버레이
                            RoundedRectangle(cornerRadius: 20) // 20포인트 둥근 모서리
                                .stroke( // 테두리 설정
                                    viewModel.isTextFieldLocked ? Color(.systemGray5) : Color.blue.opacity(0.3),
                                    // 잠금 상태에 따른 테두리 색상
                                    lineWidth: 1 // 1포인트 두께
                                )
                        )
                )
                
                // 메시지 전송 버튼
                Button(action: {
                    viewModel.sendMessage(modelContainer: modelContext.container) // 메시지 전송
                }) {
                    Image(systemName: "arrow.up.circle.fill") // 위쪽 화살표가 있는 원형 아이콘
                        .font(.system(size: 28, weight: .medium)) // 28포인트 미디엄 폰트
                        .foregroundColor(viewModel.canSendMessage ? .blue : .secondary)
                        // 전송 가능 여부에 따른 색상 변경
                }
                .disabled(!viewModel.canSendMessage) // 전송 불가능할 때 버튼 비활성화
            }
            .padding(.horizontal, 16) // 수평 16포인트 패딩
            .padding(.vertical, 12) // 수직 12포인트 패딩
            .background(Color(.systemBackground)) // 시스템 배경색
        }
    }
}

// MARK: - Predefined Question Card
// 미리 만들어진 질문을 표시하는 카드 컴포넌트
struct PredefinedQuestionCard: View {
    let question: String // 표시할 질문 텍스트
    let onTap: () -> Void // 탭 이벤트 핸들러
    
    var body: some View {
        Button(action: onTap) { // 버튼으로 감싸기
            VStack { // 수직 스택
                Text(question) // 질문 텍스트 표시
                    .font(.system(size: 14, weight: .medium)) // 14포인트 미디엄 폰트
                    .foregroundColor(.primary) // 기본 전경색
                    .multilineTextAlignment(.center) // 중앙 정렬
                    .lineLimit(2) // 최대 2줄까지 표시
            }
            .frame(maxWidth: .infinity, minHeight: 60) // 최대 너비, 최소 60포인트 높이
            .padding(.horizontal, 12) // 수평 12포인트 패딩
            .padding(.vertical, 8) // 수직 8포인트 패딩
            .background( // 배경 설정
                RoundedRectangle(cornerRadius: 12) // 12포인트 둥근 모서리
                    .fill(Color(.systemBackground)) // 시스템 배경색
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2) // 그림자 효과
            )
        }
        .buttonStyle(PlainButtonStyle()) // 기본 버튼 스타일 (하이라이트 효과 없음)
    }
}

// MARK: - Chat Row
// 개별 채팅 메시지를 표시하는 행 컴포넌트
struct ChatRow: View {
    let message: ChatMessage // 표시할 메시지 객체
    @State private var isVisible = false // 나타남 애니메이션을 위한 상태
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) { // 하단 정렬 수평 스택 (간격 0)
            if message.isUser { // 사용자 메시지인 경우
                Spacer(minLength: 40) // 왼쪽 최소 40포인트 여백 (오른쪽 정렬 효과)
                
                VStack(alignment: .trailing, spacing: 4) { // 오른쪽 정렬 수직 스택 (4포인트 간격)
                    Text(message.text) // 메시지 텍스트
                        .font(.system(size: 15, weight: .medium)) // 15포인트 미디엄 폰트
                        .foregroundColor(.white) // 흰색 텍스트
                        .padding(.horizontal, 14) // 수평 14포인트 패딩
                        .padding(.vertical, 10) // 수직 10포인트 패딩
                        .background( // 배경 설정
                            RoundedRectangle(cornerRadius: 16) // 16포인트 둥근 모서리
                                .fill(Color.blue) // 파란색 배경
                        )
                        .frame(maxWidth: 260, alignment: .trailing) // 최대 260포인트 너비, 오른쪽 정렬
                    
                    Text(message.timestamp.formattedChatTime) // 메시지 시간 표시
                        .font(.system(size: 11, weight: .medium)) // 11포인트 미디엄 폰트
                        .foregroundColor(.secondary) // 보조 전경색
                        .padding(.trailing, 4) // 오른쪽 4포인트 패딩
                }
            } else { // AI 메시지인 경우
                VStack(alignment: .leading, spacing: 4) { // 왼쪽 정렬 수직 스택 (4포인트 간격)
                    HStack(alignment: .top, spacing: 10) { // 상단 정렬 수평 스택 (10포인트 간격)
                        // AI 아바타
                        Circle() // 원형 아바타 배경
                            .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                            .frame(width: 24, height: 24) // 24x24 포인트 크기
                            .overlay( // 아바타 아이콘 오버레이
                                Image(systemName: "chart.bar.fill") // 차트 바 아이콘
                                    .font(.system(size: 10, weight: .medium)) // 10포인트 미디엄 폰트
                                    .foregroundColor(.primary) // 기본 전경색
                            )
                        
                        Text(message.text) // AI 응답 텍스트
                            .font(.system(size: 15, weight: .medium)) // 15포인트 미디엄 폰트
                            .foregroundColor(.primary) // 기본 전경색
                            .padding(.horizontal, 14) // 수평 14포인트 패딩
                            .padding(.vertical, 10) // 수직 10포인트 패딩
                            .background( // 배경 설정
                                RoundedRectangle(cornerRadius: 16) // 16포인트 둥근 모서리
                                    .fill(Color(.systemGray6)) // 시스템 그레이6 배경
                            )
                            .frame(maxWidth: 260, alignment: .leading) // 최대 260포인트 너비, 왼쪽 정렬
                    }
                    
                    Text(message.timestamp.formattedChatTime) // 메시지 시간 표시
                        .font(.system(size: 11, weight: .medium)) // 11포인트 미디엄 폰트
                        .foregroundColor(.secondary) // 보조 전경색
                        .padding(.leading, 34) // 왼쪽 34포인트 패딩 (아바타와 정렬)
                }
                
                Spacer(minLength: 40) // 오른쪽 최소 40포인트 여백 (왼쪽 정렬 효과)
            }
        }
        .opacity(isVisible ? 1 : 0) // 나타남 애니메이션을 위한 투명도
        .offset(y: isVisible ? 0 : 10) // 나타남 애니메이션을 위한 Y축 오프셋
        .animation(.easeOut(duration: 0.3), value: isVisible) // 0.3초 easeOut 애니메이션
        .onAppear { // 뷰가 나타날 때 실행
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) { // 0.1초 지연 후 0.3초 애니메이션
                isVisible = true // 보이기 상태로 변경
            }
        }
    }
}

// MARK: - Typing Indicator
// AI가 타이핑 중임을 표시하는 인디케이터 컴포넌트
struct TypingIndicator: View {
    @State private var animationPhase = 0 // 애니메이션 페이즈 상태
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) { // 하단 정렬 수평 스택 (10포인트 간격)
            // AI 아바타 (ChatRow와 동일한 스타일)
            Circle() // 원형 아바타 배경
                .fill(Color(.systemGray6)) // 시스템 그레이6 색상
                .frame(width: 24, height: 24) // 24x24 포인트 크기
                .overlay( // 아바타 아이콘 오버레이
                    Image(systemName: "chart.bar.fill") // 차트 바 아이콘
                        .font(.system(size: 10, weight: .medium)) // 10포인트 미디엄 폰트
                        .foregroundColor(.primary) // 기본 전경색
                )
            
            // 타이핑 애니메이션을 위한 점 3개
            HStack(spacing: 4) { // 수평 스택 (4포인트 간격)
                ForEach(0..<3) { index in // 0부터 2까지 3개의 점 생성
                    Circle() // 각각의 점을 원형으로 생성
                        .fill(Color.secondary) // 보조 색상으로 채우기
                        .frame(width: 6, height: 6) // 6x6 포인트 크기
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8) // 현재 페이즈와 일치하면 크게, 아니면 작게
                        .animation( // 애니메이션 설정
                            .easeInOut(duration: 0.6) // 0.6초 easeInOut 애니메이션
                            .repeatForever() // 무한 반복
                            .delay(Double(index) * 0.2), // 각 점마다 0.2초씩 지연
                            value: animationPhase // 애니메이션 트리거 값
                        )
                }
            }
            .padding(.horizontal, 14) // 수평 14포인트 패딩
            .padding(.vertical, 10) // 수직 10포인트 패딩
            .background( // 배경 설정 (ChatRow의 AI 메시지와 동일한 스타일)
                RoundedRectangle(cornerRadius: 16) // 16포인트 둥근 모서리
                    .fill(Color(.systemGray6)) // 시스템 그레이6 배경
            )
            
            Spacer(minLength: 40) // 오른쪽 최소 40포인트 여백
        }
        .onAppear { // 뷰가 나타날 때 실행
            withAnimation { // 애니메이션과 함께
                animationPhase = 1 // 애니메이션 페이즈를 1로 설정하여 애니메이션 시작
            }
        }
    }
}
