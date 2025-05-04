//
//  InformationView.swift
//  AI money
//
//  Created by 조준희 on 4/19/25.
//

import SwiftUI

struct InformationView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("AI money") // 원하는 텍스트를 이곳에 입력하세요.
                .font(.body) // 텍스트 스타일 설정
                .multilineTextAlignment(.center) // 가운데 정렬
                .padding()
            Spacer()
        }
        .navigationTitle("앱 정보")
    }
}
