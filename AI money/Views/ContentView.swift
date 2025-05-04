//
//  ContentView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExpenseViewModel.shared

    var body: some View {
        TabView {
            ExpenseCalendarView(viewModel: viewModel)
                .tabItem {
                    Label("지출 내역", systemImage: "calendar")
                }
            ChartView(viewModel: viewModel)
                .tabItem {
                    Label("차트", systemImage: "chart.bar")
                }
            PredictionView()
                .tabItem {
                    Label("예측", systemImage: "brain.head.profile")
                }
        }
        .onAppear {
            viewModel.setContext(modelContext)
        }
        .preferredColorScheme(.light)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
