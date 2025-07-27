//
//  ChatBotViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftData

class ChatBotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var conversationContext = ConversationContext()

    func sendMessage(modelContext: ModelContext) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMessage)
        inputText = ""

        let currentContext = conversationContext
        Task {
            let (aiReply, newContext) = await AIService.shared.reply(
                to: trimmed,
                context: modelContext,
                conversationContext: currentContext
            )
            await MainActor.run {
                conversationContext = newContext
                messages.append(ChatMessage(text: aiReply, isUser: false))
            }
        }
    }
}
