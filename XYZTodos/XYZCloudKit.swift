//
//  XYZCloudKit.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 1/5/21.
//

import Foundation
import CloudKit

struct XYZCloudTodo {
        
    var recordId: String?
    var group: String?
    var sequenceNr: Int?
    var detail: String?
    var complete: Bool?
    var time: Date?
    var timeOn: Bool?
}

struct XYZCloudCacheData {

    let group: String
    var todos: [XYZCloudTodo]?
    var lastReadFromCloud: Date?

    var writtingPendingTodos: [XYZCloudTodo]?
    var lastWrittenToWrite: Date?
    
    var deletedRecordIds = [String]()
    
    mutating func writeToiCloud() {

        let group = self.group
        // write to icloud
        printDebug(todos: writtingPendingTodos)

        if let writtingPendingTodos = writtingPendingTodos
        //   ,!writtingPendingTodos.isEmpty
        {
            
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            
            let recordZone = CKRecordZone(zoneName: XYZTodo.type)
            let groupRecordId = CKRecord.ID(recordName: group, zoneID: recordZone.zoneID)
 
            let op = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [groupRecordId])
            op.savePolicy = .allKeys
            op.completionBlock = {
            
                let groupRecord = CKRecord(recordType: "XYZTodoGroup", recordID: groupRecordId)
                groupRecord["group"] = group
                
                let op = CKModifyRecordsOperation(recordsToSave: [groupRecord], recordIDsToDelete: [])
                op.savePolicy = .allKeys
                op.completionBlock = {
                    
                    print("******** todogroup completionBlock and add todos")
                    let ckreference = CKRecord.Reference(recordID: groupRecordId, action: .deleteSelf)
                    
                    var records = [CKRecord]()
                    for todo in writtingPendingTodos {
                        
                        let ckrecordId = CKRecord.ID(recordName: todo.recordId!, zoneID: recordZone.zoneID)

                        let record = CKRecord(recordType: XYZTodo.type, recordID: ckrecordId)
                        record[XYZTodo.group] = todo.group
                        record[XYZTodo.sequenceNr] = todo.sequenceNr
                        record[XYZTodo.detail] = todo.detail
                        record[XYZTodo.complete] = todo.complete
                        record[XYZTodo.time] = todo.time
                        record[XYZTodo.timeOn] = todo.timeOn
                        record["todogroup"] = ckreference
        
                        records.append(record)
                    }
                    
                    let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: [])
                    op.savePolicy = .allKeys

                    op.completionBlock = {
                        
                        print("******** todos completionBlock")
                    }
                    
                    database.add(op)
                }
                
                database.add(op)
            }
            
