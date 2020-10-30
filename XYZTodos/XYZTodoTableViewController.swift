//
//  XYZTodoTableViewController.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//
//  Copyright © 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZTodoTableViewController: UITableViewController {

    // MARK: - Type
    
    struct Todo {
        
        var detail = ""
        var complete = false
    }
    
    struct TodoGroup {
        
        var collapse = true
        var todos = [Todo]()
        var complete: Bool {
            
            return todos.reduce(true) { (result, todo) -> Bool in
                
                return result && todo.complete
            }
        }
    }
    
    
    // MARK: - Property
    
    var sectionCellList = [TableViewSectionCell]()
    
    
    // MARK: - Function

    func loadModelDataIntoSectionCellData() {
        
        var loadedSectionCellList = [TableViewSectionCell]()
        
        for var section in sectionCellList {
            
            let dow = section.identifier
            var group = TodoGroup()
            
            // testing data
            if dow == DayOfWeek.Thursday.rawValue {
                
                let todo1 = Todo(detail: "Wash bathroom", complete: false)
               
                group.todos.append(todo1)
                
                let todo2 = Todo(detail: "Laundry", complete: false)
               
                group.todos.append(todo2)
            }
            
            section.data = group
            
            loadedSectionCellList.append(section)
        }
        
        sectionCellList = loadedSectionCellList
    }
    
    func printSectionCellData() {
        
        print("---- start printSectionCellData")
        
        for section in sectionCellList {
            
            print("---- ---- section id = \(section.identifier)")
            
            if let todoGroup = section.data as? TodoGroup {
                
                for todo in todoGroup.todos {
                    
                    print("---- ---- ---- todo = \(todo.detail)")
                }
            }
        }
        
        print("---- end printSectionCellData")
    }
    
    func loadSectionCellData() {

        sectionCellList = []

        let today = Date()
        let dateFormat = DateFormatter()

        dateFormat.dateFormat = "EEEE" // Day of week
        let todayDoW = dateFormat.string(from: today)

        var sectionCellListBeforeTodayDoW = [TableViewSectionCell]()
        var sectionCellListAfterAndTodayDoW = [TableViewSectionCell]()
        var hitTodayDoW = false
        
        for dayOfWeek in DayOfWeek.allCases {
        
            let dow = dayOfWeek.rawValue
            let dowlocalized = dow.localized()
            
            let groupSection = TableViewSectionCell(identifier: dow,
                                                    title: nil,
                                                    cellList: [dowlocalized],
                                                    data: nil)
            if hitTodayDoW {
                
                sectionCellListAfterAndTodayDoW.append(groupSection)
            } else {
                
                hitTodayDoW = dowlocalized == todayDoW
                if hitTodayDoW {
                 
                    sectionCellListAfterAndTodayDoW.append(groupSection)
                } else {
                    
                    sectionCellListBeforeTodayDoW.append(groupSection)
                }
            }
        }
        
        sectionCellList.append(contentsOf: sectionCellListAfterAndTodayDoW)
        sectionCellList.append(contentsOf: sectionCellListBeforeTodayDoW) // any day before today is wrap toward the end
        
        let groupSection = TableViewSectionCell(identifier: "Other",
                                                title: nil,
                                                cellList: ["Other".localized()],
                                                data: nil)
        
        sectionCellList.append(groupSection)
        
        loadModelDataIntoSectionCellData()
        
        printSectionCellData()
    }
    
    func reloadData() {
        
        loadSectionCellData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.tableHeaderView = UIView(frame: .zero)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        loadSectionCellData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return sectionCellList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        let todoGroup = sectionCellList[section].data as? TodoGroup
        
        var numTodos = 0
        
        if let todoGroup = todoGroup, !todoGroup.collapse {
            
            numTodos = todoGroup.todos.count
        }
        
        return sectionCellList[section].cellList.count
                + numTodos
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row <= 0 {
            
            var todoGroup = sectionCellList[indexPath.section].data as? TodoGroup
            
            todoGroup!.collapse = !todoGroup!.collapse
            sectionCellList[indexPath.section].data = todoGroup
        }
        
        tableView.deselectRow(at: indexPath, animated: false)

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        var height: CGFloat = 5.0
        
        if section == 0 {
            
            height = 35.0
        } else if section == sectionCellList.count - 1 {
            
            height = 15.0
        }
        
        return height
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 2.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionCellList[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        let sectionId = sectionCellList[indexPath.section].identifier

        switch sectionId {
        
            default:
                if indexPath.row <= 0 {

                    guard let newcell = tableView.dequeueReusableCell(withIdentifier: "todoTableViewCell", for: indexPath) as? XYZTodoTableViewCell else {
                        
                        fatalError("Exception: error on creating todoTableViewCell")
                    }
                    
                    if let todoGroup = sectionCellList[indexPath.section].data as? TodoGroup {
                        
                        let hastodos = !todoGroup.todos.isEmpty
                        if hastodos && todoGroup.complete  {
                            
                            newcell.accessoryType = .checkmark
                        } else if hastodos && todoGroup.collapse {
                            
                            newcell.accessoryType = .detailButton
                        } else {
                            
                            newcell.accessoryType = .none
                        }
                    } else {
                        
                        newcell.accessoryType = .none
                    }
                    
                    newcell.title.text = sectionCellList[indexPath.section].cellList[0]
                    cell = newcell
                } else { // if indexPath.row <= 0
                    
                    guard let newcell = tableView.dequeueReusableCell(withIdentifier: "todoItemTableViewCell", for: indexPath) as? XYZTodoItemTableViewCell else {
                        
                        fatalError("Exception: error on creating todoItemTableViewCell")
                    }
                    
                    let todoGroup = sectionCellList[indexPath.section].data as? TodoGroup
                    let complete = todoGroup?.todos[indexPath.row - 1].complete ?? false
                    
                    if complete {
                        
                        newcell.accessoryType = .checkmark
                    }  else {
                        
                        newcell.accessoryType = .none
                    }
                    
                    newcell.detail.text = todoGroup?.todos[indexPath.row - 1].detail
                    cell = newcell
                }
        } // switch sectionId

        return cell!
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()

        if indexPath.row > 0 {
            
            let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
                
                var section = self.sectionCellList[indexPath.section]
                var todoGroup = section.data as! TodoGroup
                
                todoGroup.todos.remove(at: indexPath.row - 1)
                section.data = todoGroup
                self.sectionCellList[indexPath.section] = section
                
                print("---- after delete = \(indexPath)")
                self.printSectionCellData()
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.reloadData()
                
                handler(true)
            }
            
            commands.append(delete)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let complete = UIContextualAction(style: .destructive, title: "Complete".localized()) { _, _, handler in

            var todoGroup = self.sectionCellList[indexPath.section].data as? TodoGroup
            let allTodos = indexPath.row <= 0
            
            if allTodos {
                
                let complete = !(todoGroup?.complete ?? false)
                var newTodos = [Todo]()
                
                for var todo in todoGroup!.todos {
                    
                    todo.complete = complete
                    newTodos.append(todo)
                }
                
                todoGroup?.todos = newTodos
            } else {
                
                let complete = todoGroup?.todos[indexPath.row - 1].complete
                
                todoGroup?.todos[indexPath.row - 1].complete = !(complete ?? true)
            }
            
            self.sectionCellList[indexPath.section].data = todoGroup
            tableView.reloadData()
            
            handler(true)
        }
        
        complete.backgroundColor = UIColor.systemBlue
        commands.append(complete)

        return UISwipeActionsConfiguration(actions: commands)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return indexPath.row > 0
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
                
        if editingStyle == .delete {
            // Delete the row from the data source
            
            var section = sectionCellList[indexPath.section]
            var todoGroup = section.data as! TodoGroup
            
            todoGroup.todos.remove(at: indexPath.row - 1)
            section.data = todoGroup
            sectionCellList[indexPath.section] = section
            
            printSectionCellData()
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            
            fatalError("Exception: yet to be implemented")
        }    
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

        var fromSection = sectionCellList[fromIndexPath.section]
        var toSection = sectionCellList[to.section]
        var fromSectionTodoGroup = fromSection.data as? TodoGroup
        var toSectionTodoGroup = toSection.data as? TodoGroup
        
        if let _ = fromSectionTodoGroup,
           let _ = toSectionTodoGroup {
            
            // same section
            if fromIndexPath.section == to.section {
                
                let todo = fromSectionTodoGroup!.todos.remove(at: fromIndexPath.row - 1)
                fromSectionTodoGroup!.todos.insert(todo, at: to.row - 1 )
                
                fromSection.data = fromSectionTodoGroup
                sectionCellList[fromIndexPath.section] = fromSection
            } else {
                
                let todo = fromSectionTodoGroup!.todos.remove(at: fromIndexPath.row - 1)
                toSectionTodoGroup!.todos.insert(todo, at: to.row - 1)
                
                fromSection.data = fromSectionTodoGroup
                sectionCellList[fromIndexPath.section] = fromSection
                
                toSection.data = toSectionTodoGroup
                sectionCellList[to.section] = toSection
            }
        }

        printSectionCellData()
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var target = proposedDestinationIndexPath
            
        target.row = max( 1, target.row )
        
        return target
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
