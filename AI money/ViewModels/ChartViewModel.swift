//
//  ChartViewModel.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation
import SwiftUI

// MARK: - 카테고리 총합 데이터 모델
/// 차트에서 사용할 카테고리별 총 지출 금액을 담는 구조체
/// Hashable을 준수하여 SwiftUI의 리스트나 ForEach에서 고유 식별자로 사용 가능
struct CategoryTotal: Hashable {
    let category: String    // 카테고리 이름 (예: "식비", "교통" 등)
    let total: Double      // 해당 카테고리의 총 지출 금액
}

// MARK: - 차트 화면의 뷰모델
/// 차트 화면에서 사용되는 데이터와 비즈니스 로직을 담당하는 뷰모델 클래스
/// @MainActor: UI 관련 작업이므로 메인 스레드에서만 실행되도록 보장
/// ObservableObject: SwiftUI 뷰에서 상태 변화를 감지할 수 있도록 함
@MainActor
class ChartViewModel: ObservableObject {
    // MARK: - Published Properties (뷰에서 관찰되는 상태 변수들)
    
    /// 카테고리 정렬 순서 (기본순/높은순/낮은순)
    @Published var sortOrder: SortOrder = .defaultOrder
    
    /// 선택된 연도 (차트에서 표시할 데이터의 연도)
    @Published var selectedYear: Int
    
    /// 선택된 월 (차트에서 표시할 데이터의 월)
    @Published var selectedMonth: Int
    
    /// 연월 선택 피커의 표시 여부를 제어하는 플래그
    @Published var isShowingYearMonthPicker = false

    // MARK: - 정렬 순서 열거형
    /// 카테고리 데이터의 정렬 방식을 정의하는 열거형
    /// CaseIterable: 모든 케이스를 배열로 가져올 수 있음
    /// Identifiable: SwiftUI에서 고유 식별자로 사용 가능
    enum SortOrder: String, CaseIterable, Identifiable {
        case defaultOrder = "기본순"    // 미리 정의된 카테고리 순서대로 정렬
        case highToLow = "높은 순"     // 지출 금액이 높은 순으로 정렬
        case lowToHigh = "낮은 순"     // 지출 금액이 낮은 순으로 정렬

        /// Identifiable 프로토콜 요구사항 - 각 케이스의 고유 식별자
        var id: String { self.rawValue }
    }

    // MARK: - Dependencies
    
    /// 지출 데이터 관리를 담당하는 서비스 (의존성 주입을 통해 전달받음)
    private let expenseService: ExpenseServiceProtocol

    // MARK: - Static Properties
    
