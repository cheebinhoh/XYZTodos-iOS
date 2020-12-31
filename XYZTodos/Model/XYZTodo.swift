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
