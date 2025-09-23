//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI
import Combine

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @StateObject private var vm = AddExpenseViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var deletingIndex: Int? = nil
    @State private var showCategoryManagement = false
    @State private var isEditing = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var focusedCardIndex: Int? = nil
    
    var selectedDate: Date

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                headerSection
                                    .padding(.top, 20)
                                
                                if vm.totalAmount > 0 {
                                    summaryCard
                                }
                                
                                ForEach(vm.expenseGroups.indices, id: \.self) { index in
                                    AddExpenseCardView(
                                        group: $vm.expenseGroups[index],
                                        index: index,
                                        selectedDate: selectedDate,
                                        isEditing: isEditing,
                                        allCategories: vm.allCategories,
                                        expenseGroupCount: vm.expenseGroups.count,
                                        isFocused: focusedCardIndex == index,
                                        onDelete: { idx in handleDelete(at: idx) },
                                        onDuplicate: { idx in vm.duplicateGroup(at: idx) },
                                        onFocus: { idx in
                                            focusedCardIndex = idx
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                scrollProxy.scrollTo(idx, anchor: .center)
                                            }
                                        },
                                        onApplyQuickAmount: { amount, idx in
                                            vm.applyQuickAmount(amount, to: idx)
                                        },
                                        onShowCategoryManagement: { showCategoryManagement = true },
                                        onAmountChange: { newValue, idx in
                                            vm.updateAmountFormatting(at: idx, newValue: newValue)
                                        }
                                    )
                                    .id(index)
                                    .padding(.horizontal, 20)
                                }
                                
                                Spacer().frame(height: 100)
                            }
                        }
                        .scrollDismissesKeyboard(.immediately)
                    }
                    
                    simpleFloatingBar
                        .offset(y: -max(0, keyboardHeight - geometry.safeAreaInsets.bottom))
                }
            }
            .navigationTitle("지출 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(vm.alertTitle, isPresented: $vm.showingAlert) {
                alertButtons
            } message: {
                Text(vm.alertMessage)
            }
            .sheet(isPresented: $showCategoryManagement, onDismiss: vm.updateCategories) {
                CategoryManagementView()
            }
            .overlay(saveOverlay)
            .onReceive(keyboardPublisher) { height in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = height
                }
            }
            .onAppear {
                vm.updateCategories()
                focusedCardIndex = 0
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("지출 추가")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(vm.formatSelectedDate(selectedDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if vm.hasUnsavedChanges {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    
                    Text("저장되지 않음")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var summaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("총 지출")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(vm.formatAmount(vm.totalAmount))원")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("\(vm.validExpenseCount)개")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .transition(.opacity)
    }
    
    private var simpleFloatingBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        vm.addGroup()
                        focusedCardIndex = vm.expenseGroups.count - 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                }
                
                Spacer()
                
                Button(action: handleSave) {
                    HStack(spacing: 8) {
                        if vm.showingSaveAnimation {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("저장")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(vm.hasValidExpenses ? Color.black : Color(.systemGray4))
                    )
                }
                .disabled(!vm.hasValidExpenses || vm.showingSaveAnimation)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var saveOverlay: some View {
        Group {
            if vm.showingSaveAnimation {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text("저장 완료")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThickMaterial)
                    )
                }
                .transition(.opacity)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("취소") {
                handleCancel()
            }
            .font(.system(size: 16, weight: .medium))
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(isEditing ? "완료" : "편집") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditing.toggle()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isEditing ? .orange : .black)
        }
    }
    
    @ViewBuilder
    private var alertButtons: some View {
        if deletingIndex != nil {
            Button("삭제", role: .destructive) {
                confirmDelete()
            }
            Button("취소", role: .cancel) {
                deletingIndex = nil
            }
        } else if vm.alertTitle == "나가기" {
            Button("나가기", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
            Button("계속 편집", role: .cancel) { }
        } else {
            Button("확인", role: .cancel) { }
        }
    }
    
    private func handleCancel() {
        if vm.shouldShowExitAlert() {
            vm.prepareExitAlert()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func handleSave() {
        vm.validateAndPrepareForSave(selectedDate: selectedDate) { expenses, error in
            if let expenses = expenses {
                for expense in expenses {
                    viewModel.addExpense(expense)
                }
                vm.completeSaveAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func handleDelete(at index: Int) {
        deletingIndex = index
        vm.alertTitle = "삭제"
        vm.alertMessage = "지출 \(index + 1)번을 삭제하시겠습니까?"
        vm.showingAlert = true
    }
    
    private func confirmDelete() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if let index = deletingIndex {
                vm.removeGroup(at: index)
            }
            deletingIndex = nil
        }
    }
    
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
}

extension AddExpenseView {
    static func formatDate(_ date: Date) -> String {
        return FormatHelper.formatSelectedDate(date)
    }

    static func formatWithComma(_ numberString: String) -> String {
        return FormatHelper.formatWithComma(numberString)
    }
}
