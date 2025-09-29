//
//  ChatMessage.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

// 채팅 메시지를 나타내는 구조체
struct ChatMessage: Identifiable, Equatable {
    let id = UUID() // 각 메시지의 고유 식별자 (SwiftUI의 List나 ForEach에서 사용)
    let text: String // 메시지 내용 텍스트
    let isUser: Bool // 사용자가 보낸 메시지인지 AI가 보낸 메시지인지 구분
    let timestamp: Date // 메시지가 생성된 시간
    
    // 기본 생성자 - 현재 시간을 타임스탬프로 설정
    init(text: String, isUser: Bool) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date() // 현재 시간으로 설정
    }
    
    // 타임스탬프를 직접 지정할 수 있는 생성자
    init(text: String, isUser: Bool, timestamp: Date) {
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp // 지정된 시간으로 설정
    }
}
