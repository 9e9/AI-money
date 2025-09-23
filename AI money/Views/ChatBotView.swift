//
//  ChatBotView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData
import Combine

struct ChatBotView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ChatBotViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                headerSection
                
                messagesSection(geometry: geometry)
                
                inputSection
            }
            .background(backgroundGradient)
            .navigationBarHidden(true)
            .onReceive(keyboardPublisher) { height in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = height
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .scaleEffect(0.6)
                            )
                        
                        Text("AI 어시스턴트")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Text("가계부 관리를 도와드릴게요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !viewModel.messages.isEmpty {
                    Text("\(viewModel.messages.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
                .opacity(0.3)
        }
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
    }
    
    private func messagesSection(geometry: GeometryProxy) -> some View {
        ScrollViewReader { scrollViewProxy in
            ZStack {
                if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            if viewModel.messages.count >= 1 {
                                welcomeCard
                                    .padding(.top, 20)
                            }
                            
                            ForEach(viewModel.messages) { message in
                                ModernChatRow(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: viewModel.messages) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if let lastId = newValue.last?.id {
                                scrollViewProxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { oldValue, newValue in
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollViewProxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                
                VStack(spacing: 12) {
                    Text("AI와 대화해보세요")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("가계부 관리, 분석, 팁 등\n무엇이든 물어보세요!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            VStack(spacing: 12) {
                Text("이런 것들을 물어보세요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(suggestionTexts, id: \.self) { suggestion in
                        SuggestionCard(text: suggestion) {
                            viewModel.inputText = suggestion
                            isInputFocused = true
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private var welcomeCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI 어시스턴트가 준비되었어요!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("가계부 관련 질문을 자유롭게 해보세요")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 4)
    }
    
    private var inputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)
            
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("메시지를 입력하세요...", text: $viewModel.inputText, axis: .vertical)
                        .focused($isInputFocused)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1...5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(isInputFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                }
                
                Button(action: {
                    viewModel.sendMessage(modelContainer: modelContext.container)
                    isInputFocused = true
                }) {
                    Image(systemName: viewModel.isTyping ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            viewModel.canSendMessage ?
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [.gray, .gray]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(viewModel.canSendMessage ? 1.0 : 0.8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.canSendMessage)
                }
                .disabled(!viewModel.canSendMessage && !viewModel.isTyping)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .opacity(0.95)
                    .background(.ultraThinMaterial)
            )
        }
        .offset(y: -max(0, keyboardHeight))
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(.systemBackground), location: 0.0),
                .init(color: Color(.systemGray6).opacity(0.3), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private let suggestionTexts = [
        "이번 달 지출 분석해줘",
        "절약 팁 알려줘",
        "예산 계획 도와줘",
        "지출 패턴 확인해줘"
    ]
}

struct ModernChatRow: View {
    let message: ChatMessage
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    ModernChatBubble(text: message.text, isUser: true)
                    
                    Text(message.timestamp.formattedChatTime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.trailing, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        ModernChatBubble(text: message.text, isUser: false)
                    }
                    
                    Text(message.timestamp.formattedChatTime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.leading, 36)
                }
                
                Spacer(minLength: 60)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.easeOut(duration: 0.5), value: isVisible)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

struct ModernChatBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isUser ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isUser ?
                          LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }
}

struct SuggestionCard: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                )
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            
            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation {
                animationPhase = 1
            }
        }
    }
}

extension ChatBotView {
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
}
