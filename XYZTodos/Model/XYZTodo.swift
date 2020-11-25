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
    
    var group = ""
    var sequenceNr = 0
    var detail = ""
    var complete = false
    
    
    // MARK: - function
    
    init(group: String?,
         sequenceNr: Int,
         detail: String,
         complete: Bool,
         context: NSManagedObjectContext?) {

        let entity = NSEntityDescription.entity(forEntityName: XYZTodo.type, in: context!)!
        
        super.init(entity: entity, insertInto: context!)
        
        self.setValue(group, forKey: XYZTodo.group)
        self.setValue(sequenceNr, forKey: XYZTodo.sequenceNr)
        self.setValue(detail, forKey: XYZTodo.detail)
        self.setValue(complete, forKey: XYZTodo.complete)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {

        super.init(entity: entity, insertInto: context)
    }
}
