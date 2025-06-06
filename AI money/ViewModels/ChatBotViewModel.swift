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
