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
        var timeOn = false
        var time = Date()
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
    var dupGroup: String?
    var dupDetail: String?
    var dupTime: Date?
    var dupTimeOn: Bool?
    var indexPathToBeRemovedAfterDup: IndexPath?
    var previewIndexPath: IndexPath?
    var sectionCellList = [TableViewSectionCell]()
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code you want to implement
        
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code here
         
        guard let canUndo = undoManager?.canUndo, canUndo else {
        
            return
        }
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let undoLastChange = UIAlertAction(title: "Undo last change".localized(), style: .default, handler: { (action) in
            
            self.undoManager?.undo()
            self.undoManager?.removeAllActions()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:nil)
        
        optionMenu.addAction(undoLastChange)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    //MARK: IBAction
    
    @IBAction func unwindToTodoList(sender: UIStoryboardSegue) {
        
        if let sourceViewController = sender.source as? XYZTodoDetailTableViewController {
            
            if sourceViewController.editmode {
                
                editTodo(dow: sourceViewController.dow,
                         detail: sourceViewController.detail!,
                         timeOn: sourceViewController.timeOn!,
                         time: sourceViewController.time!,
                         existing: sourceViewController.indexPath!)
            } else {
                
                addTodo(dow: sourceViewController.dow,
                        detail: sourceViewController.detail!,
                        timeOn: sourceViewController.timeOn!,
                        time: sourceViewController.time!)
                
                if let indexPathToBeRemovedAfterDup = indexPathToBeRemovedAfterDup {
                    
                    deleteRow(indexPath: indexPathToBeRemovedAfterDup)
                    undoManager?.removeAllActions()
                }
                
                let groupIdentifier = sourceViewController.dow?.rawValue ?? other
                
                let sectionIndex = sectionCellList.firstIndex {
                    
                    return $0.identifier == groupIdentifier
                }
                
                tableView.scrollToRow(at: IndexPath(row: 0, section: sectionIndex!), at: .top, animated: true)
            }
        }
        
        indexPathToBeRemovedAfterDup = nil
    }
    
    
    // MARK: - Function
    
    func deleteRow(indexPath: IndexPath) {
        
        let row = indexPath.row - 1
        var section = sectionCellList[indexPath.section]
        var todoGroup = section.data as! TodoGroup
        
        let detail = todoGroup.todos[row].detail
        let complete = todoGroup.todos[row].complete
        let dow = todoGroup.dow
        let timeOn = todoGroup.todos[row].timeOn
        let time = todoGroup.todos[row].time
        
        undoManager?.registerUndo(withTarget: self, handler: { (target) in
            
            self.addTodo(dow: dow,
                         detail: detail,
                         timeOn: timeOn,
                         time: time,
                         complete: complete)
        })
        
        todoGroup.todos.remove(at: row)
        todoGroup.collapse = todoGroup.todos.isEmpty
        section.data = todoGroup
        sectionCellList[indexPath.section] = section
        
        deleteTodoFromManagedContext(group: section.identifier, sequenceNr: row)
        
        tableView.reloadData()
    }
    
    func editTodo(dow: DayOfWeek?,
                  detail: String,
                  timeOn: Bool,
                  time: Date,
                  existing indexPath: IndexPath) {
        
        let sectionId = dow?.rawValue ?? other
        var originalSection = sectionCellList[indexPath.section]
        let todo = Todo(detail: detail, timeOn: timeOn, time: time, complete: false)
        
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
                                     timeOn: timeOn,
                                     time: time,
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
                                     timeOn: timeOn,
                                     time: time,
                                     complete: false)
        } // if sectionId == originalSection.identifier
        
        reloadModelData()
    }
    
    func addTodo(dow: DayOfWeek?,
                 detail: String,
                 timeOn: Bool,
                 time: Date,
                 complete: Bool = false) {
        
        let sectionId = dow?.rawValue ?? other
        
        let dowSectionIndex = sectionCellList.firstIndex {
            
            return sectionId == $0.identifier
        }
    
        if let dowSectionIndex = dowSectionIndex {
            
            var section = sectionCellList[dowSectionIndex]
            var todoGroup = section.data as? TodoGroup
            
            let todo = Todo(detail: detail, timeOn: timeOn, time: time, complete: complete)
            todoGroup?.todos.append(todo)
            todoGroup?.collapse = false
            
            section.data = todoGroup
            sectionCellList[dowSectionIndex] = section
            
            addTodoToManagedContext(group: sectionId,
                                    sequenceNr: todoGroup!.todos.count - 1,
                                    detail: detail,
                                    timeOn: timeOn,
                                    time: time,
                                    complete: false)
            
            reloadModelData()
        }
    }
    
    func loadModelDataIntoSectionCell() {
        
        let todosInStored = getTodosFromManagedContext()
        var loadedSectionCellList = [TableViewSectionCell]()
        
        for var section in sectionCellList {
            
            let dow = section.identifier
            var group = TodoGroup()
            
            if let oldGroup = section.data as? TodoGroup {
                
                group.collapse = oldGroup.collapse
            }
            
            group.dow = DayOfWeek(rawValue: section.identifier)
            
            for todoInStored in todosInStored {
                
                let groupInStored = todoInStored.group 
                
                if dow == groupInStored {
                    
                    let detail = todoInStored.detail
                    let complete = todoInStored.complete
                    let timeOn = todoInStored.timeOn
                    let time = todoInStored.time
                    
                    let todo = Todo(detail: detail,
                                    timeOn: timeOn,
                                    time: time,
                                    complete: complete)
                    
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
    
    func loadSectionCellModelData() {

        sectionCellList = []

        for dayOfWeek in DayOfWeek.allCasesStartWithSelectedDayOfWeek {
            
            let dow = dayOfWeek.rawValue
            let dowlocalized = dow.localized()
            
            let groupSection = TableViewSectionCell(identifier: dow,
                                                    title: nil,
                                                    cellList: [dowlocalized],
                                                    data: nil)
            sectionCellList.append(groupSection)
        }
        
        let groupSection = TableViewSectionCell(identifier: other,
                                                title: nil,
                                                cellList: [otherLocalized],
                                                data: nil)
        
        sectionCellList.append(groupSection)
        
        loadModelDataIntoSectionCell()
    }
    
    func reloadModelData() {
        
        loadModelDataIntoSectionCell()
        tableView.reloadData()
    }
    
    func reloadSectionCellModelData() {
        
        loadSectionCellModelData()
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
        
        loadSectionCellModelData()
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
        
        var scrollToIndexPath: IndexPath?
        
        if indexPath.row <= 0 {
            
            var todoGroup = sectionCellList[indexPath.section].data as? TodoGroup
           
            if !todoGroup!.todos.isEmpty {
                
                todoGroup!.collapse = !todoGroup!.collapse
                sectionCellList[indexPath.section].data = todoGroup
                
                scrollToIndexPath = IndexPath(row: Int(todoGroup!.todos.count / 2), section: indexPath.section)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)

        tableView.reloadData()
        
        if let idp = scrollToIndexPath {
            
            DispatchQueue.main.async {
                
                self.tableView.scrollToRow(at: idp, at: .middle, animated: false)
            }
        }
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

                        if hastodos {
      
                            if collapse {
                                
                                newcell.accessoryType = .disclosureIndicator
                                newcell.accessoryView = nil
                            } else {
                                
                                newcell.accessoryType = .none
                                newcell.accessoryView = nil // createDownDisclosureIndicatorImage
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
                    
                    let detailtext = todoGroup?.todos[indexPath.row - 1].detail
                    var time = ""
                    
                    if let timeOn = todoGroup?.todos[indexPath.row - 1].timeOn, timeOn {
                        
                        let timeFormatter = DateFormatter()
                        
                        time = timeFormatter.stringWithShortTime(from: (todoGroup?.todos[indexPath.row - 1].time)!)
                    }
                    
                    newcell.detail.text = detailtext!
                    newcell.time.text = time
                    cell = newcell
                }
        } // switch sectionId

        return cell!
    }
    
    func uiAlertActionToDupTodo(from indexPath:IndexPath) {
        
        let moveToMenu = UIAlertController(title: "Copy to".localized(), message: nil, preferredStyle: .actionSheet)
        
        let cancelMoveToAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (action) in
            
        })
        
        let todoGroup = self.sectionCellList[indexPath.section].data as? TodoGroup
        let todo = todoGroup?.todos[indexPath.row - 1]
        
        for (index, section) in self.sectionCellList.enumerated() {
            
            let dowLocalized = section.identifier.localized()

            let moveToDoW = UIAlertAction(title: dowLocalized, style: .default) { (_) in
                
                self.dupDetail = todo?.detail
                self.dupTime = todo?.time
                self.dupTimeOn = todo?.timeOn
                self.dupGroup = self.sectionCellList[index].identifier
                
                executeAddTodo()
            }
            
            if dowLocalized == todayDowLocalized {
                
                let image = UIImage(named: "Star")
                moveToDoW.setValue(image?.withRenderingMode(.alwaysTemplate), forKey: "image")
            }
            
            moveToMenu.addAction(moveToDoW)
        }
        
        moveToMenu.addAction(cancelMoveToAction)
        self.present(moveToMenu, animated: true, completion: nil)
    }
    
    func uiAlertActionToMoveTodo(from indexPath:IndexPath) {
        
        let moveToMenu = UIAlertController(title: "Move to".localized(), message: nil, preferredStyle: .actionSheet)
        
        let cancelMoveToAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (action) in
            
        })
        
        let todoGroup = self.sectionCellList[indexPath.section].data as? TodoGroup
        let todo = todoGroup?.todos[indexPath.row - 1]
        
        for (index, section) in self.sectionCellList.enumerated() {
            
            let dowLocalized = section.identifier.localized()

            let moveToDoW = UIAlertAction(title: dowLocalized, style: .default) { (_) in
                
                let todoGroup = section.data as? TodoGroup
                
                let toIndexPath = IndexPath(row: (todoGroup?.todos.count ?? 0) + 1 , section: index)
                
                if toIndexPath.section != indexPath.section {
                    
                    self.dupDetail = todo?.detail
                    self.dupTime = todo?.time
                    self.dupTimeOn = todo?.timeOn
                    self.dupGroup = self.sectionCellList[index].identifier
                    self.indexPathToBeRemovedAfterDup = indexPath
                    
                    executeAddTodo()
                }
            }
            
            if dowLocalized == todayDowLocalized {
                
                let image = UIImage(named: "Star")
                moveToDoW.setValue(image?.withRenderingMode(.alwaysTemplate), forKey: "image")
            }
            
            moveToMenu.addAction(moveToDoW)
        }
        
        moveToMenu.addAction(cancelMoveToAction)
        self.present(moveToMenu, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()

        if indexPath.row > 0 {
            
            let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
                
                self.deleteRow(indexPath: indexPath)
                handler(true)
            }
            
            commands.append(delete)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let complete = UIContextualAction(style: .normal, title: "Done".localized()) { _, _, handler in

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
                
                let row = indexPath.row - 1
                let complete = todoGroup?.todos[row].complete
                
                todoGroup?.todos[row].complete = !(complete ?? true)
                
                editTodoInManagedContext(oldGroup: self.sectionCellList[indexPath.section].identifier,
                                         oldSequenceNr: row,
                                         newGroup: self.sectionCellList[indexPath.section].identifier,
                                         newSequenceNr: row,
                                         detail: todoGroup!.todos[row].detail,
                                         timeOn: todoGroup!.todos[row].timeOn,
                                         time: todoGroup!.todos[row].time,
                                         complete: todoGroup!.todos[row].complete)
            }
            
            self.sectionCellList[indexPath.section].data = todoGroup
            tableView.reloadData()
            
            handler(true)
        }
        
        complete.backgroundColor = UIColor.systemBlue
        commands.append(complete)

        let more = UIContextualAction(style: .normal, title: "More".localized()) { _, _, handler in
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (action) in
                
                handler(true)
            })
            
            let moveToAction = UIAlertAction(title: "Move to".localized(), style: .default, handler: { (action) in

                self.uiAlertActionToMoveTodo(from: indexPath)
                handler(true)
            })
            
            let dupToAction = UIAlertAction(title: "Copy to".localized(), style: .default, handler: { (action) in

                self.uiAlertActionToDupTodo(from: indexPath)
                handler(true)
            })
            
            optionMenu.addAction(moveToAction)
            optionMenu.addAction(dupToAction)
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
 
            handler(true)
        }

        more.image = UIImage(named: "More")
        commands.append(more)
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return indexPath.row > 0
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
   
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .none
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
                
        if editingStyle == .delete {
            // Delete the row from the data source
            deleteRow(indexPath: indexPath)
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
                
                // we manipulate in a copy of sectioncelllist so that the didset only triggered once.
                var copiedSectionCellList = sectionCellList;
                
                deleteTodoFromManagedContext(group: fromSection.identifier,
                                             sequenceNr: fromRow )
                
                addTodoToManagedContext(group: toSection.identifier,
                                        sequenceNr: toRow,
                                        detail: todo.detail,
                                        timeOn: todo.timeOn,
                                        time: todo.time,
                                        complete: false)
                
                toSectionTodoGroup!.todos.insert(todo, at: toRow)
                
                fromSectionTodoGroup!.collapse = fromSectionTodoGroup!.todos.isEmpty
                fromSection.data = fromSectionTodoGroup
                copiedSectionCellList[fromIndexPath.section] = fromSection
                
                toSectionTodoGroup!.collapse = false
                toSection.data = toSectionTodoGroup
                copiedSectionCellList[to.section] = toSection
                
                sectionCellList = copiedSectionCellList
            }//  if fromIndexPath.section == to.section ... else
        } // if let _ = fromSectionTodoGroup,
             // let _ = toSectionTodoGroup

        self.reloadModelData()
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView,
                            canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var target = proposedDestinationIndexPath
            
        target.row = max(1, target.row)
        
        return target
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
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
                
                let row = indexPath.row - 1
                let section = sectionCellList[indexPath.section]
                let todoGroup = section.data as? TodoGroup
                let todo = todoGroup!.todos[row]
                
                todoDetalTableViewController.dupmode = false
                todoDetalTableViewController.dupasmove = false
                todoDetalTableViewController.populateEditData(dow: todoGroup!.dow,
                                                              detail: todo.detail,
                                                              timeOn: todo.timeOn,
                                                              time: todo.time,
                                                              indexPath: indexPath)
                indexPathToBeRemovedAfterDup = nil
                
            case "newTodoDetail":
                guard let navController = segue.destination as? UINavigationController else {
                    
                    fatalError("Exception: error in casting destination as UINavigationController")
                }
                
                guard let todoDetalTableViewController = navController.viewControllers.first as? XYZTodoDetailTableViewController else {
                    
                    fatalError("Exception: error in casting destination as XYZTodoDetailTableViewController")
                }
                
                if let _ = dupGroup {
                    
                    todoDetalTableViewController.dowLocalized = dupGroup!.localized()
                    todoDetalTableViewController.dupmode = true
                    todoDetalTableViewController.dupasmove = indexPathToBeRemovedAfterDup != nil
                    todoDetalTableViewController.dow = DayOfWeek(rawValue: dupGroup!)
                    todoDetalTableViewController.detail = dupDetail
                    todoDetalTableViewController.time = dupTime
                    todoDetalTableViewController.timeOn = dupTimeOn
                    
                    dupGroup = nil
                    dupTime = nil
                    dupTimeOn = nil
                    dupDetail = nil
                } else {
                    
                    todoDetalTableViewController.dupmode = false
                    indexPathToBeRemovedAfterDup = nil
                }
                
                break
                
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
        var todoGroup = section.data as? TodoGroup
        let detail = todoGroup!.todos[indexPath.row - 1].detail
        let row = indexPath.row - 1
        let time = todoGroup?.todos[row].time
        let timeOn = todoGroup?.todos[row].timeOn
        let complete = todoGroup?.todos[row].complete
        
        previewIndexPath = indexPath
        
        let cm = UIContextMenuConfiguration( identifier: nil,
                                             previewProvider: {
         
                                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                                guard let vc = storyboard.instantiateViewController(withIdentifier: "TodoPreview") as? XYZTodoPreviewViewController else {
                                                 
                                                    fatalError("Exception: XYZTodoPreviewViewController is expected")
                                                }

                                                let dateFormatter = DateFormatter();
                                                vc.loadView()

                                                if let time = time, let timeOn = timeOn, timeOn {

                                                    vc.time?.text = " " + dateFormatter.stringWithShortTime(from: time)
                                                } else {

                                                    vc.time.text = " -"
                                                    vc.time.isHidden = true
                                                }

                                                vc.detail?.text = detail

                                                return vc
                                             }, // previewProvider

                                            actionProvider: { _ in
                                                
                                                let deleteImage = UIImage(systemName: "delete.left")
                                                let deleteAction = UIAction(title: "Delete".localized(),
                                                                            image: deleteImage,
                                                                            identifier: nil,
                                                                            discoverabilityTitle: nil,
                                                                            attributes: UIMenuElement.Attributes.destructive,
                                                                            state: .off) {_ in
                                                    
                                                    self.deleteRow(indexPath: indexPath)
                                                }
                                                
                                                let completeAction = UIAction(title: "Done".localized(),
                                                                              image: nil,
                                                                              identifier: nil,
                                                                              discoverabilityTitle: nil,
                                                                              attributes: UIMenuElement.Attributes.init(),
                                                                              state: complete! ? .on : .off) {_ in
                                                    
                                                    todoGroup?.todos[row].complete = !(complete!)

                                                    editTodoInManagedContext(oldGroup:  self.sectionCellList[indexPath.section].identifier,
                                                                             oldSequenceNr: row,
                                                                             newGroup: self.sectionCellList[indexPath.section].identifier,
                                                                             newSequenceNr: row,
                                                                             detail: todoGroup!.todos[row].detail,
                                                                             timeOn: todoGroup!.todos[row].timeOn,
                                                                             time: todoGroup!.todos[row].time,
                                                                             complete: todoGroup!.todos[row].complete)
                                                    
                                                    self.sectionCellList[indexPath.section].data = todoGroup
                                                    tableView.reloadData()
                                                }

                                                let moveToAction = UIAction(title: "Move to".localized(),
                                                                            image: nil,
                                                                            identifier: nil,
                                                                            discoverabilityTitle: nil,
                                                                            attributes: UIMenuElement.Attributes.init(), state: .off) {_ in
                                                    
                                                    self.uiAlertActionToMoveTodo(from: indexPath)
                                                }

                                                let dupToAction = UIAction(title: "Copy to".localized(),
                                                                            image: nil,
                                                                            identifier: nil,
                                                                            discoverabilityTitle: nil,
                                                                            attributes: UIMenuElement.Attributes.init(), state: .off) {_ in
                                                    
                                                    self.uiAlertActionToDupTodo(from: indexPath)
                                                }

                                                let children = [completeAction, moveToAction, dupToAction, deleteAction]

                                                return UIMenu(title: "", children: children)
                                            } // actionProvider
            )
        
        return cm
    }
    
    override func tableView(_ tableView: UITableView,
                            previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        
        previewIndexPath = nil
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView,
                            willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                            animator: UIContextMenuInteractionCommitAnimating) {
        
        let cell = tableView.cellForRow(at: previewIndexPath!)
        
        self.performSegue(withIdentifier: "showTodoDetail",
                          sender: cell)
    }
}
