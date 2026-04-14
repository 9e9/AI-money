# 조준희 포트폴리오

<br />

# Intro

> 안녕하세요! iOS 개발자를 목표로 하는 조준희입니다.
> 7개월간 AI Money 프로젝트를 직접 설계하고 구현하며
> Swift 네이티브 개발 역량과 Apple 기술 스택을 쌓아왔습니다.

<br />

# Project

## 📱 AI Money - AI 기반 스마트 가계부

> **개발 배경**: 단순 지출 기록을 넘어, 직접 학습시킨 CoreML 텍스트 분류 모델과
> 컨텍스트 기반 대화형 챗봇을 결합한 스마트 가계부 앱을 기획하고 구현했습니다.
> SwiftUI, SwiftData, MVVM, Protocol-Oriented Programming을 실제 프로젝트에 적용하며
> iOS 개발 전반의 역량을 키운 개인 프로젝트입니다.
>
> **개발 기간**: 2025.03 ~ 2025.10 (7개월)

## 🎯 프로젝트 개요

AI Money는 **Create ML로 직접 학습시킨 텍스트 분류 모델(ExpenseClassifier)**과 **컨텍스트 기반 AI 챗봇**을 결합한 스마트 가계부 iOS 애플리케이션입니다. 사용자의 지출 패턴을 자동으로 분석하고, 자연어 대화를 통해 직관적인 재정 관리 경험을 제공합니다.

## ✨ 주요 기능

### 📊 지출 관리
- **캘린더 기반 지출 추가/조회**: 날짜별 지출 내역을 직관적으로 관리
- **다중 지출 일괄 입력**: 한 번에 여러 지출 항목을 카드 형태로 입력 가능
- **카테고리별 분류**: 식비, 교통, 쇼핑, 여가 등 기본 카테고리 + 사용자 커스텀 카테고리 지원
- **한국 공휴일 자동 표시**: 국경일, 전통명절, 기념일, 대체공휴일 색상 구분 표시
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 20 09" src="https://github.com/user-attachments/assets/88c714cb-4304-441c-bcc9-224d13790e22" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 27 52" src="https://github.com/user-attachments/assets/ceabe96b-8611-44b0-a2cc-12ad7c6e9595" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 46 31" src="https://github.com/user-attachments/assets/79525aa0-ffe4-4598-b2ec-ec8bf5b91760" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 27 47" src="https://github.com/user-attachments/assets/b7b1aeca-e43a-4387-8bbd-4fe72cd7fb2c" />

### 🤖 AI 챗봇 기능
- **CoreML 텍스트 분류**: Create ML로 직접 학습한 ExpenseClassifier 모델로 질문 유형을 15가지로 분류
- **하이브리드 파싱**: ML 분류 결과와 정규식 기반 키워드 파싱을 조합해 인식률 보완
- **컨텍스트 기반 대화**: `ConversationContext`로 이전 대화의 기간/카테고리를 기억하여 연속 질문 처리
- **지원 질문 유형**: 총 지출, 카테고리별 분석, 최대/최소 지출 날짜 및 카테고리, 지출 횟수, 예산 잔액, 소비 트렌드(최근 6개월), 평균 지출 등
<img width="300" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 20 17" src="https://github.com/user-attachments/assets/c19eed95-4b07-4f5c-8340-b4b0157d84a7" />

### 📈 데이터 시각화
- **카테고리별 차트**: Charts 프레임워크를 활용한 시각적 지출 분석
- **월별/기간별 통계**: 연월 피커를 통해 원하는 기간의 지출 패턴 분석
- **상세 내역 보기**: 스프링 애니메이션이 적용된 확장/축소 기능
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 45 45" src="https://github.com/user-attachments/assets/07f3bbbc-3503-4d85-b2d5-68187aff0f5c" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 45 50" src="https://github.com/user-attachments/assets/38356e34-ae39-4f15-a6aa-afaf174f8411" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 45 14" src="https://github.com/user-attachments/assets/5ff93735-b7e3-4733-acc2-a9dcfb78636a" />

## 🛠 기술 스택

