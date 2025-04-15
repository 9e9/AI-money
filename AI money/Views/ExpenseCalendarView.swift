//
//  ExpenseCalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseCalendarView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var showingAddExpense = false
    @State private var selectedDate: Date = Date() // 기본값 설정
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: Expense? = nil

    // 선택된 연도와 월을 관리하는 상태 변수
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("지출 내역")
                        .font(.largeTitle)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.top, -45)
                .padding(.bottom, 20)
                
                // CalendarView 호출
                CalendarView(
                    selectedYear: $selectedYear,
                    selectedMonth: $selectedMonth,
                    showHeaders: true
                ) { date in
                    VStack {
                        Text(String(Calendar.current.component(.day, from: date)))
                            .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                            .padding(4)
                            .background(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedDate = date
                            }
                        
                        let totalExpense = viewModel.totalExpense(for: date)
                        Text(totalExpense > 0 ? "\(Int(totalExpense)) 원" : " ")
                            .font(.caption)
                            .foregroundColor(totalExpense > 0 ? .secondary : .clear)
                            .lineLimit(1)
                            .frame(height: 0.5) // Ensure consistent height
                    }
                    .padding(4)
                }
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .frame(maxHeight: 340)

                ScrollView {
                    VStack {
                        if Calendar.current.isDate(selectedDate, inSameDayAs: Date.distantPast) {
                            Text("날짜를 선택하세요.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            let dailyExpenses = viewModel.expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
                            if dailyExpenses.isEmpty {
                                Text("지출 없음")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(dailyExpenses) { expense in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(expense.category)
                                                .font(.headline)
                                            Text("\(Int(expense.amount)) 원")
                                                .font(.subheadline)
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
                                                    if let expenseToDelete = expenseToDelete {
                                                        viewModel.removeExpense(expenseToDelete)
                                                    }
                                                },
                                                secondaryButton: .cancel()
                                            )
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity)
                }
                .background(Color.gray.opacity(0.5))
                .frame(minWidth: 400, maxHeight: 350)
                .padding(.top, 30)
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
        }
    }
}
