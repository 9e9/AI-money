//
//  ChatBotView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData

struct ChatBotView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ChatBotViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollViewProxy in
                ZStack {
                    if viewModel.messages.isEmpty {
                        VStack {
                            Spacer()
                            Text("아직 대화가 시작되지 않았어요.\n아래에 메시지를 입력해보세요!")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.messages) { message in
                                    AnimatedChatRow(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .onChange(of: viewModel.messages) { oldValue, newValue in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                if let lastId = newValue.last?.id {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        scrollViewProxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .safeAreaInset(edge: .top, spacing: 0) {
                            Color.clear
                                .background(Color.white)
                                .frame(height: 0)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            ZStack {
                HStack {
                    TextField("메시지를 입력하세요", text: $viewModel.inputText, onCommit: {
                        viewModel.sendMessage(modelContainer: modelContext.container)
                    })
                        .padding(12)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(10)
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                    Button(action: {
                        viewModel.sendMessage(modelContainer: modelContext.container)
                    }) {
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45))
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AnimatedChatRow: View {
    let message: ChatMessage
    @State private var isVisible = false

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                ChatBubble(text: message.text, isUser: true)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: isVisible)
            } else {
                ChatBubble(text: message.text, isUser: false)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 1.3), value: isVisible)
                Spacer()
            }
        }
        .onAppear {
            isVisible = true
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
