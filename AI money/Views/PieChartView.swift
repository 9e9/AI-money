//
//  PieChartView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI  // SwiftUI 프레임워크 import (UI 구성을 위함)
import Charts   // Charts 프레임워크 import (파이 차트 생성을 위함)

/// 지출 카테고리별 데이터를 파이 차트로 시각화하는 SwiftUI View
/// 각 카테고리별 지출 비율을 원형 차트로 표시하며, 특정 카테고리 강조 기능을 제공
struct PieChartView: View {
    // MARK: - Properties (뷰에서 사용하는 데이터)
    let data: [String: Double]              // 카테고리별 지출 금액 데이터 (카테고리명: 금액)
    let highlightedCategory: String?        // 현재 강조 표시할 카테고리 (nil이면 모든 카테고리 동일하게 표시)
    
    /// 카테고리에 따른 색상을 반환하는 private 함수
    /// - Parameter category: 카테고리 이름 (예: "식비", "교통" 등)
    /// - Returns: 해당 카테고리에 맞는 Color 객체
    private func categoryColor(for category: String) -> Color {
        switch category {                   // 카테고리 이름에 따라 분기 처리
        case "식비": return .red           // 식비는 빨간색으로 표시
        case "교통": return .blue          // 교통비는 파란색으로 표시
        case "쇼핑": return .green         // 쇼핑은 초록색으로 표시
        case "여가": return .orange        // 여가비는 주황색으로 표시
        case "기타": return .purple        // 기타는 보라색으로 표시
        default: return .gray              // 정의되지 않은 카테고리는 회색으로 표시
        }
    }
    
    /// 카테고리의 투명도를 결정하는 private 함수 (강조 효과를 위함)
    /// - Parameter category: 카테고리 이름
    /// - Returns: 0.0(완전 투명) ~ 1.0(완전 불투명) 사이의 Double 값
    private func categoryOpacity(for category: String) -> Double {
        guard let highlighted = highlightedCategory else { return 1.0 }  // 강조할 카테고리가 없으면 모두 불투명
        return category == highlighted ? 1.0 : 0.3                      // 강조 카테고리는 불투명, 나머지는 반투명
    }
    
    /// 카테고리의 외부 반지름 크기를 결정하는 private 함수 (강조 효과를 위함)
    /// - Parameter category: 카테고리 이름
    /// - Returns: 차트 반지름의 비율 (1.0이 기본 크기)
    private func outerRadius(for category: String) -> Double {
        guard let highlighted = highlightedCategory else { return 1.0 }  // 강조할 카테고리가 없으면 모두 동일한 크기
        return category == highlighted ? 1.1 : 1.0                      // 강조 카테고리는 10% 크게, 나머지는 기본 크기
    }

    var body: some View {
        Chart {                             // Charts 프레임워크의 Chart 컨테이너 시작
            // 데이터의 모든 카테고리를 정렬된 순서로 반복 처리
            ForEach(data.keys.sorted(), id: \.self) { category in
                SectorMark(                 // 파이 차트의 각 섹터(조각)를 생성하는 마크
                    // 각 섹터의 각도 크기 설정 (지출 금액에 비례)
                    angle: .value("Amount", data[category] ?? 0.0),
                    // 내부 반지름 설정 (0.5 = 50%, 도넛 차트 형태로 만듦)
                    innerRadius: .ratio(0.5),
                    // 외부 반지름 설정 (강조 효과에 따라 동적으로 변화)
                    outerRadius: .ratio(outerRadius(for: category))
                )
                .foregroundStyle(           // 섹터의 색상과 투명도 설정
                    categoryColor(for: category)        // 카테고리별 색상 적용
                        .opacity(categoryOpacity(for: category))  // 강조 효과에 따른 투명도 적용
                )
            }
        }
        .frame(height: 200)                 // 차트의 높이를 200포인트로 고정
        // 강조 카테고리가 변경될 때 부드러운 애니메이션 효과 적용
        .animation(.easeInOut(duration: 0.3), value: highlightedCategory)
    }
}
