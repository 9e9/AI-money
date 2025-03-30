//
//  AI_moneyApp.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData

@main
struct AI_MoneyApp: App {
    let aiManager = ExpenseAIManager()
    let predictor = ExpensePredictor()

    init() {
        let newTrainingData = aiManager.prepareTrainingData()
        predictor?.updateTrainingData(with: newTrainingData)
        predictor?.trainModel()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            Category.self
        ])
        let container = try! ModelContainer(for: schema)
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
