//
//  KoreanHoliday.swift
//  AI money
//
//  Created by 조준희 on 9/23/25.
//

import Foundation

// 한국 공휴일의 종류를 정의하는 열거형
enum HolidayType {
    case national      // 국경일 (빨간날) - 국가 법정공휴일
    case substitute    // 대체공휴일 - 공휴일이 주말과 겹칠 때 대체되는 휴일
    case traditional   // 전통 명절 - 설날, 추석 등 전통적인 명절
    case memorial      // 기념일 - 어버이날, 스승의 날 등
}

// 한국 공휴일 정보를 담는 구조체
struct KoreanHoliday {
    let name: String           // 공휴일 이름 (예: "신정", "추석")
    let date: Date             // 공휴일 날짜
    let isRecurring: Bool      // 매년 반복되는 공휴일인지 여부 (true: 매년 같은 날, false: 특정 연도만)
    let type: HolidayType      // 공휴일 종류
}

// 한국 공휴일을 관리하는 싱글톤 서비스 클래스
class KoreanHolidayService {
    static let shared = KoreanHolidayService()  // 싱글톤 인스턴스 - 앱 전체에서 하나만 생성
    private var holidays: [KoreanHoliday] = []  // 모든 공휴일 데이터를 저장하는 배열
    
    // private 초기화 - 외부에서 인스턴스 생성 불가 (싱글톤 패턴)
    private init() {
        setupHolidays() // 초기화 시 공휴일 데이터 설정
    }
    
    // 특정 날짜가 공휴일인지 확인하는 메서드
    func isHoliday(date: Date) -> KoreanHoliday? {
        let calendar = Calendar.current // 현재 캘린더 시스템 사용
        return holidays.first { holiday in // 공휴일 배열에서 첫 번째로 일치하는 항목 찾기
            if holiday.isRecurring { // 매년 반복되는 공휴일인 경우
                // 입력받은 날짜와 공휴일의 월, 일만 비교
                let holidayComponents = calendar.dateComponents([.month, .day], from: holiday.date)
                let dateComponents = calendar.dateComponents([.month, .day], from: date)
                return holidayComponents.month == dateComponents.month &&
                       holidayComponents.day == dateComponents.day
            } else { // 특정 연도의 공휴일인 경우
                // 정확한 날짜 비교 (연도까지 포함)
                return calendar.isDate(holiday.date, inSameDayAs: date)
            }
        }
    }
    
    // 특정 연도의 모든 공휴일을 반환하는 메서드
    func getHolidays(for year: Int) -> [KoreanHoliday] {
        let calendar = Calendar.current // 현재 캘린더 시스템 사용
        return holidays.filter { holiday in // 공휴일 배열을 필터링
            if holiday.isRecurring { // 매년 반복되는 공휴일
                return true // 매년 반복되므로 모든 연도에 해당
            } else { // 특정 연도의 공휴일
                let holidayYear = calendar.component(.year, from: holiday.date) // 공휴일의 연도 추출
                return holidayYear == year // 요청된 연도와 일치하는지 확인
            }
        }
    }
    
