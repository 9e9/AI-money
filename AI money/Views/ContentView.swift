//
//  ContentView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ExpenseCalendarView()
                .tabItem {
                    Label("지출 내역", systemImage: "calendar")
                }
            ChartView()
                .tabItem {
                    Label("차트", systemImage: "chart.bar")
                }
            PredictionView()
                .tabItem {
                    Label("예측", systemImage: "brain.head.profile")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
