//
//  ExpenseCalendarView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ExpenseCalendarView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @State private var showingAddExpense = false
    @State private var showingDeleteAlert = false
    @State private var showInformationView = false
    @State private var selectedDate: Date? = Date()
    @State private var expenseToDelete: Expense? = nil
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())

    var body: some View {
        NavigationView {
            VStack(spacing: 5) {
                VStack {
                    CalendarView(
                        viewModel: viewModel,
                        selectedYear: $selectedYear,
                        selectedMonth: $selectedMonth,
                        selectedDate: $selectedDate,
                        showHeaders: true
                    ) { date, isInCurrentMonth in
                        VStack {
                            Text(String(Calendar.current.component(.day, from: date)))
                                .foregroundColor(
                                    selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!) ? .white : .primary
                                )
                                .padding(4)
                                .background(
                                    selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!) ? Color.blue : Color.clear
                                )
                                .clipShape(Circle())
                                .onTapGesture {
                                    withAnimation {
                                        if let selected = selectedDate, Calendar.current.isDate(selected, inSameDayAs: date) {
                                            selectedDate = nil
                                        } else {
                                            selectedDate = date
                                        }
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
                }

                VStack {
                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedDate == nil {
                                VStack {
                                    Spacer()
                                    Text("날짜를 선택하세요")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .transition(.opacity)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, minHeight: 330)
                            } else {
                                let dailyExpenses = viewModel.expenses.filter {
                                    selectedDate != nil && Calendar.current.isDate($0.date, inSameDayAs: selectedDate!)
                                }
                                if dailyExpenses.isEmpty {
                                    VStack {
                                        Spacer()
                                        Text("지출 없음")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .padding()
                                            .transition(.opacity)
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 330)
                                } else {
                                    ForEach(dailyExpenses) { expense in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.systemGray6))
                                                .shadow(color: Color(.systemGray4).opacity(0.18), radius: 8, x: 0, y: 3)
                                            HStack {
                                                VStack(alignment: .leading, spacing: 6) {
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
                                                        .padding(8)
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
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray4))
                    )
                    .frame(minWidth: 400, maxHeight: 395)
                    .padding(.bottom, -20)
                }
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
                AddExpenseView(viewModel: viewModel, selectedDate: selectedDate ?? Date())
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
            .sheet(isPresented: $showInformationView) {
                NavigationView {
                    InformationView()
                }
            }
        }
    }
}
