//
//  ChatBotViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftData

@MainActor
class ChatBotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var conversationContext = ConversationContext()

    func sendMessage(modelContainer: ModelContainer) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMessage)
        inputText = ""

        let currentContext = conversationContext
        
        Task {
            let (aiReply, newContext) = await AIService.shared.reply(
                to: trimmed,
                modelContainer: modelContainer,
                conversationContext: currentContext
            )
            
            await MainActor.run {
                self.conversationContext = newContext
                self.messages.append(ChatMessage(text: aiReply, isUser: false))
            }
        }
    }
}
