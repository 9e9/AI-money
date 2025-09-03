//
//  PieChartView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI
import Charts

struct PieChartView: View {
    let data: [String: Double]
    let highlightedCategory: String?
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "식비": return .red
        case "교통": return .blue
        case "쇼핑": return .green
        case "여가": return .orange
        case "기타": return .purple
        default: return .gray
        }
    }
    
    private func categoryOpacity(for category: String) -> Double {
        guard let highlighted = highlightedCategory else { return 1.0 }
        return category == highlighted ? 1.0 : 0.3
    }
    
    private func outerRadius(for category: String) -> Double {
        guard let highlighted = highlightedCategory else { return 1.0 }
        return category == highlighted ? 1.1 : 1.0
    }

    var body: some View {
        Chart {
            ForEach(data.keys.sorted(), id: \.self) { category in
                SectorMark(
                    angle: .value("Amount", data[category] ?? 0.0),
                    innerRadius: .ratio(0.5),
                    outerRadius: .ratio(outerRadius(for: category))
                )
                .foregroundStyle(
                    categoryColor(for: category)
                        .opacity(categoryOpacity(for: category))
                )
            }
        }
        .frame(height: 200)
        .animation(.easeInOut(duration: 0.3), value: highlightedCategory)
    }
}
