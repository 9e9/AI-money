//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation
import SwiftData

@Model
class Expense {
    @Attribute(.unique) var id: UUID
    var date: Date
    var category: String
    var amount: Double
    var note: String

    init(date: Date, category: String, amount: Double, note: String) {
        self.id = UUID()
        self.date = date
        self.category = category
        self.amount = amount
        self.note = note
    }
}
