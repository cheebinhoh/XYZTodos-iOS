//
//  XYZGlobal.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 11/1/20.
//

import Foundation
import CoreData

@objc(XYZGlobal)
class XYZGlobal : NSManagedObject {
    
    // MARK: - static property
    
    static let type = "XYZGlobal"
    static let dow = "dow"

    
    // MARK: - property
    
    var dow = ""
    
    
    // MARK: - function
    
    init(dow: String,
         context: NSManagedObjectContext?) {

        let entity = NSEntityDescription.entity(forEntityName: XYZGlobal.type,
                                                in: context!)!
        
        super.init(entity: entity, insertInto: context!)
        
        self.setValue(dow, forKey: XYZGlobal.dow)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {

        super.init(entity: entity, insertInto: context)
    }
}
