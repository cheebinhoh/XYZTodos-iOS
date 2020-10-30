//
//  XYZTodoTableViewController.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//

import UIKit

class XYZTodoTableViewController: UITableViewController {

    struct Todo {
        
        var detail: String = ""
        var complete: Bool = false
    }
    
    struct TodoGroup {
        
        var iscollapse = true
        var todos = [Todo]()
        var iscomplete: Bool {
            
            return todos.reduce(true) { (result, todo) -> Bool in
                
                return result && todo.complete
            }
        }
    }
    
    var sectionCellList = [TableViewSectionCell]()
    
    
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
    
    func loadSectionCellData() {

        sectionCellList = []

        let today = Date()
        let dateFormat = DateFormatter()

        dateFormat.dateFormat = "EEEE"
        let todayDoW = dateFormat.string(from: today)

        var sectionCellListBeforeTodayDoW = [TableViewSectionCell]()
        var sectionCellListAfterAndTodayDoW = [TableViewSectionCell]()
        var hitTodayDoW = false
        
        for dayOfWeek in DayOfWeek.allCases {
        
            let dow = dayOfWeek.rawValue
            
            let groupSection = TableViewSectionCell(identifier: dow,
                                                    title: nil,
                                                    cellList: [dow.localized()],
                                                    data: nil)
            if hitTodayDoW {
                
                sectionCellListAfterAndTodayDoW.append(groupSection)
            } else {
                
                hitTodayDoW = dow.localized() == todayDoW
                if hitTodayDoW {
                 
                    sectionCellListAfterAndTodayDoW.append(groupSection)
                } else {
                    
                    sectionCellListBeforeTodayDoW.append(groupSection)
                }
            }
        }
        
        sectionCellList.append(contentsOf: sectionCellListAfterAndTodayDoW)
        sectionCellList.append(contentsOf: sectionCellListBeforeTodayDoW)
        
        let groupSection = TableViewSectionCell(identifier: "Other",
                                                title: nil,
                                                cellList: ["Other".localized()],
                                                data: nil)
        
        sectionCellList.append(groupSection)
        
        loadModelDataIntoSectionCellData()
    }
    
    func reload() {
        
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
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        
        if let todoGroup = todoGroup, !todoGroup.iscollapse {
            
            numTodos = todoGroup.todos.reduce(0, { result, todo -> Int in
            
                            return result + 1
                        })
        }
        
        return sectionCellList[section].cellList.count
                + numTodos
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row <= 0 {
            
            var todoGroup = sectionCellList[indexPath.section].data as? TodoGroup
            
            todoGroup!.iscollapse = !todoGroup!.iscollapse
            sectionCellList[indexPath.section].data = todoGroup
        }
        
        tableView.deselectRow(at: indexPath, animated: false)

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        var height: CGFloat = 2.0
        
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
                        
                        fatalError("Exception: error on creating todosTableViewCell")
                    }
                    
                    if let todoGroup = sectionCellList[indexPath.section].data as? TodoGroup {
                        
                        let hastodos = !todoGroup.todos.isEmpty
                        if hastodos && todoGroup.iscomplete  {
                            
                            newcell.accessoryType = .checkmark
                        } else if hastodos && todoGroup.iscollapse {
                            
                            newcell.accessoryType = .detailButton
                        } else {
                            
                            newcell.accessoryType = .none
                        }
                    } else {
                        
                        newcell.accessoryType = .none
                    }
                    
                    newcell.title.text = sectionCellList[indexPath.section].cellList[0]
                    cell = newcell
                } else {
                    
                    guard let newcell = tableView.dequeueReusableCell(withIdentifier: "todoItemTableViewCell", for: indexPath) as? XYZTodoItemTableViewCell else {
                        
                        fatalError("Exception: error on creating todosTableViewCell")
                    }
                    
                    let todoGroup = sectionCellList[indexPath.section].data as? TodoGroup
                    
                    newcell.detail.text = todoGroup?.todos[indexPath.row - 1].detail
                    cell = newcell
                }
        }

        return cell!
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
