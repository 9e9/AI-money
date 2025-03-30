//
//  PredictionViewModel.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation

class PredictionViewModel: ObservableObject {
    @Published var prediction: String = ""
    
    init() {
        loadPrediction()
    }
    
    func loadPrediction() {
        // Call AIService to get prediction
        prediction = "당신의 소비 패턴은 다음 달에 식비 지출이 더 많을 것으로 예측됩니다."
    }
}
