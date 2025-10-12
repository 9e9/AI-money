//
//  AddExpenseCardView.swift
//  AI money
//
//  Created by 조준희 on 7/27/25.
//

import SwiftUI
import Combine

/// 지출 추가/편집을 위한 카드 형태의 뷰
/// 각 지출 항목을 입력하는 개별 카드를 표현하며, 카테고리, 금액, 메모 등을 입력할 수 있음
struct AddExpenseCardView: View {
    // MARK: - Binding Properties (외부에서 전달받아 양방향으로 연결되는 데이터)
    @Binding var group: ExpenseGroup // 현재 편집 중인 지출 그룹 데이터 (금액, 카테고리, 메모 등을 포함)
    
    // MARK: - Input Properties (외부에서 전달받는 읽기 전용 데이터들)
    let index: Int                              // 현재 카드의 순서 인덱스 (0부터 시작하여 몇 번째 카드인지 구분)
    let selectedDate: Date                      // 사용자가 선택한 지출 날짜
    let isEditing: Bool                         // 현재 편집 모드인지 여부 (편집 모드일 때만 삭제/관리 버튼들이 표시됨)
    let allCategories: [String]                 // 선택 가능한 모든 카테고리 목록 (기본 카테고리 + 사용자 정의 카테고리)
    let expenseGroupCount: Int                  // 현재 화면에 있는 전체 지출 카드의 개수
    let isFocused: Bool                         // 현재 이 카드가 활성화(포커스)된 상태인지 여부
    
    // MARK: - Callback Functions (특정 이벤트 발생 시 부모 뷰에서 처리할 함수들)
    let onDelete: (Int) -> Void                 // 카드 삭제 요청 시 호출할 함수 (카드 인덱스를 매개변수로 전달)
    let onDuplicate: (Int) -> Void              // 카드 복사 요청 시 호출할 함수 (카드 인덱스를 매개변수로 전달)
    let onFocus: (Int) -> Void                  // 카드를 터치하여 포커스할 때 호출할 함수 (카드 인덱스를 매개변수로 전달)
    let onApplyQuickAmount: (String, Int) -> Void // 빠른 금액 버튼 선택 시 호출할 함수 (선택한 금액 문자열과 카드 인덱스를 매개변수로 전달)
    let onShowCategoryManagement: () -> Void    // 카테고리 관리 화면을 표시해달라고 요청할 때 호출할 함수
    let onAmountChange: (String, Int) -> Void   // 사용자가 금액을 입력/변경할 때 호출할 함수 (새 금액 문자열과 카드 인덱스를 매개변수로 전달)
    
    // MARK: - State Properties (이 뷰 내부에서만 관리하는 상태 변수들)
    @FocusState private var isAmountFieldFocused: Bool // 금액 입력 텍스트필드가 현재 키보드 포커스를 받고 있는지 여부
    @State private var showQuickAmounts = false        // 빠른 금액 선택 버튼들을 화면에 표시할지 여부
    
    // MARK: - Constants (변경되지 않는 상수들)
    /// 사용자가 빠르게 선택할 수 있는 미리 정의된 금액들의 배열 (문자열 형태로 저장)
    /// 5천원부터 10만원까지 자주 사용되는 금액들로 구성
    private let quickAmounts = ["5000", "10000", "20000", "30000", "50000", "100000"]

