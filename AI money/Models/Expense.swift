//
//  Expense.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation // Foundation 프레임워크 임포트 (기본 데이터 타입과 유틸리티 제공)
import SwiftData // SwiftData 프레임워크 임포트 (데이터 지속성을 위한 프레임워크)

@Model // SwiftData의 @Model 매크로 - 이 클래스를 데이터베이스 모델로 지정
class Expense { // 지출 데이터를 나타내는 클래스 정의
    @Attribute(.unique) var id: UUID // 각 지출 항목의 고유 식별자, 중복 허용 안함
    var date: Date // 지출이 발생한 날짜
    var category: String // 지출 카테고리 (예: 식비, 교통비, 쇼핑 등)
    var amount: Double // 지출 금액 (소수점 포함 가능한 실수형)
    var note: String // 지출에 대한 메모나 설명

    // Expense 객체를 생성하는 초기화 메서드
    init(date: Date, category: String, amount: Double, note: String) {
        self.id = UUID() // 새로운 고유 식별자 자동 생성
        self.date = date // 전달받은 날짜로 설정
        self.category = category // 전달받은 카테고리로 설정
        self.amount = amount // 전달받은 금액으로 설정
        self.note = note // 전달받은 메모로 설정
    }
}
