//
//  AppDelegate.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/27/20.
//

import UIKit
import CoreData
import CloudKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var todos: [XYZTodo]?
    var global: XYZGlobal?
    
    func reconciliateData() {
        
        let globalDow = DayOfWeek(rawValue: global?.value(forKey: XYZGlobal.dow) as? String ?? "")
        let refreshTodos = nil == globalDow
                            || ( globalDow != todayDoW
                                    && todayDoW == DayOfWeek.Monday ) // New Monday :(

        if refreshTodos {
            
            for todo in todos! {
   
                todo.setValue(false, forKey: XYZTodo.complete)
            }
        }
        
        global!.setValue(todayDoW.rawValue, forKey: XYZGlobal.dow)
        
        saveManageContext()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        global = loadGlobalFromManagedContext();
        //printGlobal(global: global!)
        todos = loadTodosFromManagedContext()
        //printTodos(todos: todos!)
        
        // reconciliate
        self.reconciliateData()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "XYZTodos")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            
            do {
                
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

func managedContext() -> NSManagedObjectContext? {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    return appDelegate.persistentContainer.viewContext
}

func saveManageContext() {
    
    let aContext = managedContext()
    
    do {
        
        try aContext?.save()
    } catch let nserror as NSError {
        
        fatalError("Exception: Unresolved error \(nserror), \(nserror.userInfo)")
    }
}

func sortTodos(todos: [XYZTodo]) -> [XYZTodo] {
    
    return todos.sorted { (todo1, todo2) -> Bool in
    
        let g1 = todo1.value(forKey: XYZTodo.group) as? String ?? ""
        let g2 = todo2.value(forKey: XYZTodo.group) as? String ?? ""
        let s1 = todo1.value(forKey: XYZTodo.sequenceNr) as? Int ?? 0
        let s2 = todo2.value(forKey: XYZTodo.sequenceNr) as? Int ?? 0
        
        let dow1 = DayOfWeek(rawValue: g1)
        let dow2 = DayOfWeek(rawValue: g2)
           
        return dow1!.index <= dow2!.index
               && s1 <= s2
    }
}

func loadTodosFromManagedContext() -> [XYZTodo]? {
    
    var output: [XYZTodo]?
    
    let aContext = managedContext()
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

func deleteTodoFromManagedContext(group: String,
                                  sequenceNr: Int )
{
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    guard let index = appDelegate.todos?.firstIndex(where: {
        
    
        let gr = $0.value(forKey: XYZTodo.group) as? String ?? ""
        let seqNr = $0.value(forKey: XYZTodo.sequenceNr) as? Int ?? -1
        
        return group == gr && seqNr == sequenceNr
    }) else {
        
        return
    }

    
    let todo = appDelegate.todos?.remove(at: index)
    
    managedContext()?.delete(todo!)
    saveManageContext()
    
    printTodos(todos: appDelegate.todos!)
}

func moveTodoInManagedContext(fromIndex: Int,
                              toIndex: Int)
{
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    let removeTodo = appDelegate.todos?.remove(at: fromIndex)
    appDelegate.todos?.insert(removeTodo!, at: toIndex)
    
    var index = 0
    var lastGroup = ""
    for todo in appDelegate.todos! {
        
        let group = todo.value(forKey: XYZTodo.group) as? String ?? ""
        if lastGroup == "" || lastGroup != group {
            
            lastGroup = group
            index = 0
        }
        
        todo.setValue(index, forKey: XYZTodo.sequenceNr)
        index += 1
    }
    
    saveManageContext()
}

func editTodoInManagedContext(oldGroup: String,
                              oldSequenceNr: Int,
                              newGroup: String,
                              newSequenceNr: Int,
                              detail: String,
                              complete: Bool) {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    guard let todo = appDelegate.todos?.first(where: {
    
        let gr = $0.value(forKey: XYZTodo.group) as? String ?? ""
        let seqNr = $0.value(forKey: XYZTodo.sequenceNr) as? Int ?? -1
        
        return oldGroup == gr && seqNr == oldSequenceNr
    }) else {
        
        fatalError("Exception: todo does not exist")
    }
    
    todo.setValue(newGroup, forKey: XYZTodo.group)
    todo.setValue(newSequenceNr, forKey: XYZTodo.sequenceNr)
    todo.setValue(detail, forKey: XYZTodo.detail)
    todo.setValue(complete, forKey: XYZTodo.complete)

    appDelegate.todos = sortTodos(todos: appDelegate.todos!)
    
    saveManageContext()
}

func addTodoToManagedContext(group: String,
                             sequenceNr: Int,
                             detail: String,
                             complete: Bool) {
    
    let todo = XYZTodo(group: group,
                       sequenceNr: sequenceNr,
                       detail: detail,
                       complete: complete,
                       context: managedContext())
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    appDelegate.todos!.append(todo)
    appDelegate.todos = sortTodos(todos: appDelegate.todos!)
    
    printTodos(todos: appDelegate.todos!)
    saveManageContext()
}

func getTodosFromManagedContext() -> [XYZTodo] {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    return appDelegate.todos!
}

func printTodos(todos: [XYZTodo]) {
    
    print("---- print todos")
    
    for todo in todos {
        
        let group = todo.value(forKey: XYZTodo.group) as? String ?? "_unknown_"
        let sequenceNr = todo.value(forKey: XYZTodo.sequenceNr) as? Int ?? -1
        let detail = todo.value(forKey: XYZTodo.detail) as? String ?? ""
        let complete = todo.value(forKey: XYZTodo.complete) as? Bool ?? false
        
        print("group = \(group), sequenceNr = \(sequenceNr), detail = \(detail), complete = \(complete)")
    }
}

func printGlobal(global: XYZGlobal) {
    
    print("---- print global")
    
    let dow = global.value(forKey: XYZGlobal.dow) as? String ?? ""
    print("dow = ", dow)
}
