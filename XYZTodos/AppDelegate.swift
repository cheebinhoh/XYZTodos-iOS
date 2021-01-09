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
import WidgetKit

@main
class AppDelegate: UIResponder,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate {

    var todos: [XYZTodo]?
    var global: XYZGlobal?
    var lastExpandedGroups = [String]()
    var highlightGroup = ""
    var highlightSequenceNr = -1
    var pendingWrite = false
    
    func saveLastExpandedGroups() {
        
        let tableViewController = getTodoTableViewController()
        
        lastExpandedGroups = []
        
        for section in tableViewController.sectionCellList {
            
            if let todoGroup = section.data as? XYZTodoTableViewController.TodoGroup,
               !todoGroup.collapse {
                
                lastExpandedGroups.append(section.identifier)
            }
        }
    }
    
    func reloadTodosDataInView() {
        
        let tableViewController = getTodoTableViewController()
        tableViewController.reloadSectionCellModelData()
    }
    
    func restoreLastExpandedTodoGroupInView() {
        
        let tableViewController = getTodoTableViewController()
        tableViewController.expandTodos(dows: lastExpandedGroups)
    }
    
    func highlightGroupSequenceNrInView() {
        
        if highlightGroup != "" && highlightSequenceNr >= 0 {
            
            let tableViewController = getTodoTableViewController()
            tableViewController.highlight(todoIndex: highlightSequenceNr, group: highlightGroup)
        }
        
        highlightGroup = ""
        highlightSequenceNr = -1
    }
    
    @discardableResult
    func reconciliateData() -> Bool {
        
        let globalDow = DayOfWeek(rawValue: global!.dow )
        let refreshTodos = nil == globalDow
                            || ( globalDow != todayDoW
                                 && todayDoW.weekDayNr == firstWeekDay )
        
        if refreshTodos {
            
            for todo in todos! {

                todo.complete = false
            }
        }
        
        global!.dow = todayDoW.rawValue
        todos = reconciliateTodoSequenceNr(todos: todos!)
        saveManageContext()
        
        if refreshTodos {
            
            writeTodosToCloudKit()
        }
        
        return refreshTodos
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        // notification
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .announcement, .badge];
        
        center.requestAuthorization(options: options) { (granted, error) in
            
            enableNotification = granted
        }
        
        application.registerForRemoteNotifications()
        
        global = loadGlobalFromManagedContext();
        todos = loadAndConvertTodosFromManagedContext()
        
        // cloud kit
        // 1. load data from icloud into temporary buffer based on last change token from global
        // 2. merge data from temporary buffer into todos
        // 3. push todos back to icloud
        // 4. pull data from icloud and update last change token.
        // 5. overwrite all data from icloud (2nd pull) into todos 
        // 6. subscribe change from icloud based on last change token.
        //
        // can we get the last change token related step 3 without step 4 but step 5?
        XYZCloudCache.intialize(groups: allGroups)
        XYZCloudCache.registeriCloudSubscription()
        
        center.delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        //registerDeregisterNotification()
        //WidgetCenter.shared.reloadAllTimelines()
        
