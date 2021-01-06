//
//  XYZRoot.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/31/20.
//

import Foundation
import CoreData

@objc(XYZTodo)
class XYZTodo : NSManagedObject {
    
    
    // MARK: - static property
    
    static let type = "XYZTodo"
    static let group = "group"
    static let sequenceNr = "sequenceNr"
    static let detail = "detail"
    static let complete = "complete"
    static let time = "time"
    static let timeOn = "timeOn"
    static let timeReschedule = "timeReschedule"
    
    
    // MARK: - property
    var recordId: String {
    
        return "\(group)-\(sequenceNr)"
    }
    
    var group: String {
        
        get {
            
            return self.value(forKey: XYZTodo.group) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZTodo.group)
        }
    }
    
    var sequenceNr: Int {
        
        get {
            
            return self.value(forKey: XYZTodo.sequenceNr) as? Int ?? 0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZTodo.sequenceNr)
        }
    }
    
    var detail: String {
        
        get {
            
            return self.value(forKey: XYZTodo.detail) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZTodo.detail)
        }
    }
    
    var complete: Bool {
        
        get {
            
            return self.value(forKey: XYZTodo.complete) as? Bool ?? false
        }
        
        set {
         
            self.setValue(newValue, forKey: XYZTodo.complete)
        }
    }
    
    var time: Date {
        
        get {
            
            return self.value(forKey: XYZTodo.time) as? Date ?? Date.nextHour()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZTodo.time)
        }
    }
    
    var timeOn: Bool {
        
        get {
            
            return self.value(forKey: XYZTodo.timeOn) as? Bool ?? false
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZTodo.timeOn)
        }
    }
    
    // timeReschedule
    var timeReschedule: Date? {
        
        get {
            
            return self.value(forKey: XYZTodo.timeReschedule) as? Date
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZTodo.timeReschedule)
        }
    }
    
    
    // MARK: - function
    
    init(group: String?,
         sequenceNr: Int,
         detail: String,
         timeOn: Bool,
         time: Date,
         complete: Bool,
         context: NSManagedObjectContext?) {

        let entity = NSEntityDescription.entity(forEntityName: XYZTodo.type, in: context!)!
        
        super.init(entity: entity, insertInto: context!)
    
        self.group = group ?? ""
        self.sequenceNr = sequenceNr
        self.detail = detail
        self.timeOn = timeOn
        self.time = time
        self.timeReschedule = nil
        self.complete = complete
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {

        super.init(entity: entity, insertInto: context)
    }
}

func sortTodos(todos: [XYZTodo]) -> [XYZTodo] {
    
    return todos.sorted { (todo1, todo2) -> Bool in

        let g1 = todo1.group
        let g2 = todo2.group
        let s1 = todo1.sequenceNr
        let s2 = todo2.sequenceNr
        
        let hasNoTime1 = todo1.timeOn ? 0 : 1
        let hasNoTime2 = todo2.timeOn ? 0 : 1
        var time1 = 5000
        var time2 = 5000
        
        if hasNoTime1 == 0 {
            
            let timeComponent = Calendar.current.dateComponents([.hour, .minute], from: todo1.time)
            time1 = timeComponent.hour! * 100 + timeComponent.minute!
        }
        
        if hasNoTime2 == 0 {
            
            let timeComponent = Calendar.current.dateComponents([.hour, .minute], from: todo2.time)
            time2 = timeComponent.hour! * 100 + timeComponent.minute!
        }

        let dow1Index = ( DayOfWeek(rawValue: g1)?.weekDayNr ) ?? DayOfWeek.lastWeekDayNr + 1
        let dow2Index = ( DayOfWeek(rawValue: g2)?.weekDayNr ) ?? DayOfWeek.lastWeekDayNr + 1
           
        var swap = dow1Index < dow2Index
        
        if !swap && dow1Index == dow2Index {
            
            swap = hasNoTime1 < hasNoTime2
            
            if !swap && hasNoTime1 == hasNoTime2 {
                
                swap = time1 < time2
                
                if !swap && time1 == time2 {
                    
                    swap = s1 < s2
                }
            }
        }
        
        return swap
    }
}
