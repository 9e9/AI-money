//
//  Category.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String

    init(name: String) {
        self.name = name
    }
}
