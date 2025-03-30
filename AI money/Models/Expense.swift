//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation

struct Expense: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var category: String
    var amount: Double
    var note: String
}
