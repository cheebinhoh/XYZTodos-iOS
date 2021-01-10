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
    var expandedTodoGroups = [String]()
    var highlightGroupInTodosView = ""
    var highlightSequenceNrInTodosView = -1
    
    //MARK: - Todos view manipulation methods
    
    func switchToTodosView(scene: UIScene? = UIApplication.shared.connectedScenes.first) {
        
        guard let sd = (scene?.delegate as? SceneDelegate) else {

            fatalError("Exception sceneDelegate is expected")
        }
        
        guard let tabBarController = sd.window?.rootViewController as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        tabBarController.selectedIndex = 0
    }
    
    func resetExpandedGroupInTodosView() {
    
        expandedTodoGroups = []
    }
    
    func addExpandedGroupInTodosView(group: String) {
        
        if !expandedTodoGroups.contains(group) {
            
            expandedTodoGroups.append(group)
        }
    }
    
    func saveExpandedGroupsInTodosView() {
        
        resetExpandedGroupInTodosView()
        
        let tableViewController = getTodoTableViewController()
        
        for section in tableViewController.sectionCellList {
            
            if let todoGroup = section.data as? XYZTodoTableViewController.TodoGroup,
               !todoGroup.collapse {
                
                addExpandedGroupInTodosView(group: section.identifier)
            }
        }
    }
    
    func reloadTodosDataInTodosView() {
        
        let tableViewController = getTodoTableViewController()
        tableViewController.reloadSectionCellModelData()
    }
    
    func restoreExpandedGroupInTodosView() {
        
        let tableViewController = getTodoTableViewController()
        tableViewController.expandTodos(dows: expandedTodoGroups)
    }
    
    func highlightGroupSequenceNrInTodosView() {
        
        if highlightGroupInTodosView != ""
            && highlightSequenceNrInTodosView >= 0 {
            
            let tableViewController = getTodoTableViewController()
            tableViewController.highlight(todoIndex: highlightSequenceNrInTodosView,
                                          group: highlightGroupInTodosView)
        }
        
        highlightGroupInTodosView = ""
        highlightSequenceNrInTodosView = -1
    }
    
    func setHighlightGroupSequenceNrInTodosView(group: String = "",
                                                sequenceNr: Int = -1) {
        
        highlightGroupInTodosView = group
        highlightSequenceNrInTodosView = sequenceNr
    }
    
    
    //MARK: - Miscellaneous
    @discardableResult
    func reconciliateData() -> Bool {
        
        let globalDow = DayOfWeek(rawValue: global!.dow )
        let refreshTodos = nil != globalDow
                            && ( globalDow != todayDoW
                                 && todayDoW.weekDayNr == firstWeekDay )
        
        if refreshTodos {
            
            for todo in todos! {

                todo.complete = false
            }
            
            todos = reconciliateTodoSequenceNr(todos: todos!)
            saveManageContext()
            lastChangeDataTime = Date()
        }
        
        global!.dow = todayDoW.rawValue
        
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
            
            if granted {
 
                DispatchQueue.main.async {
           
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        global = loadGlobalFromManagedContext();
        todos = loadAndConvertTodosFromManagedContext()

        /* There are 3 layers in storage:
         * 0. data is manipulated via UI and stored in controller AppDelegate.todos, this storage is alive
         *    as long as app instance
         *
         * 1. data is stored persistently on CoreData, it is as long as the app is still installed on the device
         *
         * 2. data is sync and upload to iCloud and it is stored beyond app installation.
         *
         * Data is manipulated per group, so if a group todo is changed, we delete the whole group, and update all
         * the group todos. It is not the most efficient method, but it allows us to make sure that we always see
         * a correct # of todos per group and in correct ordering.
         */
        XYZCloudCache.intialize(groups: allGroups)
        XYZCloudCache.registeriCloudSubscription()
        
        center.delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        addExpandedGroupInTodosView(group: todayDoW.rawValue)
        
        return true
    }
    
    // MARK: - CloudKit methods
    func updateTodo(todo: XYZTodo, completion: (() -> Void)? = nil) {
        
        let ctodo = XYZCloudTodo(recordId: todo.recordId,
                                 group: todo.group,
                                 sequenceNr: todo.sequenceNr,
                                 detail: todo.detail,
                                 complete: todo.complete,
                                 time: todo.time,
                                 timeOn: todo.timeOn)
        
        XYZCloudCache.UpdateRecords(todos: [ctodo]) {
            
           completion?()
        }
    }
    
    func syncTodosWithiCloudCache() {
        
        let refreshData: (() -> Void) = {
            
            self.readAndMergeTodosFromCloudKit() {

                if self.reconciliateData() {
                    
                    self.resetExpandedGroupInTodosView()
                    self.addExpandedGroupInTodosView(group: todayDoW.rawValue)
                }

                self.reloadTodosDataInTodosView()
                self.restoreExpandedGroupInTodosView()
                self.highlightGroupSequenceNrInTodosView()
                
                registerDeregisterNotification()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        let hasPendingWrite = ( ( lastChangeDataTime == nil )
                                    || ( nil == lastChangeDataWrittenToiCloudTime
                                            || lastChangeDataWrittenToiCloudTime! < lastChangeDataTime! ) )
                                && !todos!.isEmpty

        if hasPendingWrite {
            
            writeTodosToCloudKit(of: allGroups) {

                lastChangeDataTime = lastChangeDataWrittenToiCloudTime

                refreshData()
            }
        } else {

            refreshData()
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
            
            saveManageContext() // we do not adjust lastChangeDataTime as it is not changed by user
        }
        
        self.todos = loadTodosFromManagedContext(managedContext())
        self.todos = sortTodos(todos: self.todos!)
    }
    
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
        
            XYZCloudCache.write(data: outbound) {

                lastChangeDataWrittenToiCloudTime = Date()
                completion?()
            }
        }
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     
        if UIApplication.shared.applicationState == .background {
            
            completionHandler(.noData)
        } else {
            
            guard let notification:CKRecordZoneNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)! as? CKRecordZoneNotification else {
                
                completionHandler(.failed)
                
                return
            }
            
            let _ = "-------- notifiction \(String(describing: notification.recordZoneID?.zoneName))"
  
            readAndMergeTodosFromCloudKit {
                
                self.reloadTodosDataInTodosView()
                self.restoreExpandedGroupInTodosView()
            }
            
            completionHandler(.newData)
        }
    }
    
    //MARK: - Notification methods
    
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
                        lastChangeDataTime = Date()
                        
                        /* this does not work for some reason that Cloudkit operation can not be submit in background
                        updateTodo(todo: todoFound) {
                            
                            lastChangeDataWrittenToiCloudTime = Date()
                        }
                         */
                        
                    case "AN_HOUR_LATER_ACTION":
                        todoFound.timeReschedule = Date.nextHour()
                        saveManageContext()
                            
                    default:
                        break
                }
                
                addExpandedGroupInTodosView(group: group)
                setHighlightGroupSequenceNrInTodosView(group: group,
                                                       sequenceNr: sequenceNr)
            }
        }
     
        // register notification and refresh widget
        registerDeregisterNotification()
        WidgetCenter.shared.reloadAllTimelines()
        
        completionHandler()
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

    // MARK: - Core data method and deprecated managed context

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
            lastChangeDataTime = Date()
            saveManageContextDeprecated()
            
            output = appDelegate.todos
        }

        return output
    }
}


// MARK: - AppDelegate data manipulation methods

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
    lastChangeDataTime = Date()
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
    lastChangeDataTime = Date()
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
    lastChangeDataTime = Date()
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
    lastChangeDataTime = Date()
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
