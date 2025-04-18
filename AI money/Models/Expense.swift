//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation

struct Expense: Identifiable, Equatable {
    let id: UUID = UUID()
    let date: Date
    let category: String
    let amount: Double
    let note: String
}
