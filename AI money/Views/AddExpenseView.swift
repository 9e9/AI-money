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
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.4),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
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
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 24)
                }
                
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            vm.addGroup()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("새로운 지출 추가")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.25), radius: 12, x: 0, y: 6)
                        .shadow(color: Color.blue.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("지출 추가")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소", action: cancelExpense)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                            isEditing.toggle() 
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isEditing ? "xmark.circle.fill" : "pencil.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(isEditing ? "닫기" : "수정")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(isEditing ? .red : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill((isEditing ? Color.red : Color.blue).opacity(0.1))
                        )
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("저장", action: validateAndSaveExpenses)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
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
