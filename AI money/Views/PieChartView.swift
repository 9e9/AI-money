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

    var body: some View {
        Chart {
            ForEach(data.keys.sorted(), id: \.self) { category in
                SectorMark(
                    angle: .value("Amount", data[category] ?? 0.0),
                    innerRadius: .ratio(0.5),
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(by: .value("Category", category))
            }
        }
        .frame(height: 200)
    }
}