            database.add(op)
        }
        
        todos = writtingPendingTodos
        writtingPendingTodos = []
        lastWrittenToWrite = Date()
    }
    
    mutating func readFromiCloud(of group: String, changeToken: CKServerChangeToken? = nil) {
        
        lastReadFromCloud = Date()
    }
    
    func printDebug(todos: [XYZCloudTodo]? = nil) {
        
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
    
    static func intialize(groups: [String]) {

        for g in groups {
            
            let cacheData = XYZCloudCacheData(group: g)
            dataDictionary[g] = cacheData
        }
        
        let recordZone = CKRecordZone(zoneName: XYZTodo.type)
        
        let op = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: nil)
        
        op.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
            
            print("---- CKModifyRecordZonesOperation is done")
            
            if let error = error {
                
                print("Error in CKModifyRecordZonesOperation: \(error)")
            }
        }
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.add(op)
    }
    
    static func write(todos: [XYZCloudTodo], of identifier: String) {
        
        var cacheData = dataDictionary[identifier]
        
        if cacheData == nil {
            
            cacheData = XYZCloudCacheData(group: identifier)
        }
        
        dataDictionary[identifier] = cacheData
        
        cacheData!.writtingPendingTodos = todos
        
        dataDictionary[identifier] = cacheData
        
        cacheData?.writeToiCloud()
        
        dataDictionary[identifier] = cacheData
    }
    
    static func readFromiCloud(completion: @escaping () -> Void) {
        
        // not using change token
        var changeToken: CKServerChangeToken? = nil
        let defaults = UserDefaults.standard;
        
        if let changeTokenData = defaults.value(forKey: "LastChangeToken") as? Data {
            
            changeToken = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData) as? CKServerChangeToken
        }
        
        let recordZone = CKRecordZone(zoneName: XYZTodo.type)
        var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
        let option = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        option.previousServerChangeToken = changeToken
        optionsByRecordZoneID[recordZone.zoneID] = option
        
        let op = CKFetchRecordZoneChangesOperation(recordZoneIDs: [recordZone.zoneID], configurationsByRecordZoneID: optionsByRecordZoneID)
        op.recordChangedBlock = { (record) in
            
            print("********* recordChangedBlock")
            
            if record.recordType == XYZTodo.type {
            
                let group = record[XYZTodo.group] as? String ?? ""
                let sequenceNr = record[XYZTodo.sequenceNr] as? Int ?? 0
                let detail = record[XYZTodo.detail] as? String ?? ""
                let complete = record[XYZTodo.complete] as? Bool ?? false
                let time = record[XYZTodo.time] as? Date ?? Date()
                let timeOn = record[XYZTodo.timeOn] as? Bool ?? false

                if var data = dataDictionary[group] {
                
                    if data.todos == nil {
                        
                        data.todos = [XYZCloudTodo]()
                    }
                    
                    if let index = data.todos?.firstIndex(where: { (todo) -> Bool in
                        
                        return todo.recordId == record.recordID.recordName
                    }) {
                        
                        data.todos?.remove(at: index)
                    }
                    
                    let newTodo = XYZCloudTodo(recordId: record.recordID.recordName, group: group, sequenceNr: sequenceNr, detail: detail, complete: complete, time: time, timeOn: timeOn)
                    
                    data.todos?.append(newTodo)                    
                    dataDictionary[group] = data
                }
            }
        }
        
        op.recordWithIDWasDeletedBlock = { (recordId, recordType) in
        
            let tokens = recordId.recordName.split(separator: "-")
            let group = String(tokens[0])
            var cacheData = dataDictionary[group]
            
            cacheData?.deletedRecordIds.append(recordId.recordName)
            dataDictionary[group] = cacheData
        }
        
        op.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
         
            print("********* recordZoneChangeTokensUpdatedBlock")
        }
        
        op.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
           
            print("********* recordZoneFetchCompletionBlock")
            
            let data = try! NSKeyedArchiver.archivedData(withRootObject: changeToken!, requiringSecureCoding: false)
            defaults.setValue(data, forKey: "LastChangeToken")
        }
        
        op.fetchRecordZoneChangesCompletionBlock = { (error) in

            print("********* fetchRecordZoneChangesCompletionBlock")
            completion()
        }
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.add(op)
    }
    
    static func read(of identifier: String, completion: @escaping ([XYZCloudTodo]?) -> Void )  {

        var cacheData = dataDictionary[identifier]
        
        if cacheData == nil {
        
            cacheData = XYZCloudCacheData(group: identifier)
        }
    
        cacheData?.deletedRecordIds.removeAll()
        dataDictionary[identifier] = cacheData
    
        
        let defaults = UserDefaults.standard;
        defaults.setValue(Data(), forKey: "LastChangeToken")
        
        readFromiCloud {
            
            print("-------- complete")
            var result: [XYZCloudTodo]? = nil
            let cacheData = dataDictionary[identifier]
            
            if let todos = cacheData?.todos {
                
                result = todos
            } else if !cacheData!.deletedRecordIds.isEmpty {
                
                result = [XYZCloudTodo]()
            }
            
            print("-------- \(cacheData)")
            
            completion(result)
        }
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

