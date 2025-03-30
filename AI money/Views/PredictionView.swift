//
//  PredictionView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct PredictionView: View {
    @StateObject private var viewModel = PredictionViewModel()
    
    var body: some View {
        VStack {
            Text("AI 예측")
                .font(.largeTitle)
            // Add AI prediction details here
        }
    }
}

struct PredictionView_Previews: PreviewProvider {
    static var previews: some View {
        PredictionView()
    }
}
