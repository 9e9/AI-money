//
//  AddExpenseView.swift
//  AI money
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var deletingIndex: Int? = nil
    @State private var showCategoryManagement = false
    @State private var allCategories: [String] = []
    @State private var isEditing = false
    @State private var expenseGroups: [ExpenseGroup] = [ExpenseGroup()]
    var selectedDate: Date

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(expenseGroups.indices, id: \.self) { index in
                        expenseGroupView(group: $expenseGroups[index], index: index)
                    }

                    Button(action: {
                        expenseGroups.append(ExpenseGroup())
                    }) {
                        Text("새로운 지출 추가")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "닫기" : "수정")
                            .font(.headline)
                            .foregroundColor(isEditing ? .red : .blue)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: validateAndSaveExpenses)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: cancelExpense)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                if deletingIndex != nil {
                    Button("삭제", role: .destructive, action: confirmDelete)
                    Button("취소", role: .cancel) { deletingIndex = nil }
                } else {
                    Button("확인", role: .cancel) { }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showCategoryManagement, onDismiss: updateCategories) {
                CategoryManagementView()
            }
            .onAppear {
                updateCategories()
            }
        }
    }

    private func expenseGroupView(group: Binding<ExpenseGroup>, index: Int) -> some View {
        VStack {
            HStack {
                Text("날짜")
                Spacer()
                Text(Self.formatDate(selectedDate))
                    .foregroundColor(.secondary)
            }
            Divider()

            HStack {
                Text("카테고리")
                if isEditing {
                    Button(action: {
                        showCategoryManagement = true
                    }) {
                        Text("관리")
                            .foregroundColor(.blue)
                            .bold()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                Spacer()
                Picker("", selection: group.category) {
                    ForEach(allCategories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            Divider()

            HStack {
                Text("금액")
                Spacer()
                HStack {
                    TextField("금액 입력(필수)", text: group.formattedAmount)
                        .keyboardType(.numberPad)
                        .onChange(of: group.formattedAmount.wrappedValue, perform: { newValue in
                            let filteredValue = newValue.replacingOccurrences(of: ",", with: "")
                            if let number = Int(filteredValue) {
                                group.wrappedValue.formattedAmount = Self.formatWithComma(String(number))
                                group.wrappedValue.amount = String(number)
                            } else {
                                group.wrappedValue.formattedAmount = ""
                                group.wrappedValue.amount = ""
                            }
                        })
                        .multilineTextAlignment(.trailing)
                    if !group.wrappedValue.formattedAmount.isEmpty {
                        Text("원").foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: 200)
            }
            Divider()

            HStack {
                Text("메모")
                Spacer()
                TextField("선택 사항", text: group.note)
                    .multilineTextAlignment(.trailing)
            }
            Divider()

            if isEditing && expenseGroups.count > 1 {
                Button(action: {
                    deletingIndex = index
                    alertTitle = "삭제 확인"
                    alertMessage = "이 지출 묶음을 삭제하시겠습니까?"
                    showingAlert = true
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func validateAndSaveExpenses() {
        for group in expenseGroups {
            guard let expenseAmount = Double(group.amount), expenseAmount > 0 else {
                alertTitle = "금액을 입력하세요"
                alertMessage = "지출 금액을 입력해야 저장할 수 있습니다."
                showingAlert = true
                return
            }
        }

        for group in expenseGroups {
            let newExpense = Expense(
                date: selectedDate,
                category: group.category,
                amount: Double(group.amount) ?? 0,
                note: group.note
            )
            viewModel.addExpense(newExpense)
        }

        presentationMode.wrappedValue.dismiss()
    }

    private func confirmDelete() {
        if let index = deletingIndex {
            expenseGroups.remove(at: index)
        }
        deletingIndex = nil
    }

    private func cancelExpense() {
        presentationMode.wrappedValue.dismiss()
    }

    private func updateCategories() {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        let customCategories = UserDefaults.standard.customCategories
        allCategories = predefinedCategories + customCategories
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        return formatter.string(from: date)
    }

    private static func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? numberString
    }
}

struct ExpenseGroup {
    var category: String = "기타"
    var amount: String = ""
    var formattedAmount: String = ""
    var note: String = ""
}
