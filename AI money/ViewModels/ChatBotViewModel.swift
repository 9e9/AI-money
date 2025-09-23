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
    @Published var isTyping: Bool = false

    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTyping
    }

    func sendMessage(modelContainer: ModelContainer) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !isTyping else { return }
        
        let userMessage = ChatMessage(text: trimmed, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isTyping = true

        let currentContext = conversationContext
        
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            let (aiReply, newContext) = await AIService.shared.reply(
                to: trimmed,
                modelContainer: modelContainer,
                conversationContext: currentContext
            )
            
            await MainActor.run {
                self.conversationContext = newContext
                self.isTyping = false
                self.messages.append(ChatMessage(text: aiReply, isUser: false))
            }
        }
    }
    
    func stopTyping() {
        isTyping = false
    }
}