### Core Technologies
- **Swift** (99.9%) — SwiftUI 기반 네이티브 iOS 개발
- **SwiftData** — `@Model`, `FetchDescriptor`, `@ModelActor`를 활용한 로컬 데이터 관리
- **CoreML / Create ML** — 지출 질문 분류 모델(ExpenseClassifier) 직접 학습 및 통합
- **Charts Framework** — 카테고리별 지출 데이터 시각화

### Architecture & Design Pattern
- **MVVM** — View / ViewModel / Model 레이어 분리
- **Protocol-Oriented Programming** — `ExpenseServiceProtocol`, `ExpenseCalendarServiceProtocol`로 인터페이스 추상화
- **`@MainActor`** — ViewModel 전체에 적용하여 UI 업데이트 스레드 안전성 보장
- **`@ModelActor`** — `DataActor`를 통한 SwiftData 비동기 접근 안전성 확보
- **Singleton** — `AIService`, `ExpenseCalendarViewModel`, `KoreanHolidayService`

### 데이터 설계
- **`CalendarState` enum** — 날짜 미선택 / 지출 있는 날짜 선택 / 지출 없는 날짜 선택 상태를 타입으로 관리
- **`DailyExpenseSummary`** — 날짜별 지출 요약, 카테고리 breakdown, 최대 지출 카테고리를 computed property로 제공
- **`UserDefaults` Extension** — 커스텀 카테고리를 JSON 인코딩으로 영속 저장
- **`FormatHelper`** — 앱 전체 날짜/금액/퍼센트 포맷 로직을 단일 구조체로 통합

## 📂 프로젝트 구조

```
AI money/
├── Models/
│   ├── Expense.swift                  # SwiftData @Model (@Attribute(.unique) UUID)
│   ├── ExpenseCalendarModels.swift    # CalendarDay, DailyExpenseSummary, CalendarState 등
│   ├── ChatMessage.swift              # Identifiable, Equatable 채팅 메시지 모델
│   ├── KoreanHoliday.swift            # 공휴일 타입 열거형 및 KoreanHolidayService
│   └── YearMonthPickerModels.swift
├── Views/
│   ├── ContentView.swift              # 메인 탭 뷰
│   ├── ExpenseCalendarView.swift      # 캘린더 화면
│   ├── ChartView.swift / PieChartView.swift  # 차트 화면
│   ├── ChatBotView.swift              # AI 챗봇 화면
│   ├── AddExpenseView.swift / AddExpenseCardView.swift  # 지출 입력
│   ├── CategoryManagementView.swift   # 커스텀 카테고리 관리
│   └── YearMonthPickerView.swift      # 연월 선택 피커
├── ViewModels/
│   ├── ExpenseCalendarViewModel.swift # 메인 ViewModel, ExpenseCalendarServiceProtocol 구현
│   ├── ChartViewModel.swift           # 정렬 순서(기본/높은순/낮은순), 연월 선택 상태 관리
│   ├── ChatBotViewModel.swift         # 메시지 배열, ConversationContext, predefinedQuestions
│   ├── AddExpenseViewModel.swift      # 다중 지출 그룹 입력 및 유효성 검사
│   └── CategoryManagementViewModel.swift  # 커스텀 카테고리 CRUD
├── Services/
│   ├── AIService.swift                # CoreML + 키워드 하이브리드 파싱, 15가지 질문 유형 처리
│   ├── DataActor.swift                # @ModelActor 기반 SwiftData 비동기 접근
│   └── ExpenseServiceProtocol.swift   # 지출/캘린더 서비스 프로토콜 정의
├── Extensions/
│   ├── Date+Extensions.swift          # year, month computed property
│   ├── FormatHelper.swift             # 날짜/금액/퍼센트 통합 포맷 유틸리티
│   └── UserDefaultsExtensions.swift   # 커스텀 카테고리 JSON 영속화
└── ExpenseClassifier.mlproj/          # Create ML 모델 프로젝트
```

## 🎓 개발자 정보

- **이름**: 조준희
- **학교**: 상지대학교 컴퓨터공학과 졸업
- **개발 기간**: 2025.03 ~ 2025.10 (7개월)
- **버전**: 1.0 beta
