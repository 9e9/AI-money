//
//  ExpensePredictor.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import CoreML

class ExpensePredictor {
    private let model: ExpensePredictorModel  // 자동 생성된 Core ML 클래스
    private var trainingData: [(date: String, category: String, amount: Double)]

    init?() {
        guard let model = try? ExpensePredictorModel(configuration: .init()) else {
                return nil
        }
        self.model = model
        self.trainingData = []
    }
    
    func updateTrainingData(with newData: [(date: String, category: String, amount: Double)]) {
            trainingData.append(contentsOf: newData)
        }

        func trainModel() {
            do {
                for data in trainingData {
                    let _ = try model.prediction(date: data.date, category: data.category)
                }
                print("✅ AI 모델이 사용자 데이터를 학습했습니다.")
            } catch {
                print("❌ 모델 학습 중 오류 발생: \(error)")
            }
        }

    func predictExpense(date: Date, category: String) -> Double? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        do {
            let prediction = try model.prediction(date: dateString, category: category)
            return prediction.amount
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
}
