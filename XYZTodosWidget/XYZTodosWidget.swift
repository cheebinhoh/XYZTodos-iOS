//
//  XYZTodosWidget.swift
//  XYZTodosWidget
//
//  Created by Chee Bin Hoh on 1/1/21.
//

import WidgetKit
import SwiftUI
import CoreData

var persistentContainer: NSPersistentCloudKitContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
    */
    //let persistentContainer = NSPersistentContainer(name: "Collect")
    let storeURL = URL.storeURL(for: appGroup, databaseName: databaseName)
    let storeDescription = NSPersistentStoreDescription(url: storeURL)

    let container = NSPersistentCloudKitContainer(name: databaseName)
    container.persistentStoreDescriptions = [storeDescription]
    
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

func managedContext() -> NSManagedObjectContext? {
    
    return persistentContainer.viewContext
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

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todos: [XYZTodo]())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), todos: [XYZTodo]())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        var entries: [SimpleEntry] = []

        let todos = loadTodosFromManagedContext()
        var todosInFutureOfToday = [XYZTodo]()
        var todosDue = [XYZTodo]()
        let nowOnward = Date().getTimeOfToday()
        
        for todo in todos! {

            if let dow = DayOfWeek(rawValue: todo.group),
               dow == todayDoW && !todo.complete {
                
                if !todo.timeOn {
                    
                    todosInFutureOfToday.append(todo)
                } else {
                    
                    let timeOfToday = todo.time.getTimeOfToday()
                    
                    if timeOfToday >= nowOnward {
                        
                        todosInFutureOfToday.append(todo)
                    } else {
                        
                        todosDue.append(todo)
                    }
                }
            }
        }
        
        todosInFutureOfToday.append(contentsOf: todosDue)

        let entry = SimpleEntry(date: Date(), todos: todosInFutureOfToday)
        entries.append(entry)
        
        let after = Date.nextSecond(second: 60)
        
        let afterentry = SimpleEntry(date: after, todos: todosInFutureOfToday)
        entries.append(afterentry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    
    let date: Date
    var todos = [XYZTodo]()
}

struct XYZTodosWidgetEntryView : View {
    
    var entry: Provider.Entry

    var body: some View {
       
        VStack(alignment: .leading, spacing: 5, content: {
            
            Text(entry.todos.first != nil ? "Next".localized() : "You are done for today".localized()).font(.headline).foregroundColor(.green)
            Text(entry.todos.first != nil ? "\(DateFormatter().stringWithShortTime(from:entry.todos.first?.time ?? Date()))  \(entry.todos.first?.detail ?? "")" : "").fontWeight(.light)
        }).padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        
        .widgetURL(URL(string: httpUrlPrefix
                        + httpUrlWidgetHost
                        + "?group=\(entry.todos.first?.group ?? "nil")"
                        + "&sequenceNr=\(entry.todos.first?.sequenceNr ?? -1)"))
    }
}

@main
struct XYZTodosWidget: Widget {
    
    let kind: String = "XYZTodosWidget"

    var body: some WidgetConfiguration {
        
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            
            XYZTodosWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("XYZTodos".localized())
        .description("What is next task?".localized())
    }
}

struct XYZTodosWidget_Previews: PreviewProvider {
    
    static var previews: some View {
        
        XYZTodosWidgetEntryView(entry: SimpleEntry(date: Date(), todos: [XYZTodo]()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
