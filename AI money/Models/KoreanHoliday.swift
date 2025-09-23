//
//  KoreanHoliday.swift
//  AI money
//
//  Created by 조준희 on 9/23/25.
//

import Foundation

enum HolidayType {
    case national      // 국경일 (빨간날)
    case substitute    // 대체공휴일
    case traditional   // 전통 명절
    case memorial      // 기념일
}

struct KoreanHoliday {
    let name: String
    let date: Date
    let isRecurring: Bool
    let type: HolidayType
}

class KoreanHolidayService {
    static let shared = KoreanHolidayService()
    private var holidays: [KoreanHoliday] = []
    
    private init() {
        setupHolidays()
    }
    
    func isHoliday(date: Date) -> KoreanHoliday? {
        let calendar = Calendar.current
        return holidays.first { holiday in
            if holiday.isRecurring {
                let holidayComponents = calendar.dateComponents([.month, .day], from: holiday.date)
                let dateComponents = calendar.dateComponents([.month, .day], from: date)
                return holidayComponents.month == dateComponents.month &&
                       holidayComponents.day == dateComponents.day
            } else {
                return calendar.isDate(holiday.date, inSameDayAs: date)
            }
        }
    }
    
    func getHolidays(for year: Int) -> [KoreanHoliday] {
        let calendar = Calendar.current
        return holidays.filter { holiday in
            if holiday.isRecurring {
                return true // 매년 반복되는 공휴일
            } else {
                let holidayYear = calendar.component(.year, from: holiday.date)
                return holidayYear == year
            }
        }
    }
    
    private func setupHolidays() {
        let calendar = Calendar.current
        
        // 매년 반복되는 고정 공휴일들
        let recurringHolidays = [
            // 1월
            ("신정", 1, 1, HolidayType.national),
            
            // 3월
            ("3·1절", 3, 1, HolidayType.national),
            
            // 5월
            ("어린이날", 5, 5, HolidayType.national),
            ("어버이날", 5, 8, HolidayType.memorial),
            ("스승의 날", 5, 15, HolidayType.memorial),
            
            // 6월
            ("현충일", 6, 6, HolidayType.memorial),
            
            // 8월
            ("광복절", 8, 15, HolidayType.national),
            
            // 10월
            ("개천절", 10, 3, HolidayType.national),
            ("한글날", 10, 9, HolidayType.national),
            
            // 12월
            ("크리스마스", 12, 25, HolidayType.national)
        ]
        
        for (name, month, day, type) in recurringHolidays {
            if let date = calendar.date(from: DateComponents(year: 2024, month: month, day: day)) {
                holidays.append(KoreanHoliday(name: name, date: date, isRecurring: true, type: type))
            }
        }
        
        // 연도별 특정 공휴일들 (음력 기반이나 특별한 날들)
        setupLunarHolidays()
        setupSpecialHolidays()
    }
    
    private func setupLunarHolidays() {
        // 음력 기반 공휴일들 (매년 날짜가 바뀜)
        // 실제 구현시에는 음력-양력 변환 라이브러리나 API를 사용해야 함
        // 여기서는 2025년 기준으로 예시
        let calendar = Calendar.current
        
        let lunarHolidays2025 = [
            ("설날", 1, 29, HolidayType.traditional), // 2025년 설날
            ("설날 연휴", 1, 30, HolidayType.traditional),
            ("설날 연휴", 1, 31, HolidayType.traditional),
            ("부처님오신날", 5, 5, HolidayType.traditional), // 2025년 부처님오신날
            ("추석", 10, 6, HolidayType.traditional), // 2025년 추석
            ("추석 연휴", 10, 7, HolidayType.traditional),
            ("추석 연휴", 10, 8, HolidayType.traditional)
        ]
        
        for (name, month, day, type) in lunarHolidays2025 {
            if let date = calendar.date(from: DateComponents(year: 2025, month: month, day: day)) {
                holidays.append(KoreanHoliday(name: name, date: date, isRecurring: false, type: type))
            }
        }
    }
    
    private func setupSpecialHolidays() {
        let calendar = Calendar.current
        
        // 특별 공휴일들
        let specialHolidays = [
            ("대통령 선거일", 2027, 3, 9, HolidayType.national), // 예시
        ]
        
        for (name, year, month, day, type) in specialHolidays {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                holidays.append(KoreanHoliday(name: name, date: date, isRecurring: false, type: type))
            }
        }
    }
}
