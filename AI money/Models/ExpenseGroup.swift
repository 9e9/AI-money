//
//  ExpenseGroup.swift
//  AI money
//
//  Created by 조준희 on 6/6/25.
//

import Foundation

struct ExpenseGroup: Identifiable, Equatable {
    let id = UUID()
    var category: String = "기타"
    var amount: String = ""
    var formattedAmount: String = ""
    var note: String = ""
    
    var isValid: Bool {
        guard !amount.isEmpty else { return false }
        guard let doubleAmount = Double(amount), doubleAmount > 0 else { return false }
        return doubleAmount <= 10_000_000 // Maximum 10 million won
    }
    
    var amountValue: Double? {
        return Double(amount)
    }
    
    mutating func updateAmount(_ newAmount: String) {
        let filtered = newAmount.replacingOccurrences(of: ",", with: "")
        if let number = Int(filtered), number >= 0 {
            amount = String(number)
            formattedAmount = formatWithComma(String(number))
        } else if filtered.isEmpty {
            amount = ""
            formattedAmount = ""
        }
    }
    
    private func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? numberString
    }
}
