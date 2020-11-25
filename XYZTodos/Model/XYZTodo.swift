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
    
    // MARK: - function
    
    init(group: String?,
         sequenceNr: Int,
         detail: String,
         complete: Bool,
         context: NSManagedObjectContext?) {

        let entity = NSEntityDescription.entity(forEntityName: XYZTodo.type, in: context!)!
        
        super.init(entity: entity, insertInto: context!)
    
        self.group = group ?? ""
        self.sequenceNr = sequenceNr
        self.detail = detail
        self.complete = complete
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {

        super.init(entity: entity, insertInto: context)
    }
}
