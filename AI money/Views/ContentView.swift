import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ExpenseViewModel() // ViewModel 생성

    var body: some View {
        TabView {
            ExpenseCalendarView(viewModel: viewModel) // ViewModel 전달
                .tabItem {
                    Label("지출 내역", systemImage: "calendar")
                }
            ChartView(viewModel: viewModel) // ViewModel 전달
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
