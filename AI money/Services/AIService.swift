//
//  AIService.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import Foundation // 날짜, 문자열 등 기본 데이터 타입 사용
import CoreML // AI 머신러닝 모델 사용을 위한 프레임워크
import SwiftData // 데이터베이스 접근을 위한 프레임워크

// MARK: - AI 서비스의 대화 컨텍스트 구조체
struct ConversationContext {
    var period: Period? // 사용자가 언급한 기간 (이번달, 지난주 등) - 대화 맥락 유지용
    var category: String? // 사용자가 언급한 카테고리 (식비, 교통비 등) - 대화 맥락 유지용
    var questionType: QuestionType? // AI가 파악한 질문 유형 - 대화 맥락 유지용
}

// MARK: - AI가 파싱한 사용자 쿼리 정보
struct ParsedQuery {
    var period: Period? // 파싱된 기간 정보 - ML 모델과 키워드 파싱 결과
    var category: String? // 파싱된 카테고리 정보 - ML 모델과 키워드 파싱 결과
    var questionType: QuestionType? // ML 모델이 분류한 질문 유형 - ExpenseClassifier.mlmodel 결과
    var referenceDate: Date? // 참조 날짜 (특정 날짜 언급 시) - "5월 15일" 같은 구체적 날짜
    var isCompare: Bool // 비교 질문인지 여부 (지난달과 비교 등) - "더 썼어?" 같은 비교 질문 감지
}

// MARK: - 기간 관련 열거형
enum Period {
    case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth, thisYear, lastYear // 미리 정의된 기간들
    case custom(Date, Date) // 사용자 정의 기간 - 시작일과 종료일 지정
    case specificDay(Date) // 특정 날짜 - "5월 15일" 같은 구체적 날짜
    case recentNDays(Int) // 최근 N일 - "최근 7일" 같은 상대적 기간
}

// MARK: - AI가 분류할 수 있는 질문 유형들
enum QuestionType: String, CaseIterable, Equatable {
    case totalAmount = "total_expense" // 총 지출 금액 질문 - "이번 달 얼마 썼어?"
    case byCategory = "category_expense" // 카테고리별 지출 질문 - "식비 얼마 썼어?"
    case count = "count" // 지출 횟수 질문 - "몇 번 지출했어?"
    case summary = "summary" // 지출 요약 질문 - "지출 내역 요약해줘"
    case topCategory = "top_category" // 최대 지출 카테고리 질문 - "가장 많이 쓴 카테고리는?"
    case minCategory = "min_category" // 최소 지출 카테고리 질문 - "가장 적게 쓴 항목은?"
    case topDay = "top_day" // 최대 지출 날짜 질문 - "가장 많이 쓴 날은?"
    case minDay = "min_day" // 최소 지출 날짜 질문 - "가장 적게 쓴 날은?"
    case remainedBudget = "left_budget" // 남은 예산 질문 - "남은 예산 얼마야?"
    case overspent = "overspent" // 예산 초과 질문 - "예산 초과했어?"
    case trend = "trend" // 소비 트렌드 질문 - "소비 추세 알려줘"
    case paymentType = "payment_type" // 결제 방식별 질문 - "카드로 얼마 썼어?"
    case avgExpense = "avg_expense" // 평균 지출 질문 - "평균 지출 얼마야?"
    case compare = "compare" // 비교 분석 질문 - "지난달보다 더 썼어?"
    case dateExpense = "date_expense" // 특정 날짜 지출 질문 - "어제 얼마 썼어?"
    case none = "none" // 분류할 수 없는 질문 - AI가 이해하지 못한 질문
    
    // ML 모델의 라벨을 QuestionType으로 변환하는 메서드
    static func fromMLLabel(_ label: String) -> QuestionType {
        return QuestionType(rawValue: label) ?? .none // 라벨이 없으면 .none 반환
    }
}

// MARK: - AI 서비스 메인 클래스
final class AIService {
    static let shared = AIService() // 싱글톤 패턴으로 전역에서 하나의 인스턴스만 사용
    private let classifier: ExpenseClassifier? // CoreML 모델 인스턴스 - ExpenseClassifier.mlmodel 파일
    
    // MARK: - AI 인식을 위한 키워드 집합들
    // 앱과 관련된 키워드들 (AI가 지출 관련 질문인지 판단하는 기준)
    private static let appKeywords: Set<String> = [
        "지출", "카테고리", "얼마", "가장", "쇼핑", "교통", "카드", "현금", "예산", // 기본 지출 관련 키워드
        "합계", "최대", "최소", "요약", "내역", "많이", "적게", "건수", "횟수", // 통계/분석 관련 키워드
        "추세", "통계", "식비", "외식", "카페", "월세", "통신비", "문화생활" // 카테고리 및 분석 관련 키워드
    ]
    
    // 의미 없는 응답들 (AI가 거부해야 할 입력들)
    private static let meaningless: Set<String> = [
        "?", "네", "그래", "응", "ㅇㅋ", "좋아", "오키", "ok", "okay", "ㅎㅎ", "ㅋㅋ" // 단순 감탄사나 의미없는 입력들
    ]

