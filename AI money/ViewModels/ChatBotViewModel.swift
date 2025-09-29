//
//  ChatBotViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftData  // 데이터 저장 및 관리를 위한 SwiftData 프레임워크
import SwiftUI

// @MainActor: 이 클래스의 모든 메서드와 프로퍼티가 메인 스레드에서 실행되도록 보장
// ObservableObject: SwiftUI의 @ObservedObject나 @StateObject와 함께 사용할 수 있는 프로토콜
@MainActor
class ChatBotViewModel: ObservableObject {
    // MARK: - Published Properties (UI가 자동으로 업데이트되는 상태 변수들)
    
    // 채팅 메시지들을 저장하는 배열 - 사용자와 AI 메시지 모두 포함
    @Published var messages: [ChatMessage] = []
    
    // 현재 사용자가 입력하고 있는 텍스트를 저장
    @Published var inputText: String = ""
    
    // AI와의 대화 컨텍스트 - 이전 대화 내용을 기억하여 연속적인 대화가 가능하도록 함
    @Published var conversationContext = ConversationContext()
    
    // AI가 현재 응답을 생성하고 있는지를 나타내는 상태
    // true일 때 로딩 인디케이터나 "AI가 입력 중..." 같은 UI를 표시할 수 있음
    @Published var isTyping: Bool = false
    
    // 텍스트 입력 필드의 잠금 상태를 관리
    // true일 때는 사용자가 직접 텍스트를 입력할 수 없고, 미리 정의된 질문만 사용 가능
    @Published var isTextFieldLocked: Bool = true
    
    // MARK: - Constants
    
    // 사용자가 빠르게 선택할 수 있는 미리 만들어진 질문들
    // 가계부 앱의 특성에 맞게 지출 관련 질문들로 구성됨
    let predefinedQuestions = [
        "이번 달 총 지출은?",           // 현재 월의 총 지출 금액 조회
        "지난 달 총 지출은?",           // 이전 월의 총 지출 금액 조회
        "이번 달 가장 많이 쓴 카테고리는?", // 현재 월에서 지출이 가장 많은 카테고리 조회
        "지난 달 가장 많이 쓴 카테고리는?", // 이전 월에서 지출이 가장 많은 카테고리 조회
        "오늘 얼마 썼어?",             // 오늘 하루 지출 금액 조회
        "이번 주 총 지출은?",           // 현재 주의 총 지출 금액 조회
        "이번 달 교통비 얼마야?",       // 현재 월의 교통비 카테고리 지출 조회
        "3개월 동안 얼마나 썻어?"      // 최근 3개월간의 총 지출 조회
    ]

    // MARK: - Computed Properties
    
    // 메시지 전송이 가능한 상태인지 확인하는 계산된 프로퍼티
    var canSendMessage: Bool {
        // 세 가지 조건을 모두 만족해야 메시지 전송 가능:
        // 1. 텍스트 필드가 잠겨있지 않아야 함 (!isTextFieldLocked)
        // 2. 입력 텍스트가 공백이 아닌 실제 내용이 있어야 함
        // 3. AI가 현재 타이핑 중이 아니어야 함 (!isTyping)
        return !isTextFieldLocked &&
               !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !isTyping
    }

    // MARK: - Methods
    
    // 메시지를 전송하는 주요 메서드
    // modelContainer: SwiftData의 데이터 컨테이너 (지출 데이터 접근용)
    func sendMessage(modelContainer: ModelContainer) {
        // 입력 텍스트의 앞뒤 공백 제거
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 빈 텍스트이거나 AI가 이미 타이핑 중이면 전송하지 않음
        guard !trimmed.isEmpty && !isTyping else { return }
        
        // 사용자 메시지 객체 생성 및 메시지 배열에 추가
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMessage)
        
        // 입력 필드 초기화 및 타이핑 상태 활성화
        inputText = ""
        isTyping = true

        // 현재 대화 컨텍스트 저장 (비동기 작업에서 사용하기 위해)
        let currentContext = conversationContext
        
        // AI 응답을 비동기로 처리하는 Task 시작
        Task {
            // 자연스러운 타이핑 효과를 위한 0.8초 지연
            // 실제 AI가 생각하는 시간을 시뮬레이션
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            // AIService를 통해 AI 응답과 업데이트된 컨텍스트 받기
            let (aiReply, newContext) = await AIService.shared.reply(
                to: trimmed,                    // 사용자 질문
                modelContainer: modelContainer,  // 데이터 접근용 컨테이너
                conversationContext: currentContext  // 이전 대화 컨텍스트
            )
            
            // UI 업데이트는 반드시 메인 스레드에서 실행
            await MainActor.run {
                // 새로운 대화 컨텍스트로 업데이트 (대화 기억 유지)
                self.conversationContext = newContext
                // 타이핑 상태 해제
                self.isTyping = false
                // AI 응답 메시지를 채팅에 추가
                self.messages.append(ChatMessage(text: aiReply, isUser: false))
            }
        }
    }
    
    // 미리 정의된 질문을 선택했을 때 호출되는 메서드
    // question: 선택된 질문 텍스트
    func sendPredefinedQuestion(_ question: String, modelContainer: ModelContainer) {
        // 선택된 질문을 입력 필드에 설정
        inputText = question
        // 일반 메시지 전송과 동일한 프로세스로 처리
        sendMessage(modelContainer: modelContainer)
    }
    
    // 텍스트 필드의 잠금 상태를 토글하는 메서드
    // 사용자가 직접 입력 모드와 미리 정의된 질문 모드를 전환할 때 사용
    func toggleTextFieldLock() {
        // 0.3초 애니메이션과 함께 부드럽게 상태 전환
        withAnimation(.easeInOut(duration: 0.3)) {
            isTextFieldLocked.toggle()
        }
    }
    
    // AI의 타이핑 상태를 강제로 중지하는 메서드
    // 에러 상황이나 사용자가 취소했을 때 사용할 수 있음
    func stopTyping() {
        isTyping = false
    }
    
    // 채팅 내용을 완전히 초기화하는 메서드
    // 새로운 대화를 시작하거나 앱을 리셋할 때 사용
    func clearMessages() {
        messages.removeAll()           // 모든 채팅 메시지 삭제
        inputText = ""                // 입력 텍스트 초기화
        conversationContext = ConversationContext()  // 대화 컨텍스트 리셋
        isTyping = false              // 타이핑 상태 해제
        isTextFieldLocked = true      // 텍스트 필드를 다시 잠금 상태로 설정
    }
}