        return true
    }

    // MARK: CloudKit methods to get and set
    func readAndMergeTodosFromCloudKit(completion: (() -> Void)? = nil) {
 
        var processedGroup = [String]()
        var saveTodosFromCloud = [String: [XYZCloudTodo]]()
        
        XYZCloudCache.read(of: allGroups) { (identifier, todosFromCloud) in

            if let todosFromCloud = todosFromCloud {
                
                saveTodosFromCloud[identifier] = todosFromCloud
            } // if let todosFromCloud = todosFromCloud
            
            processedGroup.append(identifier)

            if processedGroup.count == allGroups.count {
                
                DispatchQueue.main.async {
                
                    self.loadTodosFromiCloudCache(todosFromCloud: saveTodosFromCloud)
                    completion?()
                }
            }
        }
    }
    
    func writeTodosToCloudKit(of groups: [String] = allGroups,
                              completion: (() -> Void)? = nil) {
        
        var outbound = [String: [XYZCloudTodo]]()
        
        for group in groups {
            
            var cloudTodos = [XYZCloudTodo]()
            
            for todo in todos! {
                
                if todo.group == group {
                    
                    let ctodo = XYZCloudTodo(recordId: todo.recordId,
                                             group: todo.group,
                                             sequenceNr: todo.sequenceNr,
                                             detail: todo.detail,
                                             complete: todo.complete,
                                             time: todo.time,
                                             timeOn: todo.timeOn)
                    
                    cloudTodos.append(ctodo)
                }
            }
            
            outbound[group] = cloudTodos
        }
        
        if !outbound.isEmpty {
        
            XYZCloudCache.write(data: outbound, completion: completion ?? { })
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     
        if UIApplication.shared.applicationState == .background {
            
            completionHandler(.noData)
        } else {
            
            guard let notification:CKRecordZoneNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)! as? CKRecordZoneNotification else {
                
                completionHandler(.failed)
                
                return
            }
            
            let _ = "-------- notifiction \(String(describing: notification.recordZoneID?.zoneName))"
  
            readAndMergeTodosFromCloudKit {
                
                self.reloadTodosDataInView()
                self.restoreLastExpandedTodoGroupInView()
            }
            
            completionHandler(.newData)
        }
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

    // MARK: - Deprecated Core Data stack

    lazy var persistentContainerDeprecated: NSPersistentCloudKitContainer = {
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let (group, sequenceNr) = parseGroupAndSequenceNr(of: response.notification.request.identifier)

        if let group = group,
            let sequenceNr = sequenceNr {
            
            if let todoFound = getTodo(group: group, sequenceNr: sequenceNr, from: todos!) {

                switch response.actionIdentifier {
                
                    case "DONE_ACTION":
                        todoFound.complete = true
                        todoFound.timeReschedule = nil
                        saveManageContext()
                        pendingWrite = true
                        
                    case "AN_HOUR_LATER_ACTION":
                        todoFound.timeReschedule = Date.nextHour()
                        saveManageContext()
                            
                    default:
                        break
                }
                
                let tableViewController = getTodoTableViewController()
                tableViewController.reloadSectionCellModelData()
                tableViewController.expandTodos(dows: [group], sequenceNr: sequenceNr)
                tableViewController.highlight(todoIndex: sequenceNr, group: group)
                
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    
                    fatalError("Exception: AppDelegate is expected")
                }
                
                appDelegate.lastExpandedGroups = []
                appDelegate.lastExpandedGroups.append(group)
            }
        }
     
        // register notification and refresh widget
        registerDeregisterNotification()
        WidgetCenter.shared.reloadAllTimelines()
        
        completionHandler()
    }
    
    // MARK :- Deprecated managed context

    func managedContextDeprecated() -> NSManagedObjectContext? {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            
            fatalError("Exception: AppDelegate is expected")
        }
      
        return appDelegate.persistentContainerDeprecated.viewContext
    }

    func saveManageContextDeprecated() {
        
        let aContext = managedContextDeprecated()
        
        do {
            
            try aContext?.save()
        } catch let nserror as NSError {
            
            fatalError("Exception: Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    func loadTodosFromiCloudCache(todosFromCloud: [String: [XYZCloudTodo]]) {
        
        for (identifier, ctodos) in todosFromCloud {
            
            for todo in self.todos! {
                
                if todo.group == identifier {
                    
                    managedContext()?.delete(todo)
                }
            }
               
            for ctodo in ctodos {
                
                let _ = XYZTodo(group: identifier,
                                sequenceNr: ctodo.sequenceNr!,
                                detail: ctodo.detail!,
                                timeOn: ctodo.timeOn!,
                                time: ctodo.time!,
                                complete: ctodo.complete!,
                                context: managedContext())
            }
            
            saveManageContext()
        }
        
        self.todos = loadTodosFromManagedContext(managedContext())
        self.todos = sortTodos(todos: self.todos!)
    }
    
    func loadAndConvertTodosFromManagedContext() -> [XYZTodo]? {

        // load from old storage
        var outputDeprecated: [XYZTodo]?

        let aContextDeprecated = managedContextDeprecated()
        let fetchRequestDeprecated = NSFetchRequest<XYZTodo>(entityName: XYZTodo.type)
        
        if let unsortedDeprecated = try? aContextDeprecated?.fetch(fetchRequestDeprecated) {
            
            outputDeprecated = sortTodos(todos: unsortedDeprecated)
        }

        // load from new storage
        let aContext = managedContext()
        var output = loadTodosFromManagedContext(aContext)

        if outputDeprecated != nil && !outputDeprecated!.isEmpty {

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                
                fatalError("Exception: AppDelegate is expected")
            }
            
            appDelegate.todos = output
            
            for todo in outputDeprecated! {
                
                addTodoToAppDelegate(group: todo.group,
                                     sequenceNr: todo.sequenceNr,
                                     detail: todo.detail,
                                     timeOn: todo.timeOn,
                                     time: todo.time,
                                     complete: todo.complete)
                
                aContextDeprecated?.delete(todo)
            }
            
            saveManageContext()
            saveManageContextDeprecated()
            
            output = appDelegate.todos
        }

        return output
    }
}


