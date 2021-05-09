//
//  XYZTodosWidget.swift
//  XYZTodosWidget
//
//  Created by Chee Bin Hoh on 1/1/21.
//
//  Copyright © 2020 - 2020 Chee Bin Hoh. All rights reserved.
//

import WidgetKit
import SwiftUI

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

        let todos = loadTodosFromManagedContext(managedContext())
        var todosForWidget = [XYZTodo]()
        var todosDue = [XYZTodo]()
        let nowOnward = Date().getTimeOfToday()

        for todo in todos! {

            if let dow = DayOfWeek(rawValue: todo.group),
               dow == todayDoW && !todo.complete {
                
                if !todo.timeOn {
                    
                    todosForWidget.append(todo)
                } else {
                    
                    let timeOfToday = todo.time.getTimeOfToday()
                    
                    if timeOfToday >= nowOnward {
                        
                        todosForWidget.append(todo)
                    } else {
                        
                        todosDue.append(todo)
                    }
                }
            }
        }
 
        if !todosDue.isEmpty {
            
            if !todosForWidget.isEmpty {
                
                let lastDueTodoEpoch = todosDue.last!.time.getTimeOfToday().timeIntervalSinceReferenceDate
                let nowOnwardEpoch = nowOnward.timeIntervalSinceReferenceDate
                let nextTodoEpoch = todosForWidget.first!.time.getTimeOfToday().timeIntervalSinceReferenceDate

                if abs( nowOnwardEpoch - lastDueTodoEpoch )
                    < abs( nextTodoEpoch - nowOnwardEpoch ) {
                    
                    let todo = todosDue.removeLast()
                    todosForWidget.insert(todo, at: 0)
                }
            }
            
            todosDue.reverse()
        }
        
        todosForWidget.append(contentsOf: todosDue)
        let overdues = todosForWidget.map { (todo) -> Bool in
            
            let time = todo.time.getTimeOfToday()
            
            return time < nowOnward
        }

        let entry = SimpleEntry(date: Date(), todos: todosForWidget, overdues: overdues)
        entries.append(entry)
        
        let afterentry = SimpleEntry(date: Date.nextMinute(), todos: todosForWidget, overdues: overdues)
        entries.append(afterentry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    
    let date: Date
    var todos = [XYZTodo]()
    var overdues = [Bool]()
}

struct XYZTodosWidgetEntryView: View {
    
    var entry: Provider.Entry

    var body: some View {
       
        VStack(alignment: .leading, spacing: 5, content: {
            
            if let first = entry.todos.first,
               let firstoverdue = entry.overdues.first  {
            
                if firstoverdue {
                    
                    Text("Overdue".localized()).font(.headline).foregroundColor(.red)
                } else {
                    
                    Text("Next".localized()).font(.headline).foregroundColor(.green)
                }
                
                let dateFormatter = DateFormatter()
                let timeDetails = "\(dateFormatter.stringWithShortTime(from: first.time)) \(first.detail)"
                
                Text(timeDetails).font(.system(.body))
            } else {
                
                Text("All done".localized()).font(.headline).foregroundColor(.green)
            }
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