    /// 숫자를 포맷팅할 때 사용하는 NumberFormatter (정적 변수로 성능 최적화)
    /// 단순한 숫자 형태로만 표시 (천 단위 구분자나 소수점 없음)
    private static let plainNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none  // 기본 숫자 스타일 (1234 -> "1234")
        return formatter
    }()

    // MARK: - Initializer
    
    /// 뷰모델 초기화 메서드
    /// - Parameter expenseService: 지출 데이터를 관리하는 서비스
    init(expenseService: ExpenseServiceProtocol) {
        self.expenseService = expenseService
        
        // 현재 날짜 정보를 가져와서 초기값으로 설정
        let now = Date()
        let calendar = Calendar.current
        
        // @Published 프로퍼티를 직접 초기화 (Published 래퍼를 통해)
        _selectedYear = Published(initialValue: calendar.component(.year, from: now))
        _selectedMonth = Published(initialValue: calendar.component(.month, from: now))
    }

    // MARK: - Computed Properties

    /// 모든 사용 가능한 카테고리 목록을 반환
    /// 미리 정의된 기본 카테고리 + 사용자가 추가한 커스텀 카테고리
    var allCategories: [String] {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]  // 앱에서 기본 제공하는 카테고리들
        return predefinedCategories + expenseService.customCategories      // 기본 카테고리 + 사용자 정의 카테고리
    }

    /// 선택된 연월에 해당하는 지출 데이터만 필터링하여 반환
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        return expenseService.expenses.filter { expense in
            // 각 지출의 날짜에서 연도와 월만 추출
            let expenseDate = calendar.dateComponents([.year, .month], from: expense.date)
            // 선택된 연도와 월이 일치하는지 확인
            return expenseDate.year == selectedYear && expenseDate.month == selectedMonth
        }
    }

    /// 필터링된 지출들의 총 금액을 계산하여 반환
    var totalAmount: Double {
        return filteredExpenses.reduce(0) { $0 + $1.amount }  // reduce를 사용해 모든 지출 금액을 합산
    }

    /// 카테고리별 총 지출 금액을 정렬 순서에 따라 정렬하여 반환
    var sortedCategoryTotals: [CategoryTotal] {
        // 1단계: 필터링된 지출들을 카테고리별로 그룹화하고 합산
        let totals = filteredExpenses.reduce(into: [String: Double]()) { result, expense in
            result[expense.category, default: 0.0] += expense.amount
        }

        // 2단계: 모든 카테고리에 대해 값이 없는 경우 0.0으로 초기화
        // (지출이 없는 카테고리도 차트에 표시하기 위함)
        let completeTotals = allCategories.reduce(into: [String: Double]()) { result, category in
            result[category] = totals[category, default: 0.0]
        }

        // 3단계: 선택된 정렬 순서에 따라 정렬 수행
        let sorted: [CategoryTotal]
        switch sortOrder {
        case .highToLow:
            // 높은 순 정렬: 금액이 같을 경우 기본 카테고리 순서 유지
            sorted = completeTotals.sorted {
                if $0.value == $1.value {
                    return allCategories.firstIndex(of: $0.key)! < allCategories.firstIndex(of: $1.key)!
                }
                return $0.value > $1.value
            }.map { CategoryTotal(category: $0.key, total: $0.value) }
            
        case .lowToHigh:
            // 낮은 순 정렬: 금액이 같을 경우 기본 카테고리 순서 유지
            sorted = completeTotals.sorted {
                if $0.value == $1.value {
                    return allCategories.firstIndex(of: $0.key)! < allCategories.firstIndex(of: $1.key)!
                }
                return $0.value < $1.value
            }.map { CategoryTotal(category: $0.key, total: $0.value) }
            
        case .defaultOrder:
            // 기본 순서: allCategories 배열의 순서대로 정렬
            sorted = allCategories.map { CategoryTotal(category: $0, total: completeTotals[$0] ?? 0.0) }
        }
        return sorted
    }

    // MARK: - Methods

    /// 선택된 연월을 현재 날짜로 초기화하고 정렬 순서를 기본으로 재설정
    func resetToCurrentDate() {
        let now = Date()
        let calendar = Calendar.current
        selectedYear = calendar.component(.year, from: now)    // 현재 연도로 설정
        selectedMonth = calendar.component(.month, from: now)  // 현재 월로 설정
        sortOrder = .defaultOrder                              // 정렬을 기본 순서로 재설정
    }

    /// 특정 연도와 월로 설정하고 정렬 순서를 기본으로 재설정
    /// - Parameters:
    ///   - year: 설정할 연도
    ///   - month: 설정할 월 (1-12)
    func setYearMonth(year: Int, month: Int) {
        selectedYear = year
        selectedMonth = month
        sortOrder = .defaultOrder  // 연월 변경 시 정렬을 기본 순서로 재설정
    }

    /// 연도를 문자열로 포맷팅하여 반환
    /// NumberFormatter를 사용해 일관된 형식으로 표시
    /// - Parameter year: 포맷팅할 연도
    /// - Returns: 포맷팅된 연도 문자열 (실패 시 원본 숫자를 문자열로 변환)
    func formatYear(_ year: Int) -> String {
        return Self.plainNumberFormatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }
}
