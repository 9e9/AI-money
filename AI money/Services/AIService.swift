//
//  AIService.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation
import CoreML

class AIService {
    static let shared = AIService()
    
    private init() {}
    
    func analyzeSpendingPattern(expenses: [Expense]) -> String {
        return "AI 모델을 기반으로 한 예측"
    }
}
