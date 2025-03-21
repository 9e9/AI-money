//
//  ExpenseListView.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @State private var isPresentingAddExpenseView = false
    @StateObject var expenseViewModel = ExpenseViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(expenses) { expense in
                    NavigationLink {
                        EditExpenseView(expense: expense)
                    } label: {
                        HStack {
                            Text(expense.date, style: .date)
                            Spacer()
                            Text("\(expense.amount, specifier: "%.0f")원")
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            expenseViewModel.deleteExpense(modelContext: modelContext, expense: expense)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("지출 내역")
            .toolbar {
                Button {
                    isPresentingAddExpenseView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $isPresentingAddExpenseView) {
                AddExpenseView()
            }
        }
    }
}
