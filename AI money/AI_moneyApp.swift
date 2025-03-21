//
//  AI_moneyApp.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import SwiftUI
import SwiftData

@main
struct Al_moneyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Expense.self, Category.self])
    }
}
