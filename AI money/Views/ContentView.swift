//
//  ContentView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    let aiManager = ExpenseAIManager()
    @State private var alerts: [String] = []

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 총 지출 금액 표시
                Text("총 지출: \(totalSpent, specifier: "%.2f")원")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                // 지출 목록
                List {
                    ForEach(expenses) { expense in
                        HStack {
                            Text(expense.title)
                            Spacer()
                            Text("\(expense.amount, specifier: "%.2f")원")
                                .foregroundColor(.red)
                        }
                    }
                    .onDelete(perform: deleteExpense)
                }

                Spacer()

                // 지출 추가 버튼
                NavigationLink(destination: AddExpenseView()) {
                    Text("지출 추가하기 ➕")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("AI Money")
            
            VStack {
                Text("AI Money 💰")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                NavigationLink("소비 분석 📊", destination: ExpenseChartView())
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                NavigationLink("카테고리별 소비 분석 📊",destination: CategoryChartView())
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                NavigationLink("카테고리별 예산 설정 💰", destination: BudgetSettingView())
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                if !alerts.isEmpty {
                    ForEach(alerts, id: \.self) { alert in
                        Text(alert)
                            .foregroundColor(.red)
                            .bold()
                    }
                }

                Button("예산 초과 확인 🔔") {
                    alerts = aiManager.checkBudgetAlerts()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()
            }
            .navigationTitle("홈")
        }
    }

    private func deleteExpense(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
