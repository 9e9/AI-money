# 조준희 포트폴리오

<br />

# Intro

> 안녕하세요! ***"시대에 맞춰 기술을 배우고 싶은"*** 조준희입니다!
> 7개월간 AI money 프로젝트를 진행하며 Apple의 기술과 AI를 활용하여 개발 역량을 키웠습니다.
> 제가 진행한 프로젝트에 대한 자세한 내용은 아래에 간략히 서술했습니다.

# Project
## 📱 AI Money - AI 기반 스마트 가계부

> **개발 배경**: 본 프로젝트는 AI 기술을 활용한 iOS 개발 역량을 보여주기 위해 제작되었습니다.  코드의 약 90%는 AI 도구(GitHub Copilot, Claude Sonnet 4.5 등)를 활용하여 작성되었으며, 이를 통해 AI 협업 개발 능력과 생산성 향상 역량을 입증합니다.

## 🎯 프로젝트 개요

AI Money는 **CoreML 기반 텍스트 분류 모델**과 **자연어 처리 AI 챗봇**을 결합한 스마트 가계부 iOS 애플리케이션입니다. 사용자의 지출 패턴을 자동으로 분석하고, 대화형 인터페이스를 통해 직관적인 재정 관리 경험을 제공합니다.

## ✨ 주요 기능

### 📊 지출 관리
- **캘린더 기반 지출 추가/조회**:  날짜별 지출 내역을 직관적으로 관리
- **다중 지출 일괄 입력**: 한 번에 여러 지출 항목을 카드 형태로 입력 가능
- **카테고리별 분류**: 식비, 교통, 쇼핑, 여가 등 9가지 기본 카테고리 + 커스텀 카테고리 지원
- **한국 공휴일 자동 표시**: 캘린더에 국경일, 전통명절, 기념일 자동 표시
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 20 09" src="https://github.com/user-attachments/assets/88c714cb-4304-441c-bcc9-224d13790e22" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 27 52" src="https://github.com/user-attachments/assets/ceabe96b-8611-44b0-a2cc-12ad7c6e9595" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 46 31" src="https://github.com/user-attachments/assets/79525aa0-ffe4-4598-b2ec-ec8bf5b91760" />
<img width="200" alt="Simulator Screenshot - iPhone 16 Pro Max 26 - 2026-01-12 at 00 27 47" src="https://github.com/user-attachments/assets/b7b1aeca-e43a-4387-8bbd-4fe72cd7fb2c" />

### 🤖 AI 기능
- **CoreML 텍스트 분류 모델**: 지출 내역을 자동으로 카테고리별로 분류
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
- **CoreML** - 머신러닝 모델 통합 (ExpenseClassifier)
- **Combine** - 리액티브 프로그래밍

### Architecture & Design Pattern
- **MVVM** (Model-View-ViewModel) 아키텍처
- **Protocol-Oriented Programming** - ExpenseServiceProtocol 기반 서비스 레이어
- **@MainActor** - 메인 스레드 안전성 보장
- **ObservableObject** - SwiftUI 상태 관리

### UI/UX
- **SwiftUI** - 선언형 UI 프레임워킹
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
│   ├── ExpenseCalendarView. swift  # 캘린더 화면
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
- **학교**: 상지대 컴퓨터공학과(졸업 예정)
- **버전**: 1.0 beta

## 🤖 AI 활용 개발 방법론

본 프로젝트는 **AI 협업 개발**의 모범 사례로, 다음과 같은 AI 도구를 활용했습니다:

- **GitHub Copilot**: 코드 자동 완성, 주석 기반 코드 생성
- **Claude Sonnet 4.5**: 아키텍처 설계, 알고리즘 구현, 디버깅
- **CoreML Create ML**: 텍스트 분류 모델 학습

## 💡 핵심 역량 증명

이 프로젝트를 통해 다음 역량을 보유하고 있음을 증명합니다:

1. **AI 도구 활용 능력** - AI를 효과적으로 활용한 고생산성 개발
2. **iOS 네이티브 개발** - SwiftUI, SwiftData, CoreML 등 최신 기술 스택
3. **아키텍처 설계** - MVVM, Protocol-Oriented 설계
4. **머신러닝 통합** - CoreML 모델 학습 및 앱 통합
5. **UX/UI 구현** - 직관적인 사용자 인터페이스 및 애니메이션

---

**Note**: 본 프로젝트는 AI 기술을 활용한 빠른 프로토타이핑과 개발 생산성 향상을 목표로 하였으며, 실제 프로덕션 환경에서는 AI가 생성한 코드에 대한 면밀한 검토와 테스트가 필요합니다. 
