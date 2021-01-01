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
    let storeURL = URL.storeURL(for: "group.com.XYZTodos", databaseName: "XYZTodos")
    let storeDescription = NSPersistentStoreDescription(url: storeURL)

    let container = NSPersistentCloudKitContainer(name: "XYZTodos")
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

let todos = loadTodosFromManagedContext()

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
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct XYZTodosWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

@main
struct XYZTodosWidget: Widget {
    let kind: String = "XYZTodosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            XYZTodosWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct XYZTodosWidget_Previews: PreviewProvider {
    static var previews: some View {
        XYZTodosWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