    // MARK: - 날짜 및 숫자 포맷터들
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter() // 날짜 포맷터 생성
        formatter.dateFormat = "yyyy-MM-dd(E)" // 요일 포함 날짜 형식 (예: 2025-01-15(수))
        return formatter
    }()
    
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter() // 월 포맷터 생성
        formatter.dateFormat = "yyyy년 M월" // 한국어 월 형식 (예: 2025년 1월)
        return formatter
    }()
    
    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter() // 금액 포맷터 생성
        formatter.numberStyle = .decimal // 천 단위 콤마 표시 (예: 1,000,000)
        return formatter
    }()
    
    // MARK: - 정규식 패턴들 (날짜 파싱용)
    // "5월 15일" 형태의 날짜를 찾는 정규식
    private static let specificDateRegex = try! NSRegularExpression(pattern: #"(\d{1,2})월(\d{1,2})일"#)
    // "5월" 형태의 월만 찾는 정규식
    private static let monthRegex = try! NSRegularExpression(pattern: #"(\d{1,2})월"#)

    // MARK: - 초기화
    private init() {
        // CoreML 모델 로드 시도
        do {
            let config = MLModelConfiguration() // ML 모델 설정 생성
            config.computeUnits = .all // CPU, GPU, Neural Engine 모두 사용하여 성능 최적화
            self.classifier = try ExpenseClassifier(configuration: config) // ExpenseClassifier.mlmodel 로드
            print("✅ AI 모델 로드 성공") // 성공 로그 출력
        } catch {
            print("❌ AI 모델 로드 실패: \(error.localizedDescription)") // 실패 시 에러 메시지 출력
            self.classifier = nil // 모델 로드 실패 시 nil로 설정
        }
    }

    // MARK: - 메인 AI 응답 메서드
    /// 사용자 입력에 대한 AI 응답을 생성하는 메인 메서드
    /// - Parameters:
    ///   - userInput: 사용자가 입력한 텍스트 (예: "이번 달 식비 얼마 썼어?")
    ///   - modelContainer: SwiftData 컨테이너 (데이터베이스 접근용)
    ///   - conversationContext: 이전 대화의 맥락 정보 (연속된 대화 처리용)
    /// - Returns: (AI응답, 업데이트된 컨텍스트) 튜플
    func reply(
        to userInput: String,
        modelContainer: ModelContainer,
        conversationContext: ConversationContext
    ) async -> (String, ConversationContext) {
        var tempContext = conversationContext // 컨텍스트 복사본 생성 (원본 보존)
        
        // 1단계: 앱 관련 질문인지 검증
        if !isRelatedToApp(userInput) {
            return ("앱 사용과 관련된 지출/소비/예산 질문을 해주세요! 🏦", tempContext) // 관련없는 질문 거부
        }
        
        // 2단계: 의미 있는 질문인지 검증
        if isNotAValidQuestion(userInput) {
            return ("더 구체적인 지출 관련 질문을 해주세요! 💰", tempContext) // 무의미한 입력 거부
        }

        // 3단계: 데이터 액터 생성 (비동기 데이터 접근용)
        let dataActor = DataActor(modelContainer: modelContainer) // 데이터베이스 비동기 접근을 위한 액터
        
        // 4단계: ML 모델 + 키워드 파싱으로 사용자 입력 분석
        let parsed = await parseUserInput(
            userInput: userInput,
            dataActor: dataActor,
            previousContext: tempContext
        ) // AI 모델과 키워드 분석을 통한 입력 해석

        // 5단계: 파싱 결과 검증 (nil 체크를 명시적으로 처리)
        let hasValidResult = (parsed.questionType != nil && parsed.questionType != QuestionType.none) ||
                           parsed.category != nil ||
                           parsed.period != nil // 유효한 파싱 결과가 있는지 확인
        
        if !hasValidResult {
            return ("죄송해요, 질문을 이해하지 못했어요. 다시 물어봐 주세요! 🤔", tempContext) // 파싱 실패 시 에러 메시지
        }

        // 6단계: 컨텍스트 업데이트 (이전 대화 맥락 유지)
        if let period = parsed.period { tempContext.period = period } // 파싱된 기간이 있으면 컨텍스트 업데이트
        if let category = parsed.category { tempContext.category = category } // 파싱된 카테고리가 있으면 컨텍스트 업데이트
        if let questionType = parsed.questionType, questionType != QuestionType.none {
            tempContext.questionType = questionType // 파싱된 질문 유형이 있으면 컨텍스트 업데이트
        }

        // 7단계: 실제 답변 생성
        let answerText = await generateAnswer(
            for: parsed,
            dataActor: dataActor,
            conversationContext: tempContext
        ) // 파싱된 정보를 바탕으로 실제 답변 생성
        
        return (answerText, tempContext) // 답변과 업데이트된 컨텍스트 반환
    }

    // MARK: - 앱 관련성 검증
    /// 사용자 입력이 지출 관리 앱과 관련된 질문인지 확인
    /// - Parameter input: 사용자 입력 텍스트
    /// - Returns: 앱 관련 질문이면 true, 아니면 false
    private func isRelatedToApp(_ input: String) -> Bool {
        let normalizedInput = input.lowercased().replacingOccurrences(of: " ", with: "") // 소문자 변환 및 공백 제거
        
        // 앱 관련 키워드가 하나라도 포함되어 있으면 관련 질문으로 판단
        return AIService.appKeywords.contains { keyword in
            normalizedInput.contains(keyword) // 키워드 포함 여부 확인
        }
    }

    // MARK: - 유효한 질문 검증
    /// 의미 없는 응답인지 확인 (단순 감탄사, 짧은 답변 등)
    /// - Parameter input: 사용자 입력 텍스트
    /// - Returns: 무의미한 입력이면 true, 유효한 질문이면 false
    private func isNotAValidQuestion(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() // 양 끝 공백 제거 및 소문자 변환
        return AIService.meaningless.contains(trimmed) || trimmed.count < 2 // 무의미한 단어이거나 너무 짧은 입력 체크
    }

    // MARK: - 사용자 입력 파싱 (ML + 키워드 조합)
    /// CoreML 모델과 키워드 파싱을 조합하여 사용자 입력을 분석
    /// - Parameters:
    ///   - userInput: 사용자 입력 텍스트
    ///   - dataActor: 데이터 접근을 위한 액터
    ///   - previousContext: 이전 대화 컨텍스트
    /// - Returns: 파싱된 쿼리 정보
    private func parseUserInput(
        userInput: String,
        dataActor: DataActor,
        previousContext: ConversationContext
    ) async -> ParsedQuery {
        
        // 1단계: ML 모델로 질문 유형 분류
        let mlQuestionType = classifyQuestionWithML(userInput) // ExpenseClassifier.mlmodel로 질문 분류
        print("🤖 ML 모델 분류 결과: \(mlQuestionType.rawValue)") // 분류 결과 로그 출력
        
        // 2단계: 키워드 파싱으로 기간, 카테고리 추출
        let keywordParsed = await parseWithKeywords(userInput, dataActor: dataActor) // 키워드 기반 파싱
        
        // 3단계: ML 결과와 키워드 결과 조합
        var finalQuestionType = mlQuestionType // ML 결과를 기본값으로 설정
        
        // ML 모델이 확실하지 않은 경우 키워드 파싱 결과 활용
        if mlQuestionType == QuestionType.none {
            finalQuestionType = keywordParsed.questionType ?? QuestionType.none // 키워드 파싱 결과로 대체
        }
        
        // 4단계: 이전 컨텍스트와 결합
        let period = keywordParsed.period ?? previousContext.period // 새로 파싱된 기간 또는 이전 컨텍스트의 기간 사용
        let category = keywordParsed.category ?? previousContext.category // 새로 파싱된 카테고리 또는 이전 컨텍스트의 카테고리 사용
        let questionType = finalQuestionType != QuestionType.none ? finalQuestionType :
                          (previousContext.questionType ?? QuestionType.totalAmount) // 질문 유형 결정 (기본값: 총 지출)
        
        return ParsedQuery(
            period: period,
            category: category,
            questionType: questionType,
            referenceDate: keywordParsed.referenceDate,
            isCompare: keywordParsed.isCompare
        ) // 파싱된 결과 반환
    }
    
    // MARK: - CoreML 모델을 사용한 질문 분류
    /// ExpenseClassifier 모델을 사용하여 질문 유형을 분류
    /// - Parameter input: 사용자 입력 텍스트
    /// - Returns: 분류된 질문 유형
    private func classifyQuestionWithML(_ input: String) -> QuestionType {
        guard let classifier = classifier else {
            print("⚠️ ML 모델이 로드되지 않음, 키워드 파싱으로 대체") // 모델 없을 때 경고 메시지
            return QuestionType.none // 모델이 없으면 none 반환
        }
        
        do {
            // ML 모델 예측 실행
            let prediction = try classifier.prediction(text: input) // ExpenseClassifier로 텍스트 분류
            let predictedType = QuestionType.fromMLLabel(prediction.label) // 라벨을 QuestionType으로 변환
            
            // 예측 신뢰도 확인을 위한 로그 (prediction에서 신뢰도 정보 추출)
            print("🎯 ML 예측: \(prediction.label)") // 예측 결과 로그 출력
            
            return predictedType // 예측된 질문 유형 반환
            
        } catch {
            print("❌ ML 모델 예측 실패: \(error.localizedDescription)") // 예측 실패 시 에러 로그
            return QuestionType.none // 예측 실패 시 none 반환
        }
    }
    
    // MARK: - 키워드 기반 파싱 (ML 보완용)
    /// 키워드와 정규식을 사용한 전통적인 파싱 방법
    /// - Parameters:
    ///   - userInput: 사용자 입력
    ///   - dataActor: 데이터 액터
    /// - Returns: 파싱된 결과
    private func parseWithKeywords(_ userInput: String, dataActor: DataActor) async -> ParsedQuery {
        let normalizedInput = userInput.replacingOccurrences(of: " ", with: "").lowercased() // 공백 제거 및 소문자 변환
        let now = Date() // 현재 날짜
        let calendar = Calendar.current // 달력 인스턴스

        var period: Period? = nil // 파싱된 기간
        var category: String? = nil // 파싱된 카테고리
        var questionType: QuestionType? = nil // 파싱된 질문 유형
        var referenceDate: Date? = nil // 참조 날짜
        var isCompare = false // 비교 질문 여부

        // 기간 파싱
        if let date = Self.parseSpecificDate(text: normalizedInput) {
            period = .specificDay(date) // "5월 15일" 형태의 특정 날짜
            referenceDate = date // 참조 날짜 설정
        } else if normalizedInput.contains("오늘") {
            period = .today // "오늘" 키워드
        } else if normalizedInput.contains("어제") || normalizedInput.contains("어재") {
            period = .yesterday // "어제" 키워드 (오타 포함)
        } else if normalizedInput.contains("이번주") {
            period = .thisWeek // "이번 주" 키워드
        } else if normalizedInput.contains("지난주") {
            period = .lastWeek // "지난주" 키워드
        } else if normalizedInput.contains("이번달") || normalizedInput.contains("이번월") ||
                  normalizedInput.contains("이달") || normalizedInput.contains("금월") {
            period = .thisMonth // "이번 달" 관련 키워드들
        } else if normalizedInput.contains("지난달") || normalizedInput.contains("저번달") ||
                  normalizedInput.contains("전월") || normalizedInput.contains("이전달") {
            period = .lastMonth // "지난달" 관련 키워드들
        } else if let customMonth = Self.parseMonth(text: normalizedInput) {
            let start = customMonth // 월의 시작일
            let end = calendar.date(byAdding: .month, value: 1, to: start)! // 월의 종료일
            period = .custom(start, end) // 사용자 정의 월 기간
        } else if normalizedInput.contains("최근일주일") || normalizedInput.contains("최근7일") {
            period = .recentNDays(7) // 최근 7일 키워드
        }

        // 비교 질문 감지
        if normalizedInput.contains("더썼") || normalizedInput.contains("늘었") ||
           normalizedInput.contains("증가") || normalizedInput.contains("비교") ||
           normalizedInput.contains("초과") || normalizedInput.contains("아껴졌") ||
           normalizedInput.contains("줄었") {
            isCompare = true // 비교 관련 키워드 감지
        }

        // 카테고리 추출 (비동기 처리)
        let categories = await extractAllCategories(dataActor: dataActor) // 데이터베이스에서 모든 카테고리 가져오기
        category = categories.first { categoryName in
            normalizedInput.contains(categoryName.replacingOccurrences(of: " ", with: "").lowercased()) // 카테고리 이름 매칭
        }

        // 질문 유형 파싱 (키워드 기반)
        if normalizedInput.contains("가장많이") || normalizedInput.contains("제일많이") ||
           normalizedInput.contains("최대") {
            questionType = normalizedInput.contains("날") || normalizedInput.contains("요일") ?
                          QuestionType.topDay : QuestionType.topCategory // 최대 지출 날짜 또는 카테고리
        } else if normalizedInput.contains("가장적게") || normalizedInput.contains("제일작은") ||
                  normalizedInput.contains("최소") {
            questionType = normalizedInput.contains("날") || normalizedInput.contains("요일") ?
                          QuestionType.minDay : QuestionType.minCategory // 최소 지출 날짜 또는 카테고리
        } else if normalizedInput.contains("횟수") || normalizedInput.contains("몇번") ||
                  normalizedInput.contains("건수") || normalizedInput.contains("몇건") {
            questionType = QuestionType.count // 지출 횟수 관련 질문
        } else if normalizedInput.contains("요약") || normalizedInput.contains("내역") {
            questionType = QuestionType.summary // 지출 요약 관련 질문
        } else if normalizedInput.contains("남은예산") || normalizedInput.contains("남은돈") ||
                  normalizedInput.contains("얼마남았") {
            questionType = QuestionType.remainedBudget // 남은 예산 관련 질문
        } else if normalizedInput.contains("총지출") || normalizedInput.contains("얼마") {
            questionType = QuestionType.totalAmount // 총 지출 관련 질문
        }

        return ParsedQuery(
            period: period,
            category: category,
            questionType: questionType,
            referenceDate: referenceDate,
            isCompare: isCompare
        ) // 파싱된 결과 반환
    }

    // MARK: - 답변 생성
    /// 파싱된 쿼리를 바탕으로 실제 답변을 생성
    /// - Parameters:
    ///   - parsed: 파싱된 쿼리 정보
    ///   - dataActor: 데이터 액터
    ///   - conversationContext: 대화 컨텍스트
    /// - Returns: 생성된 답변 텍스트
    private func generateAnswer(
        for parsed: ParsedQuery,
        dataActor: DataActor,
        conversationContext: ConversationContext
    ) async -> String {
        
        // 기간 정보가 없으면 에러 메시지 반환
        guard let period = parsed.period ?? conversationContext.period else {
            return "질문에서 기간(예: 이번달, 지난달 등)을 명확히 말씀해 주세요! 📅" // 기간 정보 누락 시 안내
        }
        
        // 날짜 범위 계산
        let dateRange = dateRange(for: period) // 기간을 실제 시작/종료 날짜로 변환
        
        // 해당 기간의 지출 데이터 가져오기
        let expenses = await dataActor.fetchExpenses(from: dateRange.0, to: dateRange.1) // 데이터베이스에서 지출 데이터 조회
        
        // 카테고리 필터링 (필요한 경우)
        let filteredExpenses: [DataActor.ExpenseData]
        if let category = parsed.category ?? conversationContext.category {
            filteredExpenses = expenses.filter { $0.category == category } // 특정 카테고리만 필터링
        } else {
            filteredExpenses = expenses // 모든 지출 데이터 사용
        }

        // 질문 유형에 따른 답변 생성
        let questionType = parsed.questionType ?? conversationContext.questionType ?? QuestionType.totalAmount // 질문 유형 결정
        
        switch questionType {
        case .totalAmount:
            return generateTotalAmountAnswer(
                expenses: filteredExpenses,
                period: period,
                category: parsed.category ?? conversationContext.category
            ) // 총 지출 금액 답변 생성
            
        case .byCategory, .summary:
            return generateCategorySummaryAnswer(expenses: filteredExpenses, period: period) // 카테고리별 요약 답변 생성
            
        case .topCategory:
            return generateTopCategoryAnswer(expenses: filteredExpenses, period: period) // 최대 지출 카테고리 답변 생성
            
        case .minCategory:
            return generateMinCategoryAnswer(expenses: filteredExpenses, period: period) // 최소 지출 카테고리 답변 생성
            
        case .topDay:
            return generateTopDayAnswer(expenses: filteredExpenses, period: period) // 최대 지출 날짜 답변 생성
            
        case .minDay:
            return generateMinDayAnswer(expenses: filteredExpenses, period: period) // 최소 지출 날짜 답변 생성
            
        case .count:
            return generateCountAnswer(
                expenses: filteredExpenses,
                period: period,
                category: parsed.category ?? conversationContext.category
            ) // 지출 횟수 답변 생성
            
        case .remainedBudget:
            return generateBudgetAnswer(expenses: filteredExpenses, period: period) // 남은 예산 답변 생성
            
        case .overspent:
            return generateOverspentAnswer(expenses: filteredExpenses, period: period) // 예산 초과 여부 답변 생성
            
        case .trend:
            return await generateTrendAnswer(
                dataActor: dataActor,
                category: parsed.category ?? conversationContext.category
            ) // 소비 트렌드 답변 생성
            
        case .paymentType:
            return generatePaymentTypeAnswer(expenses: filteredExpenses, period: period) // 결제 방식별 답변 생성
            
        case .avgExpense:
            return generateAverageAnswer(expenses: filteredExpenses, period: period) // 평균 지출 답변 생성
            
        case .compare:
            return await generateCompareAnswer(
                dataActor: dataActor,
                period: period,
                category: parsed.category ?? conversationContext.category
            ) // 비교 분석 답변 생성
            
        case .dateExpense:
            return generateDateExpenseAnswer(expenses: filteredExpenses, period: period) // 특정 날짜 지출 답변 생성
        
        case .none:
            return "죄송해요, 아직 이런 질문은 처리할 수 없어요. 다른 방식으로 물어봐 주세요! 🤗" // 분류되지 않은 질문 처리
        }
    }
    
    // MARK: - 개별 답변 생성 메서드들
    
    /// 총 지출 금액 답변 생성
    private func generateTotalAmountAnswer(expenses: [DataActor.ExpenseData], period: Period, category: String?) -> String {
        let sum = expenses.reduce(0) { $0 + $1.amount } // 모든 지출의 합계 계산
        let formattedAmount = Self.format(amount: sum) // 금액을 천 단위 콤마 포맷으로 변환
        let periodText = Self.format(period: period) // 기간을 한국어로 변환
        
        if let category = category {
            return "\(periodText) \(category) 총 지출은 \(formattedAmount)원입니다! 💰" // 특정 카테고리 총 지출
        } else {
            return "\(periodText) 총 지출은 \(formattedAmount)원입니다! 💰" // 전체 총 지출
        }
    }
    
    /// 카테고리별 요약 답변 생성
    private func generateCategorySummaryAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let categoryGroups = Dictionary(grouping: expenses, by: { $0.category }) // 카테고리별로 지출 그룹핑
        let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } } // 카테고리별 합계 계산
        
        if categorySums.isEmpty {
            return "\(Self.format(period: period))에는 지출 내역이 없습니다! 😊" // 지출이 없는 경우
        }
        
        let sortedCategories = categorySums.sorted { $0.value > $1.value } // 금액 순으로 정렬
        let summaryLines = sortedCategories.map {
            "\($0.key): \(Self.format(amount: $0.value))원" // 각 카테고리별 금액 포맷
        }
        
        return "\(Self.format(period: period)) 소비 요약 📊\n\n" + summaryLines.joined(separator: "\n") // 요약 정보 결합
    }
    
    /// 최대 지출 카테고리 답변 생성
    private func generateTopCategoryAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let categoryGroups = Dictionary(grouping: expenses, by: { $0.category }) // 카테고리별 그룹핑
        let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } } // 카테고리별 합계
        
        if let topCategory = categorySums.max(by: { $0.value < $1.value }) { // 최대 지출 카테고리 찾기
            return "\(Self.format(period: period)) 가장 많이 쓴 카테고리는 '\(topCategory.key)'입니다! (\(Self.format(amount: topCategory.value))원) 🔥"
        }
        return "\(Self.format(period: period))에는 지출 내역이 없습니다! 😊" // 지출이 없는 경우
    }
    
    /// 최소 지출 카테고리 답변 생성
    private func generateMinCategoryAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let categoryGroups = Dictionary(grouping: expenses, by: { $0.category }) // 카테고리별 그룹핑
        let categorySums = categoryGroups.mapValues { $0.reduce(0) { $0 + $1.amount } } // 카테고리별 합계
        
        if let minCategory = categorySums.min(by: { $0.value < $1.value }) { // 최소 지출 카테고리 찾기
            return "\(Self.format(period: period)) 가장 적게 쓴 항목은 '\(minCategory.key)'입니다! (\(Self.format(amount: minCategory.value))원) 💚"
        }
        return "\(Self.format(period: period))에는 지출 내역이 없습니다! 😊" // 지출이 없는 경우
    }
    
    /// 최대 지출 날짜 답변 생성
    private func generateTopDayAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let dayGroups = Dictionary(grouping: expenses, by: { Self.dayString($0.date) }) // 날짜별 그룹핑
        let daySums = dayGroups.mapValues { $0.reduce(0) { $0 + $1.amount } } // 날짜별 합계
        
        if let topDay = daySums.max(by: { $0.value < $1.value }) { // 최대 지출 날짜 찾기
            return "\(Self.format(period: period)) 가장 많이 쓴 날은 \(topDay.key)입니다! (\(Self.format(amount: topDay.value))원) 📈"
        }
        return "\(Self.format(period: period))에는 지출 내역이 없습니다! 😊" // 지출이 없는 경우
    }
    
    /// 최소 지출 날짜 답변 생성
    private func generateMinDayAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let dayGroups = Dictionary(grouping: expenses, by: { Self.dayString($0.date) }) // 날짜별 그룹핑
        let daySums = dayGroups.mapValues { $0.reduce(0) { $0 + $1.amount } } // 날짜별 합계
        
        if let minDay = daySums.min(by: { $0.value < $1.value }) { // 최소 지출 날짜 찾기
            return "\(Self.format(period: period)) 가장 적게 쓴 날은 \(minDay.key)입니다! (\(Self.format(amount: minDay.value))원) 📉"
        }
        return "\(Self.format(period: period))에는 지출 내역이 없습니다! 😊" // 지출이 없는 경우
    }
    
    /// 지출 횟수 답변 생성
    private func generateCountAnswer(expenses: [DataActor.ExpenseData], period: Period, category: String?) -> String {
        let count = expenses.count // 지출 건수 계산
        let periodText = Self.format(period: period) // 기간을 한국어로 변환
        
        if let category = category {
            return "\(periodText) \(category) 지출은 총 \(count)회입니다! 📝" // 특정 카테고리 지출 횟수
        } else {
            return "\(periodText) 지출 건수는 총 \(count)회입니다! 📝" // 전체 지출 횟수
        }
    }
    
    /// 남은 예산 답변 생성
    private func generateBudgetAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let budget: Double = 800_000 // 기본 예산 (추후 사용자 설정으로 변경 가능)
        let totalSpent = expenses.reduce(0) { $0 + $1.amount } // 총 지출 계산
        let remaining = max(0, budget - totalSpent) // 남은 예산 계산 (음수 방지)
        
        return "\(Self.format(period: period)) 남은 예산은 \(Self.format(amount: remaining))원입니다! 💸"
    }
    
    /// 예산 초과 답변 생성
    private func generateOverspentAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let budget: Double = 800_000 // 기본 예산
        let totalSpent = expenses.reduce(0) { $0 + $1.amount } // 총 지출 계산
        
        if totalSpent > budget {
            let overspent = totalSpent - budget // 초과 금액 계산
            return "\(Self.format(period: period)) 예산을 \(Self.format(amount: overspent))원 초과했습니다! ⚠️"
        } else {
            return "\(Self.format(period: period)) 예산을 초과하지 않았습니다! 👍" // 예산 내 지출
        }
    }
    
    /// 소비 트렌드 답변 생성
    private func generateTrendAnswer(dataActor: DataActor, category: String?) async -> String {
        var trendLines: [String] = [] // 트렌드 정보를 저장할 배열
        
        // 최근 6개월 데이터 수집
        for i in (0..<6).reversed() { // 6개월 전부터 현재까지
            let calendar = Calendar.current
            let targetMonth = calendar.date(byAdding: .month, value: -i, to: Date())! // i개월 전 날짜
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth))! // 월 시작일
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)! // 월 종료일
            
            let monthlyExpenses = await dataActor.fetchExpenses(from: startOfMonth, to: endOfMonth) // 해당 월 지출 데이터
            
            let monthlyTotal: Double
            if let category = category {
                monthlyTotal = monthlyExpenses
                    .filter { $0.category == category }
                    .reduce(0) { $0 + $1.amount } // 특정 카테고리만 필터링
            } else {
                monthlyTotal = monthlyExpenses.reduce(0) { $0 + $1.amount } // 전체 지출
            }
            
            trendLines.append("\(Self.monthString(startOfMonth)): \(Self.format(amount: monthlyTotal))원") // 월별 지출 정보 추가
        }
        
        let categoryText = category != nil ? "\(category!) " : "" // 카테고리 텍스트 설정
        return "\(categoryText)월별 소비 추세 📈\n\n" + trendLines.joined(separator: "\n") // 트렌드 정보 결합
    }
    
    /// 결제 방식별 답변 생성
    private func generatePaymentTypeAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        // 메모에서 "카드" 또는 "현금" 키워드로 필터링
        let cardExpenses = expenses.filter { $0.note.contains("카드") } // 카드 결제 지출 필터링
        let cashExpenses = expenses.filter { $0.note.contains("현금") } // 현금 결제 지출 필터링
        
        let cardTotal = cardExpenses.reduce(0) { $0 + $1.amount } // 카드 결제 총액
        let cashTotal = cashExpenses.reduce(0) { $0 + $1.amount } // 현금 결제 총액
        
        return "\(Self.format(period: period)) 결제 방식별 지출 💳\n\n카드: \(Self.format(amount: cardTotal))원\n현금: \(Self.format(amount: cashTotal))원"
    }
    
    /// 평균 지출 답변 생성
    private func generateAverageAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        guard !expenses.isEmpty else {
            return "\(Self.format(period: period))에는 지출 내역이 없습니다! 😊" // 지출이 없는 경우
        }
        
        let total = expenses.reduce(0) { $0 + $1.amount } // 총 지출 계산
        let average = total / Double(expenses.count) // 건당 평균 지출 계산
        
        return "\(Self.format(period: period)) 평균 지출은 건당 \(Self.format(amount: average))원입니다! 📊"
    }
    
    /// 비교 분석 답변 생성
    private func generateCompareAnswer(dataActor: DataActor, period: Period, category: String?) async -> String {
        // 현재 기간과 이전 기간 비교 로직 구현
        // 예: 이번달 vs 지난달
        return "비교 분석 기능은 곧 추가될 예정입니다! 🔍" // 아직 미구현 기능
    }
    
    /// 특정 날짜 지출 답변 생성
    private func generateDateExpenseAnswer(expenses: [DataActor.ExpenseData], period: Period) -> String {
        let total = expenses.reduce(0) { $0 + $1.amount } // 해당 날짜 총 지출 계산
        return "\(Self.format(period: period)) 지출은 총 \(Self.format(amount: total))원입니다! 📅"
    }

    // MARK: - 유틸리티 메서드들
    
    /// 기간에 따른 날짜 범위 계산
    /// - Parameter period: 기간 열거형
    /// - Returns: (시작날짜, 종료날짜) 튜플
    private func dateRange(for period: Period) -> (Date, Date) {
        let calendar = Calendar.current // 달력 인스턴스
        let now = Date() // 현재 날짜
        
        switch period {
        case .today:
            let start = calendar.startOfDay(for: now) // 오늘 00:00:00
            let end = calendar.date(byAdding: .day, value: 1, to: start)! // 내일 00:00:00
            return (start, end)
            
        case .yesterday:
            let today = calendar.startOfDay(for: now) // 오늘 00:00:00
            let start = calendar.date(byAdding: .day, value: -1, to: today)! // 어제 00:00:00
            return (start, today) // 어제 하루 범위
            
        case .thisWeek:
            let weekday = calendar.component(.weekday, from: now) // 현재 요일 (1=일요일)
            let start = calendar.date(byAdding: .day, value: -(weekday-1), to: calendar.startOfDay(for: now))! // 이번 주 일요일
            let end = calendar.date(byAdding: .day, value: 7-weekday+1, to: start)! // 다음 주 일요일
            return (start, end)
            
        case .lastWeek:
            let weekday = calendar.component(.weekday, from: now) // 현재 요일
            let thisWeekStart = calendar.date(byAdding: .day, value: -(weekday-1), to: calendar.startOfDay(for: now))! // 이번 주 시작
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)! // 지난주 시작
            return (lastWeekStart, thisWeekStart) // 지난주 범위
            
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))! // 이번 달 1일
            let end = calendar.date(byAdding: .month, value: 1, to: start)! // 다음 달 1일
            return (start, end)
            
        case .lastMonth:
            let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))! // 이번 달 1일
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth)! // 지난달 1일
            return (lastMonth, thisMonth) // 지난달 범위
            
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))! // 올해 1월 1일
            let end = calendar.date(byAdding: .year, value: 1, to: start)! // 내년 1월 1일
            return (start, end)
            
        case .lastYear:
            let thisYear = calendar.date(from: calendar.dateComponents([.year], from: now))! // 올해 1월 1일
            let lastYear = calendar.date(byAdding: .year, value: -1, to: thisYear)! // 작년 1월 1일
            return (lastYear, thisYear) // 작년 범위
            
        case .custom(let start, let end):
            return (start, end) // 사용자 정의 범위 그대로 사용
            
        case .specificDay(let day):
            let start = calendar.startOfDay(for: day) // 해당 날짜 00:00:00
            let end = calendar.date(byAdding: .day, value: 1, to: start)! // 다음 날 00:00:00
            return (start, end)
            
        case .recentNDays(let n):
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))! // 내일 00:00:00
            let start = calendar.date(byAdding: .day, value: -n+1, to: end)! // n일 전부터
            return (start, end)
        }
    }

    /// 카테고리 목록 추출
    /// - Parameter dataActor: 데이터 액터
    /// - Returns: 모든 카테고리 목록
    private func extractAllCategories(dataActor: DataActor) async -> [String] {
        return await dataActor.getAllCategories() // 데이터베이스에서 모든 카테고리 가져오기
    }

    /// 날짜를 문자열로 포맷
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 날짜 문자열
    private static func dayString(_ date: Date) -> String {
        return dayFormatter.string(from: date) // "yyyy-MM-dd(E)" 형식으로 변환
    }

    /// 월을 문자열로 포맷
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 월 문자열
    private static func monthString(_ date: Date) -> String {
        return monthFormatter.string(from: date) // "yyyy년 M월" 형식으로 변환
    }

    /// 금액을 포맷된 문자열로 변환
    /// - Parameter amount: 금액
    /// - Returns: 천 단위 콤마가 있는 문자열
    private static func format(amount: Double) -> String {
        return amountFormatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))" // 천 단위 콤마 포맷
    }

    /// 기간을 문자열로 포맷
    /// - Parameter period: 기간 열거형
    /// - Returns: 한국어 기간 문자열
    private static func format(period: Period) -> String {
        switch period {
        case .today: return "오늘"
        case .yesterday: return "어제"
        case .thisWeek: return "이번 주"
        case .lastWeek: return "지난주"
        case .thisMonth: return "이번 달"
        case .lastMonth: return "지난달"
        case .thisYear: return "올해"
        case .lastYear: return "작년"
        case .custom(let start, _): return monthString(start) // 사용자 정의 기간은 시작 월로 표시
        case .specificDay(let date): return dayString(date) // 특정 날짜는 날짜로 표시
        case .recentNDays(let n): return "최근 \(n)일"
        }
    }

    /// "5월 15일" 형태의 특정 날짜 파싱
    /// - Parameter text: 입력 텍스트
    /// - Returns: 파싱된 날짜 (올해 기준)
    private static func parseSpecificDate(text: String) -> Date? {
        if let match = specificDateRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), // 정규식 매칭
           let monthRange = Range(match.range(at: 1), in: text), // 월 부분 추출
           let dayRange = Range(match.range(at: 2), in: text) { // 일 부분 추출
            
            let month = Int(text[monthRange])! // 월을 정수로 변환
            let day = Int(text[dayRange])! // 일을 정수로 변환
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date()) // 현재 연도
            
            return calendar.date(from: DateComponents(year: currentYear, month: month, day: day)) // 올해 기준 날짜 생성
        }
        return nil // 매칭되지 않으면 nil 반환
    }

    /// "5월" 형태의 월 파싱
    /// - Parameter text: 입력 텍스트
    /// - Returns: 파싱된 월의 첫째 날 (올해 기준)
    private static func parseMonth(text: String) -> Date? {
        if let match = monthRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), // 정규식 매칭
           let monthRange = Range(match.range(at: 1), in: text) { // 월 부분 추출
            
            let month = Int(text[monthRange])! // 월을 정수로 변환
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date()) // 현재 연도
            
            return calendar.date(from: DateComponents(year: currentYear, month: month, day: 1)) // 올해 해당 월 1일
        }
        return nil // 매칭되지 않으면 nil 반환
    }
}

