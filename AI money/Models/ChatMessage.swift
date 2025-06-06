//
//  ChatMessage.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
