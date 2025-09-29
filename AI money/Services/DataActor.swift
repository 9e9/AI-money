//
//  DataActor.swift
//  AI money
//
//  Created by 조준희 on 9/3/25.
//

import SwiftData  // 데이터베이스 접근을 위한 프레임워크
import Foundation

// MARK: - SwiftData 비동기 데이터 액세스를 위한 액터
// @ModelActor 어노테이션으로 SwiftData 모델 컨텍스트에 안전하게 접근
@ModelActor
actor DataActor {
    
    // MARK: - Sendable 준수 데이터 구조체
    // Actor 간 안전한 데이터 전달을 위한 Sendable 프로토콜 준수 구조체
    struct ExpenseData: Sendable {
        let id: UUID              // 지출 고유 식별자
        let date: Date            // 지출 발생 날짜
        let category: String      // 지출 카테고리 (식비, 교통비 등)
        let amount: Double        // 지출 금액
        let note: String          // 지출 메모/설명
        
        // Expense 모델 객체로부터 ExpenseData를 생성하는 초기화 메서드
        init(from expense: Expense) {
            self.id = expense.id
            self.date = expense.date
            self.category = expense.category
            self.amount = expense.amount
            self.note = expense.note
        }
    }
    
    // MARK: - 기간별 지출 데이터 조회
    /// 지정된 날짜 범위 내의 지출 데이터를 조회하는 비동기 메서드
    /// - Parameters:
    ///   - from: 조회 시작 날짜 (포함)
    ///   - to: 조회 종료 날짜 (미포함)
    /// - Returns: 해당 기간의 지출 데이터 배열
    func fetchExpenses(from: Date, to: Date) async -> [ExpenseData] {
        // FetchDescriptor로 날짜 범위 조건 설정
        let request = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= from && $0.date < to }
        )
        // 데이터베이스에서 조건에 맞는 지출 데이터 조회 (실패 시 빈 배열 반환)
        let expenses = (try? modelContext.fetch(request)) ?? []
        // Expense 모델을 ExpenseData로 변환하여 반환
        return expenses.map { ExpenseData(from: $0) }
    }
    
    // MARK: - 모든 카테고리 목록 조회
    /// 데이터베이스에 저장된 모든 지출 카테고리의 고유 목록을 조회
    /// - Returns: 중복 제거된 카테고리 이름 배열
    func getAllCategories() async -> [String] {
        // 모든 지출 데이터 조회를 위한 FetchDescriptor
        let request = FetchDescriptor<Expense>()
        // 전체 지출 데이터 조회 (실패 시 빈 배열)
        let expenses = (try? modelContext.fetch(request)) ?? []
        // 카테고리만 추출하여 Set으로 중복 제거
        let unique = Set(expenses.map { $0.category })
        // Set을 Array로 변환하여 반환
        return Array(unique)
    }
    
    // MARK: - 모든 지출 데이터 조회
    /// 데이터베이스에 저장된 모든 지출 데이터를 조회하는 메서드
    /// - Returns: 모든 지출 데이터 배열 (ExpenseData 형태)
    func getAllExpenses() async -> [ExpenseData] {
        // 조건 없이 모든 데이터 조회를 위한 FetchDescriptor
        let request = FetchDescriptor<Expense>()
        // 모든 지출 데이터 조회 (실패 시 빈 배열)
        let expenses = (try? modelContext.fetch(request)) ?? []
        // Expense 모델을 ExpenseData로 변환하여 반환
        return expenses.map { ExpenseData(from: $0) }
    }
}
