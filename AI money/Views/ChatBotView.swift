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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { message in
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
                .background(Color.white)
                .onChange(of: viewModel.messages) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation {
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

            ZStack {
                HStack {
                    TextField("메시지를 입력하세요", text: $viewModel.inputText, onCommit: {
                        viewModel.sendMessage(modelContext: modelContext)
                    })
                        .padding(12)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(10)
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                    Button(action: {
                        viewModel.sendMessage(modelContext: modelContext)
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
