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
        
        var dow: DayOfWeek?
        var collapse = true
        var todos = [Todo]()
        var complete: Bool {
            
            return todos.reduce(true) { (result, todo) -> Bool in
                
                return result && todo.complete
            }
        }
    }
    
    
    // MARK: - Property
    
    var sectionCellList = [TableViewSectionCell]() {
        
        didSet {
            
            let hasNoCollapse = sectionCellList.contains {
            
                    guard let todoGroup = $0.data as? TodoGroup else {
                        
                        return true
                    }
                    
                    return !todoGroup.collapse
                }
            
            self.navigationItem.leftBarButtonItem?.isEnabled = hasNoCollapse
        }
    }
    
    
    //MARK: IBAction
    
    @IBAction func unwindToTodoList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? XYZTodoDetailTableViewController {
            
            if sourceViewController.editmode {
                
                editTodo(dow: sourceViewController.dow, detail: sourceViewController.detail!, existing: sourceViewController.indexPath!)
            } else {
                
                addTodo(dow: sourceViewController.dow, detail: sourceViewController.detail!)
            }
        }
    }
    
    
    // MARK: - Function

    func editTodo(dow: DayOfWeek?,
                  detail: String,
                  existing indexPath: IndexPath) {
        
        let sectionId = dow?.rawValue ?? other
        var originalSection = sectionCellList[indexPath.section]
        let todo = Todo(detail: detail, complete: false)
        
        if sectionId == originalSection.identifier {
            
            var originalTodoGroup = originalSection.data as! TodoGroup
            let originalRow = indexPath.row - 1
            
            originalTodoGroup.todos[originalRow] = todo
            
            originalSection.data = originalTodoGroup
            sectionCellList[indexPath.section] = originalSection
            
            editTodoInManagedContext(oldGroup: sectionId,
                                     oldSequenceNr: originalRow,
                                     newGroup: sectionId,
                                     newSequenceNr: originalRow,
                                     detail: detail,
                                     complete: false)
        } else {
            
            var originalTodoGroup = originalSection.data as! TodoGroup
            let originalRow = indexPath.row - 1
            
            originalTodoGroup.todos.remove(at: originalRow)
            originalSection.data = originalTodoGroup
            sectionCellList[indexPath.section] = originalSection
            
            let targetSectionIndex = sectionCellList.firstIndex {
                
                return $0.identifier == sectionId
            }
            
            var targetSection = sectionCellList[targetSectionIndex!]
            var targetTodoGroup = targetSection.data as! TodoGroup
            
            targetTodoGroup.todos.append(todo)
            targetSection.data = targetTodoGroup
            sectionCellList[targetSectionIndex!] = targetSection
            
            editTodoInManagedContext(oldGroup: originalSection.identifier,
                                     oldSequenceNr: originalRow,
                                     newGroup: sectionId,
                                     newSequenceNr: targetTodoGroup.todos.count - 1,
                                     detail: detail,
                                     complete: false)
        } // if sectionId == originalSection.identifier
        
        tableView.reloadData()
    }
    
    func addTodo(dow: DayOfWeek?,
                 detail: String) {
        
        let sectionId = dow?.rawValue ?? other
        
        let dowSectionIndex = sectionCellList.firstIndex {
            
            return sectionId == $0.identifier
        }
    
        if let dowSectionIndex = dowSectionIndex {
            
            var section = sectionCellList[dowSectionIndex]
            var todoGroup = section.data as? TodoGroup
            
            let todo = Todo(detail: detail, complete: false)
            todoGroup?.todos.append(todo)
            todoGroup?.collapse = false
            
            section.data = todoGroup
            sectionCellList[dowSectionIndex] = section
            
            addTodoToManagedContext(group: sectionId,
                                    sequenceNr: todoGroup!.todos.count - 1,
                                    detail: detail,
                                    complete: false)
            
            tableView.reloadData()
        }
    }
    
    func loadModelDataIntoSectionCellData() {
        
        let todosInStored = getTodosFromManagedContext()
        var loadedSectionCellList = [TableViewSectionCell]()
        
        for var section in sectionCellList {
            
            let dow = section.identifier
            var group = TodoGroup()
            
            group.dow = DayOfWeek(rawValue: section.identifier)
            
            for todoInStored in todosInStored {
                
                let groupInStored = todoInStored.value(forKey: XYZTodo.group) as? String ?? other
                
                if dow == groupInStored {
                    
                    let detail = todoInStored.value(forKey: XYZTodo.detail) as? String ?? ""
                    let complete = todoInStored.value(forKey: XYZTodo.complete) as? Bool ?? false
                    
                    let todo = Todo(detail: detail, complete: complete)
                    group.todos.append(todo)
                }
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
        
        var hitStartOfTheWeek = false
        var trailingSectinoCellList = [TableViewSectionCell]()
        
        for dayOfWeek in DayOfWeek.allCases {
        
            let dow = dayOfWeek.rawValue
            let dowlocalized = dow.localized()
            
            let groupSection = TableViewSectionCell(identifier: dow,
                                                    title: nil,
                                                    cellList: [dowlocalized],
                                                    data: nil)
            
            if hitStartOfTheWeek
                || dayOfWeek.weekDayNr == firstWeekDay {
                
                hitStartOfTheWeek = true
                sectionCellList.append(groupSection)
            } else {
                
                trailingSectinoCellList.append(groupSection)
            }
        }
        
        sectionCellList.append(contentsOf: trailingSectinoCellList)
        
        let groupSection = TableViewSectionCell(identifier: other,
                                                title: nil,
                                                cellList: [other.localized()],
                                                data: nil)
        
        sectionCellList.append(groupSection)
        
        loadModelDataIntoSectionCellData()
    }
    
    func reloadData() {
        
        loadSectionCellData()
        tableView.reloadData()
    }

    func expandTodos(dows: [DayOfWeek]) {
        
        var expndedSectionCellList = [TableViewSectionCell]()
        
        for var section in sectionCellList {
            
            var group = section.data as? TodoGroup
            
            if let dow = DayOfWeek(rawValue: section.identifier),
               dows.contains(dow) {
        
                group!.collapse = false
            } else {
                
                group!.collapse = true
            }

            section.data = group
            expndedSectionCellList.append(section)
        }
        
        sectionCellList = expndedSectionCellList
        
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        loadSectionCellData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.leftBarButtonItem?.isEnabled = false
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return sectionCellList.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        let todoGroup = sectionCellList[section].data as? TodoGroup
        
        var numTodos = 0
        
        if let todoGroup = todoGroup, !todoGroup.collapse {
            
            numTodos = todoGroup.todos.count
        }
        
        return sectionCellList[section].cellList.count
                + numTodos
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row <= 0 {
            
            var todoGroup = sectionCellList[indexPath.section].data as? TodoGroup
           
            if !todoGroup!.todos.isEmpty {
                
                todoGroup!.collapse = !todoGroup!.collapse
                sectionCellList[indexPath.section].data = todoGroup
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        
        var height: CGFloat = 5.0
        
        if section == 0 {
            
            height = 35.0
        } else if section == sectionCellList.count - 1 {
            
            height = 15.0
        }
        
        return height
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        
        return 2.0
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        
        return sectionCellList[section].title
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
                        let collapse = todoGroup.collapse
                        let complete = todoGroup.complete
                        
                        if hastodos {
                            
                            if complete {
                                
                                newcell.accessoryType = .checkmark
                                newcell.accessoryView = nil
                            } else {
                                
                                if collapse {
                                    
                                    newcell.accessoryType = .disclosureIndicator
                                    newcell.accessoryView = nil
                                } else {
                                    
                                    newcell.accessoryType = .none
                                    newcell.accessoryView = createDownDisclosureIndicatorImage()
                                }
                            }
                        } else {
                            
                            newcell.accessoryType = .none
                            newcell.accessoryView = nil
                        }
                    } else {
                        
                        newcell.accessoryType = .none
                        newcell.accessoryView = nil
                    }
                    
                    let isTheDoW = todayDoW.rawValue == sectionId
                    if isTheDoW {
                        
                        newcell.title.textColor = UIColor.systemBlue
                    } else {
                        
                        newcell.title.textColor = nil
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

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()

        if indexPath.row > 0 {
            
            let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
                
                var section = self.sectionCellList[indexPath.section]
                var todoGroup = section.data as! TodoGroup
                
                todoGroup.todos.remove(at: indexPath.row - 1)
                todoGroup.collapse = todoGroup.todos.isEmpty
                section.data = todoGroup
                self.sectionCellList[indexPath.section] = section
                
                deleteTodoFromManagedContext(group: section.identifier, sequenceNr: indexPath.row - 1)
                
                tableView.reloadData()
                
                handler(true)
            }
            
            commands.append(delete)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let complete = UIContextualAction(style: .destructive, title: "Done".localized()) { _, _, handler in

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
                
                editTodoInManagedContext(oldGroup: self.sectionCellList[indexPath.section].identifier,
                                         oldSequenceNr: indexPath.row - 1,
                                         newGroup: self.sectionCellList[indexPath.section].identifier,
                                         newSequenceNr: indexPath.row - 1,
                                         detail: todoGroup!.todos[indexPath.row - 1].detail,
                                         complete: todoGroup!.todos[indexPath.row - 1].complete)
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
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return indexPath.row > 0
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
                
        if editingStyle == .delete {
            // Delete the row from the data source
            
            var section = sectionCellList[indexPath.section]
            var todoGroup = section.data as! TodoGroup
            
            todoGroup.todos.remove(at: indexPath.row - 1)
            todoGroup.collapse = todoGroup.todos.isEmpty
            section.data = todoGroup
            sectionCellList[indexPath.section] = section
            
            deleteTodoFromManagedContext(group: section.identifier, sequenceNr: indexPath.row - 1)
            
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            
            fatalError("Exception: yet to be implemented")
        }    
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView,
                            moveRowAt fromIndexPath: IndexPath,
                            to: IndexPath) {

        var fromSection = sectionCellList[fromIndexPath.section]
        var toSection = sectionCellList[to.section]
        var fromSectionTodoGroup = fromSection.data as? TodoGroup
        var toSectionTodoGroup = toSection.data as? TodoGroup
        
        if let _ = fromSectionTodoGroup,
           let _ = toSectionTodoGroup {
  
            let fromRow = fromIndexPath.row - 1
            let toRow = to.row - 1
            
            var todo = fromSectionTodoGroup!.todos.remove(at: fromRow)
            todo.complete = false
            
            // same section
            if fromIndexPath.section == to.section {
                
                var fromIndexBase = 0
                for section in sectionCellList {
                    
                    if section.identifier == fromSection.identifier {
                        
                        break
                    }
                    
                    fromIndexBase = fromIndexBase + ( section.data as? TodoGroup )!.todos.count
                }
                
                moveTodoInManagedContext(fromIndex: fromIndexBase + fromRow,
                                         toIndex: fromIndexBase + toRow)
                
                fromSectionTodoGroup!.todos.insert(todo, at: toRow)
                
                fromSection.data = fromSectionTodoGroup
                sectionCellList[fromIndexPath.section] = fromSection
            } else {
                
                // we add the todo to the last item of new section
                // we then move the todo within that section to the intended position
                
                deleteTodoFromManagedContext(group: fromSection.identifier,
                                             sequenceNr: fromRow )
                
                addTodoToManagedContext(group: toSection.identifier,
                                        sequenceNr: toRow,
                                        detail: todo.detail,
                                        complete: false)
                
                toSectionTodoGroup!.todos.insert(todo, at: toRow)
                
                fromSectionTodoGroup!.collapse = fromSectionTodoGroup!.todos.isEmpty
                fromSection.data = fromSectionTodoGroup
                sectionCellList[fromIndexPath.section] = fromSection
                
                toSectionTodoGroup!.collapse = false
                toSection.data = toSectionTodoGroup
                sectionCellList[to.section] = toSection
                
                
                /*
                let newToGroupIndex = toSectionTodoGroup!.todos.count
                editTodoInManagedContext(oldGroup: fromSection.identifier,
                                         oldSequenceNr: fromRow,
                                         newGroup: toSection.identifier,
                                         newSequenceNr: newToGroupIndex,
                                         detail: todo.detail,
                                         complete: false)
                
                toSectionTodoGroup!.todos.insert(todo, at: toRow)
                
                fromSectionTodoGroup!.collapse = fromSectionTodoGroup!.todos.isEmpty
                fromSection.data = fromSectionTodoGroup
                sectionCellList[fromIndexPath.section] = fromSection
                
                toSectionTodoGroup!.collapse = false
                toSection.data = toSectionTodoGroup
                sectionCellList[to.section] = toSection
                
                var toIndexBase = 0
                for section in sectionCellList {
                    
                    if section.identifier == toSection.identifier {
                        
                        break
                    }
                    
                    toIndexBase = toIndexBase + ( section.data as? TodoGroup )!.todos.count
                }
                
                moveTodoInManagedContext(fromIndex: toIndexBase + newToGroupIndex,
                                         toIndex: toIndexBase + toRow)
                */
            }//  if fromIndexPath.section == to.section ... else
        }

        tableView.reloadData()
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var target = proposedDestinationIndexPath
            
        target.row = max( 1, target.row )
        
        return target
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        
            case "showTodoDetail":
                guard let todoDetalTableViewController = segue.destination as? XYZTodoDetailTableViewController else {
                    
                    fatalError("Exception: error in casting destination as XYZTodoDetailTableViewController")
                }
                
                guard let cell = sender as? XYZTodoItemTableViewCell else {
                    
                    fatalError("Exception: error in casting sender as XYZTodoItemTableViewCell")
                }
                
                guard let indexPath = tableView.indexPath(for: cell) else {
                    
                    fatalError("Exception: error in indexPath")
                }
                
                let section = sectionCellList[indexPath.section]
                let todoGroup = section.data as? TodoGroup
                let todo = todoGroup!.todos[indexPath.row - 1]
                
                todoDetalTableViewController.dow = todoGroup!.dow
                todoDetalTableViewController.detail = todo.detail
                todoDetalTableViewController.editmode = true
                todoDetalTableViewController.indexPath = indexPath
                
            default:
                break
        }
    }

    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard indexPath.row > 0 else {
            
            return nil
        }
        
        let section = sectionCellList[indexPath.section]
        let todoGroup = section.data as? TodoGroup
        let detail = todoGroup!.todos[indexPath.row - 1].detail
        
        return UIContextMenuConfiguration( identifier: nil,
                                           previewProvider: {
                                            
                                                let viewController = UIViewController()
                                                
                                                // 1
                                                let textview = UITextView()
                                                textview.text = detail
                                                textview.font = UIFont.systemFont(ofSize: 16)
                                                textview.isScrollEnabled = true
                                                textview.sizeToFit()
                                                textview.translatesAutoresizingMaskIntoConstraints = true
                                                textview.textContainer.maximumNumberOfLines = 0
                                                textview.showsVerticalScrollIndicator = true
                                                textview.isUserInteractionEnabled = true
                                                textview.isSelectable = true
                                                textview.isEditable = false 
                                                //textview.scrollRangeToVisible(NSMakeRange(0, 0))
                                            
                                                // 2
                                                textview.frame = CGRect(x: 0,
                                                                        y: 0,
                                                                        width: 420,
                                                                        height: max( 400,
                                                                                     textview.contentSize.height) )
        
                                                // 3
                                                //viewController.preferredContentSize = textview.frame.size
                                                viewController.view = textview
                                            
                                                return viewController
                                           },
                                           actionProvider: { _ in
                                            
                                                let children: [UIMenuElement] = []
                                            
                                                return UIMenu(title: "", children: children)
                                           })
    }
    
}
