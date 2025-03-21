//
//  ContentView.swift
//  AI money
//
//  Created by 조준희 on 3/21/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import Vision

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State var expenseViewModel = ExpenseViewModel()
    @State private var isPresentingAddExpenseView = false
    @State private var isShowingPhotoPicker = false
    @State private var isPresentingPhotoPicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var recognizedText: String = ""
    
    

    var body: some View {
        NavigationView {
            VStack {
                Text("AI 가계부")
                    .font(.largeTitle)
                    .padding()

                NavigationLink(destination: ExpenseListView()) {
                    Text("지출 내역 보기")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)

                NavigationLink(destination: ChartView()) {
                    Text("차트 보기")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)

                Button {
                    isShowingPhotoPicker = true
                } label: {
                    Text("영수증 스캔")
                        .font(.title3)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)
                .photosPicker(isPresented: $isPresentingPhotoPicker, selection: $selectedPhoto) {
                    Text("영수증 스캔")
                        .font(.title3)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .onChange(of: selectedImage) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            performOCR(onImage: uiImage)
                        }
                    }
                }

                if !recognizedText.isEmpty {
                    Text("인식된 텍스트: \(recognizedText)")
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Al Money")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingAddExpenseView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddExpenseView) {
                AddExpenseView()
            }
            .environment(\.modelContext, modelContext)
        }
    }

    func performOCR(onImage image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                print("텍스트 인식 오류: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }

            var fullText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                fullText += topCandidate.string + "\n"
            }

            DispatchQueue.main.async {
                recognizedText = fullText
                extractExpenseInfo(fromText: fullText) // 텍스트에서 정보 추출
            }
        }

        do {
            try requestHandler.perform([request])
        } catch {
            print("OCR 요청 실패: \(error.localizedDescription)")
        }
    }

    func extractExpenseInfo(fromText text: String) {
        // 간단한 금액 추출: 숫자와 소수점, 그리고 "원" 또는 "$" 기호 찾기
        let amountRegex = try? NSRegularExpression(pattern: "([0-9,.]+)[원$]") // 수정된 정규 표현식
        if let match = amountRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let amountRange = Range(match.range(at: 1), in: text) {
                let amountString = text[amountRange].replacingOccurrences(of: ",", with: "") // 쉼표 제거
                if let amount = Double(amountString) {
                    let newExpense = Expense(date: Date(), amount: amount, memo: text, category: nil) // 임시로 카테고리 nil 설정, description 대신 memo
                    modelContext.insert(newExpense)
                    print("새로운 지출 기록됨: 금액 - \(amount), 내용 - \(text)")
                    return
                }
            }
        }

        // 금액을 찾지 못한 경우, 전체 텍스트를 내용으로만 저장 (금액은 0으로 설정하거나 사용자에게 입력 요청)
        let newExpense = Expense(date: Date(), amount: 0.0, memo: text, category: nil) // 금액 0으로 임시 설정, description 대신 memo
        modelContext.insert(newExpense)
        print("지출 기록됨 (금액 인식 실패): 내용 - \(text)")
    }
}