// MARK: - Date Extension (날짜 계산 유틸리티)
extension Date {
    /// 특정 요일의 이전 날짜 찾기
    /// - Parameter weekday: 요일
    /// - Returns: 해당 요일의 이전 날짜
    func previous(_ weekday: Weekday) -> Date {
        return get(.previous, weekday) // 이전 방향으로 해당 요일 찾기
    }
    
    /// 특정 요일의 다음 날짜 찾기
    /// - Parameter weekday: 요일
    /// - Returns: 해당 요일의 다음 날짜
    func next(_ weekday: Weekday) -> Date {
        return get(.next, weekday) // 다음 방향으로 해당 요일 찾기
    }
    
    /// 날짜 계산 내부 로직
    /// - Parameters:
    ///   - direction: 검색 방향 (이전/다음)
    ///   - weekday: 요일
    /// - Returns: 계산된 날짜
    private func get(_ direction: SearchDirection, _ weekday: Weekday) -> Date {
        let calendar = Calendar.current // 달력 인스턴스
        let components = DateComponents(weekday: weekday.rawValue) // 요일 컴포넌트 생성
        
        switch direction {
        case .next:
            return calendar.nextDate(after: self, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)! // 다음 해당 요일 찾기
        case .previous:
            return calendar.nextDate(after: self.addingTimeInterval(-86400), matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)! // 이전 해당 요일 찾기 (하루 빼고 다음 찾기)
        }
    }
    
    /// 검색 방향 열거형
    enum SearchDirection {
        case next    // 다음
        case previous // 이전
    }
    
    /// 요일 열거형
    enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday // 일요일=1, 월요일=2, ..., 토요일=7
    }
}
