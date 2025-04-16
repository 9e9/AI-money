//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation

struct Expense: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let category: String
    let amount: Double
    let note: String

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.category == rhs.category &&
               lhs.amount == rhs.amount &&
               lhs.note == rhs.note
    }
}
