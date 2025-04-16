//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseViewModel

    @State private var sortOrder: SortOrder = .defaultOrder // 기본 정렬 옵션

    // 정렬 옵션
    enum SortOrder: String, CaseIterable, Identifiable {
        case defaultOrder = "기본순"
        case highToLow = "높은 순"
        case lowToHigh = "낮은 순"

        var id: String { self.rawValue }
    }

    // 사전에 정의된 카테고리 목록
    private let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]

    // 카테고리별 총합 계산 및 정렬
    private var sortedCategoryTotals: [(String, Double)] {
        // 1. 모든 카테고리를 포함한 기본 데이터 생성
        let totals = viewModel.expenses.reduce(into: [String: Double]()) { result, expense in
            result[expense.category, default: 0.0] += expense.amount
        }

        // 2. 미사용된 카테고리는 0으로 설정
        let completeTotals = predefinedCategories.reduce(into: [String: Double]()) { result, category in
            result[category] = totals[category, default: 0.0]
        }

        // 3. 정렬 로직
        let sorted: [(String, Double)]
        switch sortOrder {
        case .highToLow:
            sorted = completeTotals.sorted { $0.value > $1.value } // 높은 순
        case .lowToHigh:
            sorted = completeTotals.sorted { $0.value < $1.value } // 낮은 순
        case .defaultOrder:
            sorted = completeTotals.sorted { $0.key < $1.key } // 기본: 알파벳 순 정렬
        }
        return sorted
    }

    var body: some View {
        VStack {
            Text("원형 차트")
                .font(.headline)

            // 원형 그래프 (예: Swift Charts 라이브러리 사용)
            PieChartView(data: Dictionary(uniqueKeysWithValues: sortedCategoryTotals))

            Divider()
                .padding(.vertical, 10)

            // 정렬 메뉴 (드롭다운 형식)
            HStack {
                Text("카테고리별 총 지출")
                    .font(.headline)

                Spacer()

                Menu {
                    Button(action: { sortOrder = .defaultOrder }) {
                        Label("기본순", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { sortOrder = .highToLow }) {
                        Label("높은 순", systemImage: "arrow.down")
                    }
                    Button(action: { sortOrder = .lowToHigh }) {
                        Label("낮은 순", systemImage: "arrow.up")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal") // 밑줄 세 개 아이콘
                        .font(.title2)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal)

            // 카테고리별 총 지출 목록
            List {
                ForEach(sortedCategoryTotals, id: \.0) { category, total in
                    HStack {
                        Text(category)
                            .font(.body)
                        Spacer()
                        Text("\(Int(total)) 원") // 소수점 제거
                            .fontWeight(.bold)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding()
    }
}

// 원형 차트 컴포넌트 (Swift Charts 예제)
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