    var body: some View {
        VStack(spacing: 0) { // 세로로 배치하되 요소 간 간격은 0으로 설정
            // 카드 최상단의 헤더 영역 (카드 번호, 미리보기 정보, 삭제 버튼 등을 포함)
            cardHeader
            
            VStack(spacing: 24) { // 메인 콘텐츠들을 세로로 배치하되 각 섹션 간 24pt 간격 설정
                // 카테고리를 선택할 수 있는 드롭다운 메뉴 영역
                categoryRow
                
                // 금액을 숫자로 입력할 수 있는 텍스트필드 영역
                amountRow
                
                // 조건부 렌더링: 빠른 금액 선택 버튼들 (금액 필드가 포커스되고 비어있을 때만 표시)
                if showQuickAmounts {
                    quickAmountGrid
                }
                
                // 선택사항인 메모를 입력할 수 있는 텍스트필드 영역
                noteRow
                
                // 조건부 렌더링: 추가 액션 버튼들 (편집 모드이고 카드가 2개 이상일 때만 표시)
                if isEditing && expenseGroupCount > 1 {
                    actionRow
                }
            }
            .padding(20) // 메인 콘텐츠 영역 전체에 20pt의 안쪽 여백 적용
        }
        .background(cardBackground) // 카드 전체의 배경 스타일 적용 (테두리, 그림자 등 포함)
        .onTapGesture { // 카드 전체 영역을 터치했을 때의 제스처 처리
            // 이 카드를 활성화(포커스) 상태로 변경하도록 부모에게 알림
            onFocus(index)
        }
        .onChange(of: isAmountFieldFocused) { oldValue, newValue in // 금액 필드의 포커스 상태가 변경될 때 실행
            // 부드러운 애니메이션과 함께 빠른 금액 버튼들의 표시/숨김 상태 변경
            withAnimation(.easeInOut(duration: 0.3)) {
                // 금액 필드가 포커스되었고 동시에 현재 금액이 비어있을 때만 빠른 금액 버튼들을 표시
                showQuickAmounts = newValue && group.amount.isEmpty
            }
        }
    }
    
    /// 카드 상단의 헤더 영역을 구성하는 뷰
    /// 카드 순서 번호, 현재 입력된 정보의 미리보기, 삭제 버튼 등을 포함
    private var cardHeader: some View {
        HStack(spacing: 16) { // 가로로 배치하되 요소 간 16pt 간격 설정
            // 카드의 순서를 나타내는 원형 번호 인디케이터
            Circle()
                .fill(isFocused ? Color.black : Color(.systemGray4)) // 포커스 상태에 따라 배경색 변경 (포커스 시 검은색, 아니면 회색)
                .frame(width: 24, height: 24) // 원의 크기를 24x24pt로 설정
                .overlay( // 원 위에 텍스트를 오버레이로 배치
                    Text("\(index + 1)") // 카드 번호 표시 (배열 인덱스는 0부터 시작하므로 +1하여 1부터 표시)
                        .font(.system(size: 12, weight: .bold, design: .rounded)) // 12pt 크기의 굵은 둥근 폰트 사용
                        .foregroundColor(isFocused ? .white : .secondary) // 포커스 상태에 따라 텍스트 색상 변경 (포커스 시 흰색, 아니면 보조 색상)
                )
            
            // 현재 입력된 카테고리와 금액 정보를 미리보기로 표시하는 영역
            HStack(spacing: 12) { // 가로로 배치하되 요소 간 12pt 간격 설정
                // 조건부 렌더링: 카테고리가 입력되었을 때만 카테고리명 표시
                if !group.category.isEmpty {
                    Text(group.category)
                        .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
                        .foregroundColor(.primary) // 기본 텍스트 색상 사용
                }
                
                // 금액 입력 상태에 따른 조건부 표시
                if !group.amount.isEmpty {
                    // 금액이 입력된 경우: 포맷팅된 금액과 '원' 단위를 함께 표시
                    Text("\(group.formattedAmount)원")
                        .font(.system(size: 14, weight: .semibold, design: .rounded)) // 14pt 크기의 약간 굵은 둥근 폰트
                        .foregroundColor(.secondary) // 보조 텍스트 색상 사용
                } else {
                    // 금액이 입력되지 않은 경우: 사용자에게 입력을 유도하는 안내 텍스트 표시
                    Text("금액 입력")
                        .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
                        .foregroundColor(.orange) // 주황색으로 표시하여 주의를 끌도록 설정
                }
            }
            
            Spacer() // 남은 가로 공간을 모두 차지하여 삭제 버튼을 오른쪽 끝으로 밀어냄
            
            // 조건부 렌더링: 편집 모드이고 카드가 2개 이상일 때만 삭제 버튼 표시
            if isEditing && expenseGroupCount > 1 {
                Button(action: { onDelete(index) }) { // 버튼을 누르면 현재 카드의 인덱스를 전달하며 삭제 함수 호출
                    Image(systemName: "minus.circle.fill") // iOS 시스템의 마이너스 원형 아이콘 사용
                        .font(.system(size: 20)) // 20pt 크기로 아이콘 설정
                        .foregroundColor(.red) // 삭제를 의미하는 빨간색으로 설정
                }
            }
        }
        .padding(.horizontal, 20) // 좌우에 20pt의 여백 적용
        .padding(.vertical, 16) // 상하에 16pt의 여백 적용
        .background(Color(.systemGray6).opacity(0.3)) // 헤더 영역의 배경을 연한 회색으로 설정 (투명도 30%)
    }
    
