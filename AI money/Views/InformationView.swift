//
//  InformationView.swift
//  AI money
//
//  Created by 조준희 on 4/19/25.
//

import SwiftUI

struct InformationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            HStack {
                Text("🤖") //
                Text("AI money")
                    .font(.headline)
            }

            HStack {
                Text("🛠")
                Text("버전: 1.0 beta")
                    .font(.subheadline)
            }
            
            HStack {
                Text("👨‍💻")
                Text("개발: 조준희")
                    .font(.subheadline)
            }

            HStack {
                Text("🏫")
                Text("소속: 상지대학교 컴퓨터공학과 202048049")
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
        .navigationTitle("앱 정보")
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
