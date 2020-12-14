//
//  XYZUtility.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//


import Foundation

// MARK: - Global Property

let other = "Other"
var todayDoW: DayOfWeek {
    
    let today = Date()
    let dateComponent = Calendar.current.dateComponents([.weekday], from: today)
    
    return DayOfWeek[dateComponent.weekday!]
}

var todayDowLocalized: String {
    
    let today = Date()
    let dateFormat = DateFormatter()

    dateFormat.dateFormat = "EEEE" // Day of week
    
    return dateFormat.string(from: today)
}

var firstWeekDayLocalized: String {
    
    return DayOfWeek[firstWeekDay].rawValue.localized()
}

var firstWeekDay: Int {
    
    get {
        
        let defaults = UserDefaults.standard;
        return defaults.value(forKey: "firstWeekDay") as? Int ?? Locale.current.calendar.firstWeekday
    }
    
    set {
        
        let defaults = UserDefaults.standard;
        defaults.setValue(newValue, forKey: "firstWeekDay")
    }
}

var enableNotification: Bool {
    
    get {
        
        let defaults = UserDefaults.standard;
        return defaults.value(forKey: "notification") as? Bool ?? false
    }
    
    set {
        
        let defaults = UserDefaults.standard;
        defaults.setValue(newValue, forKey: "notification")
    }
}

// MARK: - Type

enum DayOfWeek: String, CaseIterable {

    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    
    var weekDayNr: Int {
        
        return DayOfWeek.allCasesString.firstIndex(of: self.rawValue)! + 1
    }
    
    static subscript(index: Int) -> DayOfWeek {
        
        get {
            
            var dow = DayOfWeek.Saturday
            
            switch index {
                
                case 1:
                    dow = DayOfWeek.Sunday
                    
                case 2:
                    dow = DayOfWeek.Monday
                    
                case 3:
                    dow = DayOfWeek.Tuesday
                    
                case 4:
                    dow = DayOfWeek.Wednesday
                    
                case 5:
                    dow = DayOfWeek.Thursday
                    
                case 6:
                    dow = DayOfWeek.Friday
                    
                case 7:
                    dow = DayOfWeek.Saturday
                    
                default:
                    fatalError("Exception: out of bound in DayOfWeek subscript")
            }
            
            return dow
        }
    }
    
    static var lastWeekDayNr: Int {
        
        return DayOfWeek.allCasesString.count + 1
    }
    
    static var allCasesString: [String] {
        
        return DayOfWeek.allCases.map { (dow) -> String in
        
            return dow.rawValue
        }
    }
    
    static var allCasesStringLocalized: [String] {
        
        return DayOfWeek.allCases.map { (dow) -> String in
        
            return dow.rawValue.localized()
        }
    }
} // enum DayOfWeek

extension String {
    
    func localized() -> String {
        
        return NSLocalizedString(self, comment:"")
    }
}

extension Date {
    
}
