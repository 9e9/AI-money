# 조준희 포트폴리오

<br />

# Intro

> 안녕하세요! iOS 개발자를 목표로 하는 조준희입니다.  
> 7개월간 AI Money 프로젝트를 직접 설계하고 개발하며  
> Swift 네이티브 개발 역량과 Apple 기술 스택을 쌓아왔습니다.

<br />

# Project
## 📱 AI Money - AI 기반 스마트 가계부

> **개발 배경**: 단순 지출 기록을 넘어, CoreML 기반 자동 분류와 대화형 챗봇을 결합한  
> 스마트 가계부 앱을 직접 기획하고 구현하였습니다.  
> SwiftUI, SwiftData, MVVM 아키텍처를 실제 프로젝트에 적용하며  
> iOS 개발 전반의 역량을 키운 개인 프로젝트입니다.

## 🎯 프로젝트 개요

AI Money는 **CoreML 기반 텍스트 분류 모델**과 **자연어 처리 AI 챗봇**을 결합한 스마트 가계부 iOS 애플리케이션입니다. 사용자의 지출 패턴을 자동으로 분석하고, 대화형 인터페이스를 통해 직관적인 재정 관리 경험을 제공합니다.

## ✨ 주요 기능

### 📊 지출 관리
- **캘린더 기반 지출 추가/조회**: 날짜별 지출 내역을 직관적으로 관리
- **다중 지출 일괄 입력**: 한 번에 여러 지출 항목을 카드 형태로 입력 가능
- **카테고리별 분류**: 식비, 교통, 쇼핑, 여가 등 9가지 기본 카테고리 + 커스텀 카테고리 지원
- **한국 공휴일 자동 표시**: 캘린더에 국경일, 전통명절, 기념일 자동 표시
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 20 09" src="https://github.com/user-attachments/assets/88c714cb-4304-441c-bcc9-224d13790e22" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 27 52" src="https://github.com/user-attachments/assets/ceabe96b-8611-44b0-a2cc-12ad7c6e9595" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 46 31" src="https://github.com/user-attachments/assets/79525aa0-ffe4-4598-b2ec-ec8bf5b91760" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 27 47" src="https://github.com/user-attachments/assets/b7b1aeca-e43a-4387-8bbd-4fe72cd7fb2c" />

### 🤖 AI 기능
- **CoreML 텍스트 분류 모델**: Create ML로 직접 학습시킨 ExpenseClassifier 모델로 지출 내역을 자동 카테고리 분류
- **대화형 AI 챗봇**: 자연어로 지출 현황 질문 가능
  - "이번 달 총 지출은?"
  - "지난 주 가장 많이 쓴 카테고리는?"
  - "오늘 얼마 썼어?"
- **컨텍스트 기반 대화**: 이전 대화 내용을 기억하여 연속적인 질문 가능
- **스마트 답변 생성**: 기간별, 카테고리별 지출 분석 및 통계 제공
<img width="300" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 20 17" src="https://github.com/user-attachments/assets/c19eed95-4b07-4f5c-8340-b4b0157d84a7" />

### 📈 데이터 시각화
- **카테고리별 차트**: Charts 프레임워크를 활용한 시각적 분석
- **월별/기간별 통계**: 선택한 기간의 지출 패턴 분석
- **상세 내역 보기**: 애니메이션이 적용된 확장/축소 기능
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 45 45" src="https://github.com/user-attachments/assets/07f3bbbc-3503-4d85-b2d5-68187aff0f5c" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 45 50" src="https://github.com/user-attachments/assets/38356e34-ae39-4f15-a6aa-afaf174f8411" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 45 14" src="https://github.com/user-attachments/assets/5ff93735-b7e3-4733-acc2-a9dcfb78636a" />

## 🛠 기술 스택

### Core Technologies
- **Swift** (99.9%) - SwiftUI 기반 네이티브 iOS 개발
- **SwiftData** - 로컬 데이터베이스 관리
- **CoreML / Create ML** - 텍스트 분류 모델 직접 학습 및 통합
- **Combine** - 리액티브 프로그래밍

### Architecture & Design Pattern
- **MVVM** (Model-View-ViewModel) 아키텍처
- **Protocol-Oriented Programming** - ExpenseServiceProtocol 기반 서비스 레이어
- **@MainActor** - 메인 스레드 안전성 보장
- **ObservableObject** - SwiftUI 상태 관리

### UI/UX
- **SwiftUI** - 선언형 UI 프레임워크
- **Charts Framework** - 데이터 시각화
- **Custom Animations** - 스프링 애니메이션, 전환 효과

## 📂 프로젝트 구조

```
AI money/
├── Models/               # 데이터 모델
│   ├── Expense.swift    # 지출 데이터 모델 (@Model)
│   └── ExpenseCalendarModels.swift
├── Views/               # SwiftUI 뷰
│   ├── ContentView.swift          # 메인 탭 뷰
│   ├── ExpenseCalendarView.swift  # 캘린더 화면
│   ├── ChartView.swift            # 차트 화면
│   └── ChatBotView.swift          # AI 챗봇 화면
├── ViewModels/          # 비즈니스 로직
│   ├── ExpenseCalendarViewModel.swift
│   ├── ChartViewModel.swift
│   └── ChatBotViewModel.swift
├── Services/            # 서비스 레이어
│   ├── AIService.swift           # AI 분석 서비스
│   └── ExpenseServiceProtocol.swift
└── ExpenseClassifier.mlproj/  # CoreML 모델 프로젝트
```

## 🎓 개발자 정보

- **이름**: 조준희
- **학교**: 상지대학교 컴퓨터공학과 졸업
- **개발 기간**: 2024.03 ~ 2024.10 (7개월)
- **버전**: 1.0 beta
