//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @StateObject private var vm = AddExpenseViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var deletingIndex: Int? = nil
    @State private var showCategoryManagement = false
    @State private var isEditing = false
    var selectedDate: Date

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(vm.expenseGroups.indices, id: \.self) { index in
                        expenseGroupView(group: $vm.expenseGroups[index], index: index)
                            .transition(.opacity)
                    }

                    Button(action: {
                        withAnimation {
                            vm.addGroup()
                        }
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
                        withAnimation {
                            isEditing.toggle()
                        }
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
            .sheet(isPresented: $showCategoryManagement, onDismiss: vm.updateCategories) {
                CategoryManagementView()
            }
            .onAppear {
                vm.updateCategories()
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
            .frame(maxHeight: 23)
            Divider()

            HStack {
                Text("카테고리")
                if isEditing {
                    withAnimation {
                        Button(action: {
                            showCategoryManagement = true
                        }) {
                            Text("관리")
                                .foregroundColor(.blue)
                                .bold()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .transition(.opacity)
                    }
                }
                Spacer()
                Picker("", selection: group.category) {
                    ForEach(vm.allCategories, id: \.self) { category in
                        Text(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .frame(maxHeight: 23)
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
            }
            .frame(maxHeight: 35)
            Divider()

            HStack {
                Text("메모")
                Spacer()
                TextField("선택 사항", text: group.note)
                    .multilineTextAlignment(.trailing)
            }
            .frame(maxHeight: 20)
            
            if isEditing && vm.expenseGroups.count > 1 {
                Button(action: {
                    deletingIndex = index
                    alertTitle = "삭제 확인"
                    alertMessage = "이 지출 묶음을 삭제하시겠습니까?"
                    showingAlert = true
                }) {
                    VStack {
                        Divider()
                        Image(systemName: "trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                    .frame(maxHeight: 23)
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
        let (isValid, errorMsg) = vm.validate()
        if !isValid {
            alertTitle = "금액을 입력하세요"
            alertMessage = errorMsg ?? ""
            showingAlert = true
            return
        }

        let newExpenses = vm.makeExpenses(selectedDate: selectedDate)
        for expense in newExpenses {
            viewModel.addExpense(expense)
        }

        presentationMode.wrappedValue.dismiss()
    }

    private func confirmDelete() {
        withAnimation {
            if let index = deletingIndex {
                vm.removeGroup(at: index)
            }
            deletingIndex = nil
        }
    }

    private func cancelExpense() {
        presentationMode.wrappedValue.dismiss()
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
