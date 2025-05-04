//
//  AI_moneyApp.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData

@main
struct AI_moneyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Expense.self)
        }
    }
}
