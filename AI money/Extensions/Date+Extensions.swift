//
//  Date+Extensions.swift
//  AI money
//
//  Created by 조준희 on 9/8/25.
//

import Foundation

extension Date {
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
}
