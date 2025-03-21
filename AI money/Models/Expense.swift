//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var amount: Double
    var memo: String // description 대신 memo 사용
    var category: Category?

    init(date: Date, amount: Double, description: String, category: Category? = nil) {
        self.date = date
        self.amount = amount
        self.memo = description // description 대신 memo 사용
        self.category = category
    }
}
