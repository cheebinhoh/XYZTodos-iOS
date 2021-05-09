//
//  XYZCoreData.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 1/5/21.
//
//  Copyright © 2020 - 2021 Chee Bin Hoh. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Core data and managed context

func managedContext() -> NSManagedObjectContext? {
  
    return persistentContainer.viewContext
}

func saveManageContext() {
    
    let aContext = managedContext()
    
    if aContext!.hasChanges {
    
        do {
            
            try aContext?.save()
        } catch let nserror as NSError {
            
            fatalError("Exception: Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

func loadTodosFromManagedContext(_ aContext: NSManagedObjectContext?) -> [XYZTodo]? {
    
    var output: [XYZTodo]?
    let fetchRequest = NSFetchRequest<XYZTodo>(entityName: XYZTodo.type)
    
    if let unsorted = try? aContext?.fetch(fetchRequest) {
        
        output = sortTodos(todos: unsorted)
    }

    return output
}

func loadGlobalFromManagedContext() -> XYZGlobal? {
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZGlobal>(entityName: XYZGlobal.type)
    
    guard let output = try? aContext?.fetch(fetchRequest) else {
        
        fatalError("Exception: error in fetchRequest XYZGlobal")
    }

    var global = output.first
    if nil == global {
        
        global = XYZGlobal(dow: "", context: managedContext())
        saveManageContext()
    }
    
    return global
}


// MARK: - Miscallenous

func printTodos(todos: [XYZTodo]) {
    
    print("---- print todos")
    
    for todo in todos {
        
        let group = todo.group
        let sequenceNr = todo.sequenceNr
        let detail = todo.detail
        let timeOn = todo.timeOn
        let time = todo.time
        let complete = todo.complete
        
        print("group = \(group), sequenceNr = \(sequenceNr), detail = \(detail), timeOn = \(timeOn), time = \(time), complete = \(complete)")
    }
}

func printGlobal(global: XYZGlobal) {
    
    print("---- print global")
    
    let dow = global.dow
    print("dow = ", dow)
}
