//
//  Date+Extensions.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation // Foundation 프레임워크 import (Date, Calendar 등 기본 타입 사용)

// MARK: - Date 타입 확장
/// Date 타입에 편의 프로퍼티를 추가하는 확장
/// 캘린더 관련 작업에서 년도와 월을 쉽게 추출할 수 있도록 도움
extension Date {
    
    /// 현재 Date 객체에서 연도(년)를 추출하는 계산 프로퍼티
    /// - Returns: Int 타입의 연도 값 (예: 2025)
    /// - 사용 예시: let currentYear = Date().year
    var year: Int {
        Calendar.current.component(.year, from: self) // 현재 캘린더에서 연도 컴포넌트 추출
    }
    
    /// 현재 Date 객체에서 월을 추출하는 계산 프로퍼티
    /// - Returns: Int 타입의 월 값 (1-12, 1월이 1, 12월이 12)
    /// - 사용 예시: let currentMonth = Date().month
    var month: Int {
        Calendar.current.component(.month, from: self) // 현재 캘린더에서 월 컴포넌트 추출
    }
}
