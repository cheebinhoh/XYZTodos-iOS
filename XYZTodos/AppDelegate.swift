//
//  AppDelegate.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/27/20.
//

import UIKit
import CoreData
import CloudKit
import NotificationCenter
import UserNotifications

@main
class AppDelegate: UIResponder,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate {

    var todos: [XYZTodo]?
    var global: XYZGlobal?
    
    func reconciliateTodoSequenceNr() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            
            fatalError("Exception: AppDelegate is expected")
        }
        
        var index = 0
        var lastGroup = ""
        for todo in appDelegate.todos! {
            
            let group = todo.group 
            if lastGroup == "" || lastGroup != group {
                
                lastGroup = group
                index = 0
            }
            
            todo.sequenceNr = index
            index += 1
        }
    }
    
    @discardableResult
    func reconciliateData() -> Bool {
        
        let globalDow = DayOfWeek(rawValue: global?.dow ?? "" )
        let refreshTodos = nil == globalDow
                            || ( globalDow != todayDoW
                                 && todayDoW.weekDayNr == firstWeekDay )

        if refreshTodos {
            
            for todo in todos! {
   
                todo.complete = false
            }
        }
        
        global!.dow = todayDoW.rawValue
        reconciliateTodoSequenceNr()
        
        saveManageContext()
        
        return refreshTodos
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        global = loadGlobalFromManagedContext();
        todos = loadTodosFromManagedContext()
        
        // reconciliate
        reconciliateData()
        
        // notification
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .announcement, .badge];
        
        center.requestAuthorization(options: options) { (granted, error) in
            
            enableNotification = granted
        }
        
        center.delegate = self
        registerDeregisterNotification()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
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
                fatalError("Exception: unresolved error \(error), \(error.userInfo)")
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
                fatalError("Exception: unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let scene = UIApplication.shared.connectedScenes.first
        
        guard let sd = (scene?.delegate as? SceneDelegate) else {
    
            fatalError("Exception sceneDelegate is expected")
        }
        
        guard let tabBarController = sd.window?.rootViewController as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let tableViewController = navController.viewControllers.first as? XYZTodoTableViewController else {
            
            fatalError("Exception: XYZTodoTableViewController is expected" )
        }
        
        tableViewController.reloadData()
        tableViewController.expandTodos(dows: [todayDoW])
        
        completionHandler()
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

        let g1 = todo1.group
        let g2 = todo2.group
        let s1 = todo1.sequenceNr
        let s2 = todo2.sequenceNr
        
        let dow1Index = ( DayOfWeek(rawValue: g1)?.weekDayNr ) ?? DayOfWeek.lastWeekDayNr + 1
        let dow2Index = ( DayOfWeek(rawValue: g2)?.weekDayNr ) ?? DayOfWeek.lastWeekDayNr + 1
           
        return dow1Index < dow2Index
               || ( dow1Index == dow2Index
                    && s1 < s2 )
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
    
        let gr = $0.group
        let seqNr = $0.sequenceNr
        
        return group == gr && seqNr == sequenceNr
    }) else {
        
        return
    }

    let todo = appDelegate.todos?.remove(at: index)
    
    managedContext()?.delete(todo!)
    appDelegate.reconciliateTodoSequenceNr()
    
    saveManageContext()
    registerDeregisterNotification()
}

func moveTodoInManagedContext(fromIndex: Int,
                              toIndex: Int)
{
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    let removeTodo = appDelegate.todos?.remove(at: fromIndex)
    appDelegate.todos?.insert(removeTodo!, at: toIndex)
    appDelegate.reconciliateTodoSequenceNr()
    
    saveManageContext()
    registerDeregisterNotification()
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
    
        let gr = $0.group
        let seqNr = $0.sequenceNr
        
        return oldGroup == gr && seqNr == oldSequenceNr
    }) else {
        
        fatalError("Exception: todo is not found for \(oldGroup), \(oldSequenceNr)")
    }
    
    todo.group = newGroup
    todo.sequenceNr = newSequenceNr
    todo.detail = detail
    todo.complete = complete

    appDelegate.todos = sortTodos(todos: appDelegate.todos!)
    appDelegate.reconciliateTodoSequenceNr()
    
    saveManageContext()
    registerDeregisterNotification()
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
    appDelegate.reconciliateTodoSequenceNr()
    
    saveManageContext()
    registerDeregisterNotification()
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
        
        let group = todo.group
        let sequenceNr = todo.sequenceNr
        let detail = todo.detail
        let complete = todo.complete
        
        print("group = \(group), sequenceNr = \(sequenceNr), detail = \(detail), complete = \(complete)")
    }
}

func printGlobal(global: XYZGlobal) {
    
    print("---- print global")
    
    let dow = global.dow
    print("dow = ", dow)
}

func registerDeregisterNotification() {

    // deregister
    let center = UNUserNotificationCenter.current()
    
    center.removeAllPendingNotificationRequests()
    
    guard enableNotification else {
        
        return
    }
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    let dows = appDelegate.todos!.reduce(Set<DayOfWeek>()) { (dows, todo) -> Set<DayOfWeek> in
    
        let group = todo.group
        var output = dows
        
        if let dow = DayOfWeek(rawValue: group) {

            output.insert(dow)
        }
        
        return output
    }
    
    for dow in dows {
        
        let content = UNMutableNotificationContent()
        content.title = "You have todos on \(dow.rawValue)".localized()
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        dateComponents.weekday = dow.weekDayNr
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: dow.rawValue, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            
            if let error = error {
                
                print("-------- registerDeregisterNotification: error = \(error)")
            }
        }
    }
} // func registerDeregisterNotification()
