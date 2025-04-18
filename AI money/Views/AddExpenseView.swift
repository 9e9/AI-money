//
//  AddExpenseView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false // 삭제 확인 팝업 상태
    @State private var deletingIndex: Int? = nil // 삭제 대상 인덱스
    @State private var showCategoryManagement = false
    @State private var allCategories: [String] = []
    @State private var isEditing = false // 수정 버튼 상태 관리
    @State private var expenseGroups: [ExpenseGroup] = [ExpenseGroup()] // 여러 지출 묶음 관리
    var selectedDate: Date

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 지출 묶음 리스트
                    ForEach(expenseGroups.indices, id: \.self) { index in
                        expenseGroupView(group: $expenseGroups[index], index: index)
                    }

                    // 새로운 지출 추가 버튼
                    Button(action: {
                        expenseGroups.append(ExpenseGroup()) // 새로운 묶음 추가
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
                        isEditing.toggle() // 수정 상태 변경
                    }) {
                        Text(isEditing ? "취소" : "수정")
                            .font(.headline)
                            .foregroundColor(isEditing ? .red : .blue)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: saveAllExpenses)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: cancelExpense)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("삭제 확인"),
                    message: Text("이 지출 묶음을 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제"), action: {
                        if let index = deletingIndex {
                            deleteExpenseGroup(at: index)
                        }
                    }),
                    secondaryButton: .cancel(Text("취소"), action: {
                        deletingIndex = nil // 삭제 인덱스 초기화
                    })
                )
            }
            .sheet(isPresented: $showCategoryManagement, onDismiss: {
                updateCategories()
            }) {
                CategoryManagementView()
            }
            .onAppear {
                updateCategories()
            }
        }
    }

    private func expenseGroupView(group: Binding<ExpenseGroup>, index: Int) -> some View {
        // 하나의 지출 묶음을 렌더링
        VStack {
            HStack {
                Text("날짜")
                Spacer()
                Text(Self.formatDate(selectedDate))
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: 25)
            Divider()

            HStack {
                Text("카테고리")
                if isEditing { // 수정 상태일 때만 '관리' 버튼 표시
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
            .frame(maxHeight: 25)
            Divider()

            HStack {
                Text("금액")
                Spacer()
                HStack {
                    TextField("금액 입력(필수)", text: group.amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: group.amount.wrappedValue, perform: { newValue in
                            group.wrappedValue.formattedAmount = Self.formatWithComma(newValue)
                        })
                        .multilineTextAlignment(.trailing)
                    if !group.wrappedValue.formattedAmount.isEmpty {
                        Text("원").foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: 200)
            }
            .frame(maxHeight: 25)
            Divider()

            HStack {
                Text("메모")
                Spacer()
                TextField("선택 사항", text: group.note)
                    .multilineTextAlignment(.trailing)
            }
            .frame(maxHeight: 25)
            Divider()

            // 삭제 버튼 (수정 모드일 때만 표시 + 최소 2개 이상의 묶음일 때만 표시)
            if isEditing && expenseGroups.count > 1 {
                Button(action: {
                    deletingIndex = index // 삭제 대상 설정
                    showingAlert = true // Alert 표시
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .center) // 가운데 정렬
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func deleteExpenseGroup(at index: Int) {
        // 삭제 처리
        guard index >= 0 && index < expenseGroups.count else { return } // 유효성 확인
        expenseGroups.remove(at: index) // 배열에서 항목 제거
        deletingIndex = nil // 삭제 인덱스 초기화
    }

    private func saveAllExpenses() {
        // 모든 묶음 검증 및 저장
        for group in expenseGroups {
            guard let expenseAmount = Double(group.amount), expenseAmount > 0 else {
                showingAlert = true
                return
            }
        }

        // 유효한 경우 저장
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

    private func cancelExpense() {
        presentationMode.wrappedValue.dismiss()
    }

    private func updateCategories() {
        let predefinedCategories = ["식비", "교통", "쇼핑", "여가", "기타"]
        let customCategories = UserDefaults.standard.customCategories
        allCategories = predefinedCategories + customCategories
    }

    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private static func formatWithComma(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        return numberFormatter.string(from: NSNumber(value: number)) ?? numberString
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        return formatter
    }()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

struct ExpenseGroup {
    var category: String = "기타"
    var amount: String = ""
    var formattedAmount: String = ""
    var note: String = ""
}
