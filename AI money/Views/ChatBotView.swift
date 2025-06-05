//
//  ChatBotView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBotView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var conversationContext = ConversationContext()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    ChatBubble(text: message.text, isUser: true)
                                } else {
                                    ChatBubble(text: message.text, isUser: false)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .background(Color .white)
                .onChange(of: messages) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let lastId = messages.last?.id {
                            withAnimation {
                                scrollViewProxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear
                        .background(.ultraThinMaterial)
                        .overlay(Color.white.opacity(1.0))
                        .frame(height: 0)
                        .allowsHitTesting(false)
                }
            }

            ZStack {
                HStack {
                    TextField("메시지를 입력하세요", text: $inputText, onCommit: sendMessage)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(10)
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45))
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMessage)
        inputText = ""

        Task {
            var tempContext = conversationContext
            let aiReply = await AIService.shared.reply(
                to: trimmed,
                context: modelContext,
                conversationContext: &tempContext
            )
            await MainActor.run {
                conversationContext = tempContext
                messages.append(ChatMessage(text: aiReply, isUser: false))
            }
        }
    }
}

struct ChatBubble: View {
    let text: String
    let isUser: Bool

    var body: some View {
        Text(text)
            .padding(10)
            .background(isUser ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isUser ? .white : .black)
            .cornerRadius(14)
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }
}