// MARK: - functions to manage data in AppDelegate

func reconciliateTodoSequenceNr(todos: [XYZTodo]) -> [XYZTodo] {
    
    var index = 0
    var lastGroup = ""
    for todo in todos {
        
        let group = todo.group
        if lastGroup == "" || lastGroup != group {
            
            lastGroup = group
            index = 0
        }
        
        todo.sequenceNr = index
        index += 1
    }
    
    return todos
}

func deleteTodoInAppDelegate(group: String,
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
    let group = todo?.group
    
    managedContext()?.delete(todo!)
    appDelegate.todos = reconciliateTodoSequenceNr(todos: appDelegate.todos!)
    
    saveManageContext()
    registerDeregisterNotification()
    
    appDelegate.writeTodosToCloudKit(of: [group!])
    XYZCloudCache.printDebug()
}

func moveTodoInAppDelegate(fromIndex: Int,
                           toIndex: Int)
{
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    let removeTodo = appDelegate.todos?.remove(at: fromIndex)
    let group = removeTodo?.group
    
    appDelegate.todos?.insert(removeTodo!, at: toIndex)
    appDelegate.todos = reconciliateTodoSequenceNr(todos: appDelegate.todos!)
    appDelegate.todos = sortTodos(todos: appDelegate.todos!)
    appDelegate.todos = reconciliateTodoSequenceNr(todos: appDelegate.todos!)
    
    saveManageContext()
    registerDeregisterNotification()
    
    appDelegate.writeTodosToCloudKit(of: [group!])
    XYZCloudCache.printDebug()
}

func editTodoInAppDelegate(oldGroup: String,
                           oldSequenceNr: Int,
                           newGroup: String,
                           newSequenceNr: Int,
                           detail: String,
                           timeOn: Bool,
                           time: Date,
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
    todo.timeOn = timeOn
    todo.time = time
    todo.timeReschedule = nil
    todo.complete = complete

    appDelegate.todos = sortTodos(todos: appDelegate.todos!)
    appDelegate.todos = reconciliateTodoSequenceNr(todos: appDelegate.todos!)
        
    saveManageContext()
    registerDeregisterNotification()
    
    appDelegate.writeTodosToCloudKit(of: [oldGroup, newGroup])
    XYZCloudCache.printDebug()
}

func addTodoToAppDelegate(group: String,
                          sequenceNr: Int,
                          detail: String,
                          timeOn: Bool,
                          time: Date,
                          complete: Bool) {
    
    let todo = XYZTodo(group: group,
                       sequenceNr: sequenceNr,
                       detail: detail,
                       timeOn: timeOn,
                       time: time,
                       complete: complete,
                       context: managedContext())
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    appDelegate.todos!.append(todo)
    appDelegate.todos = sortTodos(todos: appDelegate.todos!)
    appDelegate.todos = reconciliateTodoSequenceNr(todos: appDelegate.todos!)
        
    saveManageContext()
    registerDeregisterNotification()
    
    appDelegate.writeTodosToCloudKit(of: [todo.group])
    XYZCloudCache.printDebug()
}

func getTodosFromAppDelegate() -> [XYZTodo] {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    return appDelegate.todos!
}

