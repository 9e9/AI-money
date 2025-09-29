//
//  YearMonthPickerModels.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation

// MARK: - 지출 통계 모델
struct ExpenseStatistics {
    let totalExpense: Double                    // 총 지출 금액
    let mostSpentCategory: ExpenseCategoryInfo? // 가장 많이 소비한 카테고리 정보
    let averageMonthlyExpense: Double          // 월 평균 지출 금액
    let prevYearSameMonthExpense: Double       // 작년 동월 지출 금액
    let expenseChangeRate: Double              // 작년 동월 대비 변화율 (퍼센트)
    
    // 작년 동월 데이터가 있는지 확인
    var hasPrevYearData: Bool {
        prevYearSameMonthExpense > 0
    }
    
    // 변화율을 화면에 표시할 텍스트로 변환 (예: +15.3%, -5.2%)
    var changeRateDisplayText: String {
        return "\(expenseChangeRate >= 0 ? "+" : "")\(String(format: "%.1f", expenseChangeRate))%"
    }
    
    // 변화율의 증감 상태를 텍스트로 표시 (증가/감소)
    var changeRateSubtitle: String {
        return expenseChangeRate >= 0 ? "증가" : "감소"
    }
    
    // 지출이 증가했는지 여부 확인
    var isIncreasing: Bool {
        return expenseChangeRate >= 0
    }
}

// MARK: - 카테고리별 지출 정보 모델
struct ExpenseCategoryInfo {
    let category: String  // 카테고리명 (식비, 교통, 쇼핑 등)
    let amount: Double    // 해당 카테고리의 지출 금액
    
    // 카테고리명이 비어있는지 확인
    var isEmpty: Bool {
        category.isEmpty
    }
}

// MARK: - 통계 카드 UI 데이터 모델
struct StatCardData {
    let title: String      // 카드 제목 (예: "총 지출", "최다 지출 카테고리")
    let value: String      // 카드 메인 값 (예: "150,000원", "식비")
    let subtitle: String?  // 카드 부제목 (선택사항)
    let isMain: Bool       // 메인 카드 여부 (크기와 스타일 차별화)
    let isCompact: Bool    // 컴팩트 사이즈 카드 여부
    let isChange: Bool     // 변화율 표시 카드 여부
    let isIncrease: Bool   // 증가/감소 상태 (색상 결정용)
    
    // 카드 데이터 초기화 함수
    init(title: String,
         value: String,
         subtitle: String? = nil,      // 기본값: nil
         isMain: Bool = false,         // 기본값: false
         isCompact: Bool = false,      // 기본값: false
         isChange: Bool = false,       // 기본값: false
         isIncrease: Bool = false) {   // 기본값: false
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isMain = isMain
        self.isCompact = isCompact
        self.isChange = isChange
        self.isIncrease = isIncrease
    }
}

// MARK: - 날짜 기간 모델
struct DatePeriod {
    let year: Int   // 연도
    let month: Int  // 월
    
    // 화면에 표시할 텍스트 (예: "2025년 1월")
    var displayText: String {
        return "\(year)년 \(month)월"
    }
    
    // 유효한 날짜 범위인지 검증 (2000년~2100년, 1월~12월)
    var isValid: Bool {
        return year >= 2000 && year <= 2100 && month >= 1 && month <= 12
    }
}

// MARK: - 피커 설정 상수
struct PickerConfiguration {
    static let availableYears = Array(2000...2100)  // 선택 가능한 연도 범위 (2000년~2100년)
    static let months = Array(1...12)               // 선택 가능한 월 범위 (1월~12월)
    static let monthNames = ["1월", "2월", "3월", "4월", "5월", "6월",  // 월 이름 배열 (한글)
                            "7월", "8월", "9월", "10월", "11월", "12월"]
}

// MARK: - 애니메이션 설정 상수
struct AnimationConfiguration {
    static let fadeOutDuration: Double = 0.15    // 페이드아웃 애니메이션 지속 시간
    static let fadeInDuration: Double = 0.25     // 페이드인 애니메이션 지속 시간
    static let scaleEffectDuration: Double = 0.3 // 스케일 효과 애니메이션 지속 시간
    static let minScale: Double = 0.95           // 최소 스케일 비율
    static let maxScale: Double = 1.0            // 최대 스케일 비율
}
