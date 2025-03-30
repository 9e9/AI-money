//
//  ExpenseCalenderView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseCalendarView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var showingAddExpense = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            VStack {
                CalendarView(interval: DateInterval(start: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, end: Date())) { date in
                    VStack {
                        Text(String(Calendar.current.component(.day, from: date)))
                            .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                            .padding(4)
                            .background(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedDate = date
                            }
                    }
                    .padding(4)
                }
                .environment(\.locale, Locale(identifier: "ko_KR"))

                List {
                    ForEach(viewModel.expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.category)
                                    .font(.headline)
                                Text("\(expense.amount, specifier: "%.2f") 원")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Button(action: {
                                viewModel.removeExpense(expense)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
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
                AddExpenseView(viewModel: viewModel)
            }
        }
    }
}

struct ExpenseCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseCalendarView()
    }
}
