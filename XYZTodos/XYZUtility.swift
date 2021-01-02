//
//  XYZUtility.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//


import Foundation

// MARK: - Global Property
let appScheme = "xyztodot"
let httpUrlPrefix = appScheme + "://"
let httpUrlWidgetHost = "widget"
let appGroup = "group.com.XYZTodos"
let databaseName = "XYZTodos"

let other = "Other"

let otherLocalized = other.localized()

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
    
    static var allCasesStringStartWithSelectedDayOfWeek: [String] {
        
        return DayOfWeek.allCasesStartWithSelectedDayOfWeek.map { (dow) -> String in
        
            return dow.rawValue
        }
    }
    
    static var allCasesStringLocalizedStartWithSelectedDayOfWeek: [String] {
        
        return DayOfWeek.allCasesStartWithSelectedDayOfWeek.map { (dow) -> String in
        
            return dow.rawValue.localized()
        }
    }
    
    static var allCasesStartWithSelectedDayOfWeek: [DayOfWeek] {
        
        var hitStartOfTheWeek = false
        var daysOfWeek = [DayOfWeek]()
        var nextIndex = 0
        for dayOfWeek in DayOfWeek.allCases {

            if hitStartOfTheWeek
                || dayOfWeek.weekDayNr == firstWeekDay {
                
                hitStartOfTheWeek = true
                
                daysOfWeek.insert(dayOfWeek, at: nextIndex)
                nextIndex = nextIndex + 1
            } else {
                
                daysOfWeek.append(dayOfWeek)
            }
        }
        
        return daysOfWeek
    }
} // enum DayOfWeek

extension DateFormatter {
    
    func stringWithShortTime(from date:Date) -> String {
        
        self.dateStyle = .none
        self.timeStyle = .short
    
        return self.string(from: date)
    }
}

extension String {
    
    func localized() -> String {
        
        return NSLocalizedString(self, comment:"")
    }
}

extension Date {
    
    static func nextHour(hour: Int = 1) -> Date {
        
        let nowComponents = Calendar.current.dateComponents([.day, .month, .year, .hour], from: Date())
        let now = Calendar.current.date(from: nowComponents)
        let afterHour = Calendar.current.date(byAdding: .hour, value: hour, to: now!)
        
        return afterHour!
    }
    
    static func nextMinute(minute: Int = 1) -> Date {
        
        let nowComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: Date())
        let now = Calendar.current.date(from: nowComponents)
        let afterMinute = Calendar.current.date(byAdding: .minute, value: minute, to: now!)
        
        return afterMinute!
    }
    
    static func nextSecond(second: Int = 1) -> Date {
        
        let nowComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: Date())
        let now = Calendar.current.date(from: nowComponents)
        let afterSecond = Calendar.current.date(byAdding: .second, value: second, to: now!)
        
        return afterSecond!
    }
    
    func getTimeOfToday() -> Date {
        
        var today = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let time =  Calendar.current.dateComponents([.hour, .minute], from: self)

        today.setValue(time.minute, for: .minute)
        today.setValue(time.hour, for: .hour)
        
        return Calendar.current.date(from: today)!
    }
}

public extension URL {

    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName)")
    }
}