func registerDeregisterNotification() {

    // deregister
    let center = UNUserNotificationCenter.current()
    
    center.removeAllPendingNotificationRequests()
    
    guard enableNotification else {
        
        return
    }
    
    let doneAction = UNNotificationAction(identifier: "DONE_ACTION",
                                          title: "Done".localized(),
                                          options: UNNotificationActionOptions(rawValue: 0))

    let anHourAfterAction = UNNotificationAction(identifier: "AN_HOUR_LATER_ACTION",
                                                 title: "Remind after an hour".localized(),
                                                 options: UNNotificationActionOptions(rawValue: 0))
    
    // Define the notification type
    let meetingInviteCategory = UNNotificationCategory(identifier: "TODO_ACTION",
                                                       actions: [doneAction, anHourAfterAction],
                                                       intentIdentifiers: [],
                                                       hiddenPreviewsBodyPlaceholder: "",
                                                       options: .customDismissAction)

    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.setNotificationCategories([meetingInviteCategory])
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }

    var lastDoWMidNightNotificationInstalled = false
    var lastDoW: DayOfWeek?
    for todo in appDelegate.todos! {
        
        let todoDow = DayOfWeek(rawValue: todo.group)
        
        if todoDow == nil {
            
            continue
        }
        
        if todo.complete {
            
            continue
        }
        
        if let lastDow = lastDoW, lastDow != todoDow {
            
            lastDoWMidNightNotificationInstalled = false
        }
        
        let content = UNMutableNotificationContent()

        content.badge = 1
        content.categoryIdentifier = "TODO_ACTION"
        content.body = todo.detail
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.weekday = todoDow!.weekDayNr
        
        if let timeReschedule = todo.timeReschedule,
           todo.timeOn && timeReschedule > Date() {
            
            dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                             from: timeReschedule)

            let dateFormatter = DateFormatter()
            
            content.title = "You have todo on \(todoDow!.rawValue)".localized()
                            + " \(dateFormatter.stringWithShortTime(from: todo.time))"
        } else if todo.timeOn {
        
            dateComponents = Calendar.current.dateComponents([.hour, .minute],
                                                             from: todo.time)
            
            let dateFormatter = DateFormatter()
            
            content.title = "You have todo on \(todoDow!.rawValue)".localized()
                            + " \(dateFormatter.stringWithShortTime(from: todo.time))"
        } else {
        
            if lastDoWMidNightNotificationInstalled {
                
                continue
            }
            
            lastDoWMidNightNotificationInstalled = true
            
            content.title = "You have todo on \(todoDow!.rawValue)".localized()
            
            dateComponents.hour = 0
            dateComponents.minute = 0
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier:"group=\(todo.group)&sequenceNr=\(todo.sequenceNr)",
                                            content: content,
                                            trigger: trigger)
        
        center.add(request) { (error) in
            
            if let error = error {
                
                print("-------- registerDeregisterNotification: error = \(error)")
            }
        }
        
        lastDoW = todoDow
    }
} // func registerDeregisterNotification()

func executeAddTodo() {
    
    let scene = UIApplication.shared.connectedScenes.first
    let tableViewController = getTodoTableViewController(scene: scene)
    
    DispatchQueue.main.async {
     
        tableViewController.performSegue(withIdentifier: "newTodoDetail",
                                         sender: scene)
    }
}

func switchToTodoTableViewController(scene: UIScene? = UIApplication.shared.connectedScenes.first) {
    
    guard let sd = (scene?.delegate as? SceneDelegate) else {

        fatalError("Exception sceneDelegate is expected")
    }
    
    guard let tabBarController = sd.window?.rootViewController as? UITabBarController else {
        
        fatalError("Exception: UITabBarController is expected" )
    }
    
    tabBarController.selectedIndex = 0
}

func getTodoTableViewController(window: UIWindow) -> XYZTodoTableViewController {

    guard let tabBarController = window.rootViewController as? UITabBarController else {
        
        fatalError("Exception: UITabBarController is expected" )
    }
    
    guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
        
        fatalError("Exception: UINavigationController is expected")
    }
    
    guard let tableViewController = navController.viewControllers.first as? XYZTodoTableViewController else {
        
        fatalError("Exception: XYZTodoTableViewController is expected" )
    }
    
    return tableViewController
}

func getTodoTableViewController(scene: UIScene? = UIApplication.shared.connectedScenes.first) -> XYZTodoTableViewController {
    
    guard let sd = (scene?.delegate as? SceneDelegate) else {

        fatalError("Exception sceneDelegate is expected")
    }
    
    return getTodoTableViewController(window: sd.window!)
}
