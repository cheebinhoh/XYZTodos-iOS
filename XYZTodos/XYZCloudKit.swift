//
//  XYZCloudKit.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 1/5/21.
//

import Foundation
import CloudKit

struct XYZCloudTodo {
        
    var group: String?
    var sequenceNr: Int?
    var detail: String?
    var complete: Bool?
    var time: Date?
    var timeOn: Bool?
}

struct XYZCloudCacheData {

    var todos: [XYZCloudTodo]?
    var lastReadFromCloud: Date?

    var writtingPendingTodos: [XYZCloudTodo]?
    var lastWrittenToWrite: Date?
    
    mutating func writeToiCloud() {
        
        // write to icloud
        todos = writtingPendingTodos
        writtingPendingTodos = []
        lastWrittenToWrite = Date()
    }
    
    mutating func readFromiCloud(of group: String) {
        
        lastReadFromCloud = Date()
    }
    
    func printDebug() {
        
        print("-------- start of XYZCloudCacheData.printDebug")
        print("-------- lastReadFromCloud = \(String(describing: lastReadFromCloud))")
        print("-------- lastWrittenToWrite = \(String(describing: lastWrittenToWrite))")
        
        if let todos = todos, !todos.isEmpty {
            
            for todo in todos {
                
                print("-------- todo = \(todo)")
            }
        } else {
            
            print("-------- no todo")
        }
        
        print("-------- end of XYZCloudCacheData.printDebug")
    }
}

struct XYZCloudCache {
    
    static var dataDictionary = [String : XYZCloudCacheData]()
    
    static func write(todos: [XYZCloudTodo], of identifier: String) {
        
        var cacheData = dataDictionary[identifier]
        
        if cacheData == nil {
            
            cacheData = XYZCloudCacheData()
        }
    
        cacheData!.writtingPendingTodos = todos
        
        dataDictionary[identifier] = cacheData
        
        cacheData?.writeToiCloud()
        
        dataDictionary[identifier] = cacheData
    }
    
    static func read(of identifier: String) -> [XYZCloudTodo]? {
     
        var cacheData = dataDictionary[identifier]
        
        if cacheData == nil {
        
            cacheData = XYZCloudCacheData()
        }
        
        cacheData?.readFromiCloud(of: identifier)
        
        dataDictionary[identifier] = cacheData
        
        return cacheData?.todos
    }
    
    static func printDebug() {
        
        print("---- start of XYZCloudCache.printDebug")
        for (key, dataCache) in dataDictionary {
            
            print("-------- identifier = \(key)")
            dataCache.printDebug()
            
            print("")
        }
        
        print("---- end of XYZCloudCache.printDebug")
    }
}

