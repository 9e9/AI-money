//
//  ExpenseListView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var showingAddExpense = false
    @State private var selectedDate: Date = Date() // 기본값 설정
    
    var body: some View {
        NavigationView {
            List(viewModel.expenses) { expense in
                VStack(alignment: .leading) {
                    Text(expense.category)
                        .font(.headline)
                    Text("\(expense.amount, specifier: "%.2f") 원")
                        .font(.subheadline)
                }
            }
            .navigationTitle("지출 내역")
            .toolbar {
                Button(action: {
                    showingAddExpense = true
                }) {
                    Label("지출 추가", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel, selectedDate: selectedDate)
            }
        }
    }
}
