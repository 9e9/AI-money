//
//  ExpenseCalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseCalendarView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @State private var showingAddExpense = false
    @State private var showingDeleteAlert = false
    @State private var showInformationView = false
    @State private var selectedDate: Date = Date()
    @State private var expenseToDelete: Expense? = nil
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())

    var body: some View {
        NavigationView {
            VStack {
                CalendarView(
                    viewModel: viewModel, selectedYear: $selectedYear, selectedMonth: $selectedMonth, showHeaders: true) { date in
                    VStack {
                        Text(String(Calendar.current.component(.day, from: date)))
                            .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                            .padding(4)
                            .background(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                        
                        let totalExpense = viewModel.totalExpense(for: date)
                        Text(totalExpense > 0 ? "\(Int(totalExpense)) 원" : " ")
                            .font(.caption)
                            .foregroundColor(totalExpense > 0 ? .secondary : .clear)
                            .lineLimit(1)
                            .frame(height: 0.5)
                    }
                    .padding(4)
                }
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .frame(maxHeight: 340)

                ScrollView {
                    VStack {
                        let dailyExpenses = viewModel.expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
                        if dailyExpenses.isEmpty {
                            Text("지출 없음")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding()
                                .transition(.opacity)
                        } else {
                            ForEach(dailyExpenses) { expense in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(expense.category)
                                            .font(.headline)
                                        HStack {
                                            Text("\(Int(expense.amount)) 원")
                                                .font(.subheadline)
                                            if !expense.note.isEmpty {
                                                Text("- \(expense.note)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        expenseToDelete = expense
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .alert(isPresented: $showingDeleteAlert) {
                                        Alert(
                                            title: Text("삭제 확인"),
                                            message: Text("이 지출 내역을 삭제하시겠습니까?"),
                                            primaryButton: .destructive(Text("삭제")) {
                                                withAnimation {
                                                    if let expenseToDelete = expenseToDelete {
                                                        viewModel.removeExpense(expenseToDelete)
                                                    }
                                                }
                                            },
                                            secondaryButton: .cancel(Text("취소"))
                                        )
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
                }
                .background(Color.gray.opacity(0.5))
                .frame(minWidth: 400, maxHeight: 350)
                .padding(.top, 30)
                .padding(.bottom, -30)
            }
            .navigationTitle("")
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
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        showInformationView = true
                    }) {
                        Text("AI money")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                    }
                    .padding(.leading, -7)
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 35)
            .sheet(isPresented: $showInformationView) {
                NavigationView {
                    InformationView()
                }
            }
        }
    }
}
