//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
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
            ZStack {
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(vm.expenseGroups.indices, id: \.self) { index in
                            AddExpenseCardView(
                                group: $vm.expenseGroups[index],
                                index: index,
                                selectedDate: selectedDate,
                                isEditing: isEditing,
                                allCategories: vm.allCategories,
                                expenseGroupCount: vm.expenseGroups.count,
                                onDelete: { idx in
                                    deletingIndex = idx
                                    alertTitle = "삭제 확인"
                                    alertMessage = "이 지출 묶음을 삭제하시겠습니까?"
                                    showingAlert = true
                                },
                                onShowCategoryManagement: { showCategoryManagement = true }
                            )
                            .transition(.opacity)
                        }
                        Spacer().frame(height: 70)
                    }
                    .padding(.top, 20)
                }
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            vm.addGroup()
                        }
                    }) {
                        Label("새로운 지출 추가", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(14)
                            .shadow(color: Color.blue.opacity(0.18), radius: 8, x: 0, y: 3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("지출 추가")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소", action: cancelExpense)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation { isEditing.toggle() }
                    }) {
                        Text(isEditing ? "닫기" : "수정")
                            .font(.headline)
                            .foregroundColor(isEditing ? .red : .blue)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("저장", action: validateAndSaveExpenses)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
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
            .onAppear { vm.updateCategories() }
        }
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
}

extension AddExpenseView {
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }

    static func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? numberString
    }
}
