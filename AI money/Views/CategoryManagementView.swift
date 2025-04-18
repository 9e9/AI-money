//
//  CategoryManagementView.swift
//  AI money
//
//  Created by 조준희 on 4/18/25.
//

import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var customCategories = UserDefaults.standard.customCategories
    @State private var newCategoryName = ""
    @State private var showingAlert = false
    @State private var categoryToDelete: String? // 삭제할 카테고리 이름 저장

    var body: some View {
        NavigationView {
            VStack {
                if customCategories.isEmpty {
                    // 카테고리가 없을 때 메시지를 화면 중앙에 배치
                    Spacer()
                    Text("카테고리가 없음")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(customCategories, id: \.self) { category in
                            HStack {
                                Text(category)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    categoryToDelete = category // 삭제할 카테고리 저장
                                    showingAlert = true // 확인 알림 표시
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle()) // 클릭 영역 최소화
                            }
                            .padding(.vertical, 8) // 셀 간격 설정
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer() // 위쪽 공간 밀어내기

                // 새 카테고리 입력 필드와 추가 버튼
                HStack {
                    TextField("새 카테고리", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 8)
                    Button(action: addCategory) {
                        Text("추가")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("카테고리 관리")
            .navigationBarItems(trailing: Button("완료") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("삭제 확인"),
                    message: Text("정말로 '\(categoryToDelete ?? "")'를 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        if let category = categoryToDelete {
                            deleteCategory(named: category)
                        }
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            }
        }
    }

    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !customCategories.contains(trimmedName) else {
            // 중복된 이름일 경우 처리 로직 (Alert 등)
            return
        }
        customCategories.append(trimmedName)
        UserDefaults.standard.customCategories = customCategories
        newCategoryName = ""
    }

    private func deleteCategory(named category: String) {
        if let index = customCategories.firstIndex(of: category) {
            customCategories.remove(at: index)
            UserDefaults.standard.customCategories = customCategories
        }
    }
}
