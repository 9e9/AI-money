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

            VStack {
                Text("🤖")
                Text("AI money")
                    .font(.headline)
            }

            VStack {
                Text("🛠")
                Text("버전: 1.0 beta")
                    .font(.subheadline)
            }
            
            VStack {
                Text("👨‍💻")
                Text("개발: 조준희")
                    .font(.subheadline)
            }

            VStack {
                Text("🏫")
                Text("상지대학교\n컴퓨터공학과\n학번: 202048049")
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
