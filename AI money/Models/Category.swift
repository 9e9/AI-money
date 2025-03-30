//
//  Category.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftData
import Foundation

@Model
class Category {
    var id: UUID
    var name: String
    var color: String  // HEX 코드로 저장 가능
    var expenses: [Expense] = []

    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
    }
}