    // 모든 공휴일 데이터를 초기화하는 메서드
    private func setupHolidays() {
        let calendar = Calendar.current // 현재 캘린더 시스템 사용
        
        // 매년 반복되는 고정 공휴일들 (양력 기준)
        let recurringHolidays = [
            // 1월
            ("신정", 1, 1, HolidayType.national),      // 신정 - 1월 1일
            
            // 3월
            ("3·1절", 3, 1, HolidayType.national),    // 삼일절 - 3월 1일
            
            // 5월
            ("어린이날", 5, 5, HolidayType.national),   // 어린이날 - 5월 5일
            ("어버이날", 5, 8, HolidayType.memorial),   // 어버이날 - 5월 8일 (기념일)
            ("스승의 날", 5, 15, HolidayType.memorial), // 스승의 날 - 5월 15일 (기념일)
            
            // 6월
            ("현충일", 6, 6, HolidayType.memorial),     // 현충일 - 6월 6일
            
            // 8월
            ("광복절", 8, 15, HolidayType.national),   // 광복절 - 8월 15일
            
            // 10월
            ("개천절", 10, 3, HolidayType.national),   // 개천절 - 10월 3일
            ("한글날", 10, 9, HolidayType.national),   // 한글날 - 10월 9일
            
            // 12월
            ("크리스마스", 12, 25, HolidayType.national) // 크리스마스 - 12월 25일
        ]
        
        // 반복 공휴일 배열을 순회하며 KoreanHoliday 객체 생성
        for (name, month, day, type) in recurringHolidays {
            // 2024년을 기준으로 날짜 객체 생성 (매년 반복되므로 기준년도는 임의)
            if let date = calendar.date(from: DateComponents(year: 2024, month: month, day: day)) {
                holidays.append(KoreanHoliday(name: name, date: date, isRecurring: true, type: type))
            }
        }
        
        // 음력 기반 공휴일과 특별 공휴일 설정
        setupLunarHolidays()  // 음력 공휴일 설정
        setupSpecialHolidays() // 특별 공휴일 설정
    }
    
    // 음력 기반 공휴일을 설정하는 메서드 (설날, 추석 등)
    private func setupLunarHolidays() {
        // 음력 기반 공휴일들 (매년 날짜가 바뀜)
        // 실제 구현시에는 음력-양력 변환 라이브러리나 API를 사용해야 함
        // 여기서는 2025년 기준으로 예시 데이터 하드코딩
        let calendar = Calendar.current // 현재 캘린더 시스템 사용
        
        // 2025년 음력 공휴일 데이터 (실제로는 매년 계산되어야 함)
        let lunarHolidays2025 = [
            ("설날", 1, 29, HolidayType.traditional),        // 2025년 설날 - 1월 29일
            ("설날 연휴", 1, 30, HolidayType.traditional),   // 설날 연휴 - 1월 30일
            ("설날 연휴", 1, 31, HolidayType.traditional),   // 설날 연휴 - 1월 31일
            ("부처님오신날", 5, 5, HolidayType.traditional), // 2025년 부처님오신날 - 5월 5일
            ("추석", 10, 6, HolidayType.traditional),        // 2025년 추석 - 10월 6일
            ("추석 연휴", 10, 7, HolidayType.traditional),   // 추석 연휴 - 10월 7일
            ("추석 연휴", 10, 8, HolidayType.traditional)    // 추석 연휴 - 10월 8일
        ]
        
        // 음력 공휴일 배열을 순회하며 KoreanHoliday 객체 생성
        for (name, month, day, type) in lunarHolidays2025 {
            // 2025년 특정 날짜로 Date 객체 생성
            if let date = calendar.date(from: DateComponents(year: 2025, month: month, day: day)) {
                // isRecurring: false - 매년 날짜가 달라지므로 반복되지 않음
                holidays.append(KoreanHoliday(name: name, date: date, isRecurring: false, type: type))
            }
        }
    }
    
    // 특별 공휴일을 설정하는 메서드 (선거일 등)
    private func setupSpecialHolidays() {
        let calendar = Calendar.current // 현재 캘린더 시스템 사용
        
        // 특별 공휴일들 (특정 연도에만 해당)
        let specialHolidays = [
            ("대통령 선거일", 2027, 3, 9, HolidayType.national), // 예시: 2027년 대통령 선거일
        ]
        
        // 특별 공휴일 배열을 순회하며 KoreanHoliday 객체 생성
        for (name, year, month, day, type) in specialHolidays {
            // 특정 연도의 특정 날짜로 Date 객체 생성
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                // isRecurring: false - 특정 연도에만 해당하므로 반복되지 않음
                holidays.append(KoreanHoliday(name: name, date: date, isRecurring: false, type: type))
            }
        }
    }
}
