//
//  SettingsView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct SettingsView: View {
    let aiManager = ExpenseAIManager()
    let predictor = ExpensePredictor()

    var body: some View {
        VStack {
            Text("AI 소비 패턴 학습 📊")
                .font(.title)
                .bold()
                .padding()

            Button("AI 학습 시작 🚀") {
                let newTrainingData = aiManager.prepareTrainingData()
                predictor?.updateTrainingData(with: newTrainingData)
                predictor?.trainModel()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .navigationTitle("설정")
    }
}
