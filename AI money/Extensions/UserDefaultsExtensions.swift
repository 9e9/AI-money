//
//  UserDefaultsExtensions.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import Foundation

extension UserDefaults {
    private static let customCategoriesKey = "customCategories"

    var customCategories: [String] {
        get {
            if let data = data(forKey: UserDefaults.customCategoriesKey),
               let categories = try? JSONDecoder().decode([String].self, from: data) {
                return categories
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: UserDefaults.customCategoriesKey)
            }
        }
    }
}
