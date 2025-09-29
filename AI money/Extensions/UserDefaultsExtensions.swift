//
//  UserDefaultsExtensions.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import Foundation

// UserDefaults 클래스에 대한 확장 - 사용자 정의 카테고리를 저장하고 불러오는 기능 추가
extension UserDefaults {
    // UserDefaults에서 사용할 키 값을 상수로 정의 (사용자 정의 카테고리 저장용)
    private static let customCategoriesKey = "customCategories"

    // 사용자 정의 카테고리 배열을 저장/불러오는 계산 속성
    var customCategories: [String] {
        // getter: UserDefaults에서 사용자 정의 카테고리 목록을 불러오기
        get {
            // 키에 해당하는 Data 객체를 가져와서 JSONDecoder로 [String] 배열로 디코딩
            if let data = data(forKey: UserDefaults.customCategoriesKey),
               let categories = try? JSONDecoder().decode([String].self, from: data) {
                return categories // 디코딩 성공 시 카테고리 배열 반환
            }
            return [] // 데이터가 없거나 디코딩 실패 시 빈 배열 반환
        }
        // setter: 새로운 카테고리 배열을 UserDefaults에 저장
        set {
            // [String] 배열을 JSONEncoder로 Data로 인코딩하여 UserDefaults에 저장
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: UserDefaults.customCategoriesKey) // 인코딩된 Data를 저장
            }
        }
    }
}
