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
    
    mutating func writeToiCloud(completion: @escaping () -> Void) {

        let group = self.group

        if let writtingPendingTodos = writtingPendingTodos {
            
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
                    
                        completion()
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
    
    static func UpdateRecords(todos updateTodos: [XYZCloudTodo], completion: @escaping () -> Void) {
        
        var recordsToBeSaved = [CKRecord]()
        let recordZone = CKRecordZone(zoneName: XYZTodo.type)
        
        for todo in updateTodos {
            
            var cacheData = dataDictionary[todo.group!]
            
            if let index = cacheData?.todos?.firstIndex(where: {
                
                return $0.recordId == todo.recordId
            }) {
                
                cacheData?.todos?.remove(at: index)
            }
            
            cacheData?.lastWrittenToWrite = Date()
            cacheData?.todos?.append(todo)
            dataDictionary[todo.group!] = cacheData
            
            let groupRecordId = CKRecord.ID(recordName: todo.group!, zoneID: recordZone.zoneID)
            let ckreference = CKRecord.Reference(recordID: groupRecordId, action: .deleteSelf)
            let ckrecordId = CKRecord.ID(recordName: todo.recordId!, zoneID: recordZone.zoneID)

            let record = CKRecord(recordType: XYZTodo.type, recordID: ckrecordId)
            record[XYZTodo.group] = todo.group
            record[XYZTodo.sequenceNr] = todo.sequenceNr
            record[XYZTodo.detail] = todo.detail
            record[XYZTodo.complete] = todo.complete
            record[XYZTodo.time] = XYZTodo.time
            record[XYZTodo.timeOn] = XYZTodo.timeOn
            record["todogroup"] = ckreference
            
            recordsToBeSaved.append(record)
        }
        
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        /*
        database.save(recordsToBeSaved.first!) { (record, error) in
            
            if let error = error {
                
                print("-------->> \(error)")
            }
        }
        */

        let op = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: [])
        op.savePolicy = .allKeys
        op.completionBlock = {

            completion()
        }

        database.add(op)
    }
    
    static func intializeRecordZoneAndDo(completion: @escaping () -> Void) {
        
        if recordZoneInitialized {
         
            completion()
        } else {
            
            let recordZone = CKRecordZone(zoneName: XYZTodo.type)
            
            let op = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: nil)
            
            op.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                
                if let _ = error {
                    
                } else {
                    
                    recordZoneInitialized = true
                    completion()
                }
            }
            
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            
            database.add(op)
        }
    }
    
    static func intialize(groups: [String]) {

        for g in groups {
            
            let cacheData = XYZCloudCacheData(group: g)
            dataDictionary[g] = cacheData
        }
    }
    
    static func write(data: [String: [XYZCloudTodo]],
                      completion: @escaping () -> Void) {
        
        intializeRecordZoneAndDo {
         
            var numData = data.count
            
            for ( identifier, todos ) in data {
                
                var cacheData = dataDictionary[identifier]

                cacheData!.writtingPendingTodos = todos
                
                dataDictionary[identifier] = cacheData

                cacheData?.writeToiCloud(completion: {
                    
                    numData = numData - 1
                    if numData == 0 {
                        
                        completion()
                    }
                })
         
                dataDictionary[identifier] = cacheData // we reset writtingPendingTodos
            }
        }
    }
    
    static func readFromiCloud(completion: @escaping () -> Void) {
        
        var changeToken: CKServerChangeToken? = nil
        
        if let tokenData = lastChangeToken {
            
            changeToken = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(tokenData) as? CKServerChangeToken
        }
   
        let recordZone = CKRecordZone(zoneName: XYZTodo.type)
        var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
        let option = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        option.previousServerChangeToken = changeToken
        optionsByRecordZoneID[recordZone.zoneID] = option
        
        let op = CKFetchRecordZoneChangesOperation(recordZoneIDs: [recordZone.zoneID], configurationsByRecordZoneID: optionsByRecordZoneID)
        op.recordChangedBlock = { (record) in
            
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
            if var todos = cacheData?.todos,
               !todos.isEmpty {
                
                if let index = todos.firstIndex(where: { (todo) -> Bool in
                    
                    return todo.recordId == recordId.recordName
                }) {
                    
                    todos.remove(at: index)
                    
                    cacheData?.todos = todos
                }
            }
            
            dataDictionary[group] = cacheData
        }
        
        op.recordZoneChangeTokensUpdatedBlock = { (zoneId, changeToken, data) in
         
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: changeToken!, requiringSecureCoding: false)
            lastChangeToken = tokenData
        }
        
        op.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
           
        }
        
        op.fetchRecordZoneChangesCompletionBlock = { (error) in

            completion()
        }
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.add(op)
    }
    
    static func read(of identifiers: [String],
                     completion: @escaping (String, [XYZCloudTodo]?) -> Void )  {

        intializeRecordZoneAndDo {
                
            readFromiCloud {
                
                for identifier in identifiers {
                    
                    var result: [XYZCloudTodo]? = nil
                    var cacheData = dataDictionary[identifier]

                    if let todos = cacheData?.todos {
                        
                        result = todos
                    } else if !cacheData!.deletedRecordIds.isEmpty {
                        
                        result = [XYZCloudTodo]()
                    }
             
                    completion(identifier, result)
                    
                    cacheData?.deletedRecordIds = []
                    dataDictionary[identifier] = cacheData
                }
            }
        }
    }
    
    static func printDebug() {
        
        print("---- start of XYZCloudCache.printDebug")
        for (key, cacheData) in dataDictionary {
            
            print("-------- identifier = \(key)")
            cacheData.printDebug()
            
            print("")
        }
        
        print("---- end of XYZCloudCache.printDebug")
    }

    static func registeriCloudSubscription() {
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        let ckrecordzone = CKRecordZone(zoneName: XYZTodo.type)

        let id = "\((ckrecordzone.zoneID.zoneName))-\((ckrecordzone.zoneID.ownerName))"
        let fetchOp = CKFetchSubscriptionsOperation.init(subscriptionIDs: [id])
        
        fetchOp.fetchSubscriptionCompletionBlock = {(subscriptionDict, error) -> Void in
            
            let subscription = CKRecordZoneSubscription.init(zoneID: (ckrecordzone.zoneID), subscriptionID: id)
            let notificationInfo = CKSubscription.NotificationInfo()

            notificationInfo.alertBody = "XYZTodo has new update from iCloud"
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
            operation.qualityOfService = .utility
            operation.completionBlock = {
                
            }
            
            operation.modifySubscriptionsCompletionBlock = { subscriptions, strings, error in
                
                if let error = error {
                
                    print(">>>>>>>>>> error = \(error)")
                }
            }
            
            database.add(operation)
        }

        database.add(fetchOp)
    }
}
