//
//  XYZUtility.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//

import Foundation

enum DayOfWeek: String, CaseIterable {

    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
    
    var index: Int {
        
        return DayOfWeek.allCases.firstIndex(of: self)!
    }
}

extension String {
    
    func localized() -> String {
        
        return NSLocalizedString(self, comment:"")
    }
}
