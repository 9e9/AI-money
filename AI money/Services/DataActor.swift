//
//  DataActor.swift
//  AI money
//
//  Created by 조준희 on 9/3/25.
//

import SwiftData
import Foundation

@ModelActor
actor DataActor {
    struct ExpenseData: Sendable {
        let id: UUID
        let date: Date
        let category: String
        let amount: Double
        let note: String
        
        init(from expense: Expense) {
            self.id = expense.id
            self.date = expense.date
            self.category = expense.category
            self.amount = expense.amount
            self.note = expense.note
        }
    }
    
    func fetchExpenses(from: Date, to: Date) async -> [ExpenseData] {
        let request = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= from && $0.date < to }
        )
        let expenses = (try? modelContext.fetch(request)) ?? []
        return expenses.map { ExpenseData(from: $0) }
    }
    
    func getAllCategories() async -> [String] {
        let request = FetchDescriptor<Expense>()
        let expenses = (try? modelContext.fetch(request)) ?? []
        let unique = Set(expenses.map { $0.category })
        return Array(unique)
    }
    
    func getAllExpenses() async -> [ExpenseData] {
        let request = FetchDescriptor<Expense>()
        let expenses = (try? modelContext.fetch(request)) ?? []
        return expenses.map { ExpenseData(from: $0) }
    }
}