    /// 사용자가 카테고리를 선택할 수 있는 드롭다운 메뉴 영역
    /// 사용 가능한 모든 카테고리 목록을 제공하며, 카테고리 관리 링크도 포함
    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 8) { // 왼쪽 정렬로 세로 배치하되 요소 간 8pt 간격 설정
            HStack { // 섹션 제목과 관리 버튼을 가로로 배치
                // 섹션의 제목 레이블
                Text("카테고리")
                    .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
                    .foregroundColor(.secondary) // 보조 텍스트 색상으로 설정하여 주요 콘텐츠와 구분
                
                Spacer() // 남은 공간을 차지하여 관리 버튼을 오른쪽으로 밀어냄
                
                // 조건부 렌더링: 편집 모드일 때만 카테고리 관리 버튼 표시
                if isEditing {
                    Button("관리", action: onShowCategoryManagement) // '관리' 텍스트 버튼, 누르면 카테고리 관리 화면 표시 요청
                        .font(.system(size: 12, weight: .medium)) // 12pt 크기의 중간 굵기 폰트
                        .foregroundColor(.blue) // 파란색으로 설정하여 링크임을 시각적으로 표현
                }
            }
            
            // 카테고리 선택을 위한 드롭다운 메뉴
            Menu {
                // 사용 가능한 모든 카테고리를 순회하며 메뉴 항목으로 생성
                ForEach(allCategories, id: \.self) { category in
                    Button(category) { // 각 카테고리명을 버튼으로 생성
                        group.category = category // 선택된 카테고리로 현재 그룹의 카테고리 값 업데이트
                    }
                }
            } label: {
                // 메뉴 버튼의 외형을 커스터마이징 (현재 선택된 카테고리 표시 + 드롭다운 화살표)
                HStack { // 가로로 배치
                    Text(group.category) // 현재 선택된 카테고리명 표시
                        .font(.system(size: 16, weight: .medium)) // 16pt 크기의 중간 굵기 폰트
                        .foregroundColor(.primary) // 기본 텍스트 색상 사용
                    
                    Spacer() // 남은 공간을 차지하여 화살표를 오른쪽으로 밀어냄
                    
                    Image(systemName: "chevron.down") // iOS 시스템의 아래쪽 화살표 아이콘 (드롭다운임을 시각적으로 표현)
                        .font(.system(size: 12, weight: .medium)) // 12pt 크기의 중간 굵기로 아이콘 설정
                        .foregroundColor(.secondary) // 보조 색상으로 설정하여 주요 텍스트와 구분
                }
                .padding(.horizontal, 16) // 좌우에 16pt의 안쪽 여백 적용
                .padding(.vertical, 12) // 상하에 12pt의 안쪽 여백 적용
                .background( // 메뉴 버튼의 배경 스타일 설정
                    RoundedRectangle(cornerRadius: 8) // 모서리가 8pt만큼 둥근 사각형
                        .fill(Color(.systemGray6)) // 시스템 회색6 색상으로 채우기
                )
            }
        }
    }
    
    /// 사용자가 지출 금액을 숫자로 입력할 수 있는 텍스트필드 영역
    /// 숫자 키패드를 제공하고, 포커스 상태에 따라 시각적 피드백을 제공
    private var amountRow: some View {
        VStack(alignment: .leading, spacing: 8) { // 왼쪽 정렬로 세로 배치하되 요소 간 8pt 간격 설정
            // 섹션 제목 레이블
            Text("금액")
                .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
                .foregroundColor(.secondary) // 보조 텍스트 색상으로 설정
            
            HStack { // 입력 필드와 단위 표시를 가로로 배치
                // 금액 입력을 위한 텍스트필드
                TextField("0", text: $group.formattedAmount) // 플레이스홀더로 "0" 표시, 포맷된 금액과 양방향 바인딩
                    .font(.system(size: 24, weight: .bold, design: .rounded)) // 24pt 크기의 굵은 둥근 폰트 (금액을 강조하기 위해 큰 폰트 사용)
                    .keyboardType(.numberPad) // 숫자 키패드만 표시하여 숫자 입력에 최적화
                    .multilineTextAlignment(.leading) // 텍스트를 왼쪽 정렬
                    .focused($isAmountFieldFocused) // 포커스 상태를 바인딩하여 키보드 표시/숨김 제어
                    .onReceive(Just(group.formattedAmount)) { newValue in
                        // 실시간으로 입력값을 숫자만 필터링
                        let filtered = newValue.filter { "0123456789,".contains($0) }
                        if filtered != newValue {
                            // 숫자와 콤마가 아닌 문자가 포함되어 있으면 필터링된 값으로 교체
                            onAmountChange(filtered, index)
                        }
                    }
                    .onChange(of: group.formattedAmount) { oldValue, newValue in // 사용자가 금액을 입력하거나 변경할 때마다 실행
                        // 부모 뷰에 금액 변경을 알리기 위해 콜백 함수 호출 (새로운 금액 값과 카드 인덱스 전달)
                        onAmountChange(newValue, index)
                    }
                
                Spacer() // 남은 공간을 차지하여 '원' 단위 표시를 오른쪽으로 밀어냄
                
                // 통화 단위 표시
                Text("원")
                    .font(.system(size: 20, weight: .medium)) // 20pt 크기의 중간 굵기 폰트
                    .foregroundColor(.secondary) // 보조 텍스트 색상으로 설정하여 주요 금액 숫자와 구분
            }
            .padding(.horizontal, 16) // 좌우에 16pt의 안쪽 여백 적용
            .padding(.vertical, 16) // 상하에 16pt의 안쪽 여백 적용
            .background( // 입력 필드의 배경 및 테두리 스타일 설정
                RoundedRectangle(cornerRadius: 8) // 모서리가 8pt만큼 둥근 사각형
                    .fill(Color(.systemGray6)) // 시스템 회색6 색상으로 기본 배경 설정
                    .overlay( // 기본 배경 위에 테두리를 오버레이로 추가
                        RoundedRectangle(cornerRadius: 8) // 동일한 모양의 사각형
                            .stroke(
                                // 포커스 상태에 따라 테두리 색상을 조건부로 변경 (포커스 시 검은색, 아니면 투명)
                                isAmountFieldFocused ? Color.black : Color.clear,
                                lineWidth: 2 // 테두리 두께 2pt
                            )
                    )
            )
        }
    }
    
    /// 사용자가 빠르게 금액을 선택할 수 있는 미리 정의된 금액 버튼들의 그리드
    /// 금액 입력 필드가 포커스되고 비어있을 때만 표시되어 사용자 편의성을 제공
    private var quickAmountGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) { // 3열 그리드로 배치, 각 열은 동일한 비율로 분할, 요소 간 8pt 간격
            ForEach(quickAmounts, id: \.self) { amount in // 미리 정의된 빠른 금액 배열을 순회
                Button(action: {
                    // 사용자가 빠른 금액을 선택했을 때의 처리
                    onApplyQuickAmount(amount, index) // 부모 뷰에 선택된 금액과 카드 인덱스 전달
                    isAmountFieldFocused = false // 키보드를 숨기기 위해 포커스 해제
                }) {
                    // 콤마가 포함된 형태로 금액을 포맷하여 표시 (예: "10,000원")
                    Text("\(FormatHelper.formatWithComma(amount))원")
                        .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
                        .foregroundColor(.primary) // 기본 텍스트 색상 사용
                        .padding(.horizontal, 12) // 좌우에 12pt의 안쪽 여백
                        .padding(.vertical, 8) // 상하에 8pt의 안쪽 여백
                        .background( // 버튼의 배경 스타일
                            RoundedRectangle(cornerRadius: 6) // 모서리가 6pt만큼 둥근 사각형
                                .fill(Color(.systemGray5)) // 시스템 회색5 색상으로 채우기
                        )
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top))) // 나타날 때 투명도 변화와 위에서 아래로 이동하는 애니메이션 효과 결합
    }
    
    /// 사용자가 지출에 대한 추가 정보나 설명을 입력할 수 있는 메모 영역 (선택사항)
    private var noteRow: some View {
        VStack(alignment: .leading, spacing: 8) { // 왼쪽 정렬로 세로 배치하되 요소 간 8pt 간격 설정
            // 섹션 제목 레이블
            Text("메모")
                .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
                .foregroundColor(.secondary) // 보조 텍스트 색상으로 설정
            
            // 메모 입력을 위한 텍스트필드
            TextField("메모 입력 (선택)", text: $group.note) // 선택사항임을 명시한 플레이스홀더, 메모 내용과 양방향 바인딩
                .font(.system(size: 16, weight: .medium)) // 16pt 크기의 중간 굵기 폰트
                .padding(.horizontal, 16) // 좌우에 16pt의 안쪽 여백
                .padding(.vertical, 12) // 상하에 12pt의 안쪽 여백
                .background( // 텍스트필드의 배경 스타일
                    RoundedRectangle(cornerRadius: 8) // 모서리가 8pt만큼 둥근 사각형
                        .fill(Color(.systemGray6)) // 시스템 회색6 색상으로 채우기
                )
        }
    }
    
    /// 추가적인 액션들을 제공하는 버튼 영역 (현재는 복사 기능만 제공)
    /// 편집 모드이고 카드가 여러 개일 때만 표시되어 필요한 경우에만 UI 복잡도를 증가시킴
    private var actionRow: some View {
        HStack(spacing: 12) { // 가로로 배치하되 요소 간 12pt 간격 설정
            // 현재 카드의 내용을 복사하여 새로운 카드를 생성하는 버튼
            Button("복사") {
                onDuplicate(index) // 부모 뷰에 현재 카드의 복사 요청 (카드 인덱스와 함께 전달)
            }
            .font(.system(size: 14, weight: .medium)) // 14pt 크기의 중간 굵기 폰트
            .foregroundColor(.blue) // 파란색으로 설정하여 액션 버튼임을 시각적으로 표현
            .padding(.horizontal, 16) // 좌우에 16pt의 안쪽 여백
            .padding(.vertical, 8) // 상하에 8pt의 안쪽 여백
            .background( // 버튼의 배경 스타일
                RoundedRectangle(cornerRadius: 6) // 모서리가 6pt만큼 둥근 사각형
                    .fill(Color.blue.opacity(0.1)) // 파란색을 10% 투명도로 적용하여 연한 파란색 배경 생성
            )
            
            Spacer() // 남은 가로 공간을 모두 차지 (향후 다른 액션 버튼들을 추가할 때를 대비한 공간 확보)
        }
    }
    
    /// 카드 전체의 배경 및 테두리 스타일을 정의하는 뷰
    /// 포커스 상태에 따라 시각적 피드백을 제공하여 현재 활성화된 카드를 명확히 구분
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12) // 모서리가 12pt만큼 둥근 사각형 (카드 형태의 둥근 모서리)
            .fill(Color(.systemBackground)) // 시스템 배경색으로 채우기 (라이트/다크 모드에 자동으로 적응)
            .overlay( // 기본 배경 위에 테두리를 오버레이로 추가
                RoundedRectangle(cornerRadius: 12) // 동일한 모양과 크기의 사각형
                    .stroke( // 테두리만 그리기 (내부는 투명)
                        // 포커스 상태에 따라 테두리 색상을 조건부로 변경 (포커스 시 검은색, 아니면 연한 회색)
                        isFocused ? Color.black : Color(.systemGray5),
                        lineWidth: isFocused ? 2 : 1 // 포커스 상태에 따라 테두리 두께도 변경 (포커스 시 2pt, 아니면 1pt)
                    )
            )
            .shadow( // 카드에 그림자 효과 적용
                color: Color.black.opacity(isFocused ? 0.1 : 0.05), // 포커스 상태에 따라 그림자 진하기 변경 (포커스 시 더 진함)
                radius: isFocused ? 8 : 4, // 포커스 상태에 따라 그림자 흐림 반경 변경 (포커스 시 더 넓게)
                x: 0, // 가로 방향 그림자 오프셋 없음 (중앙 정렬)
                y: 2  // 세로 방향으로 2pt 아래쪽에 그림자 생성 (자연스러운 떠 있는 효과)
            )
    }
}
