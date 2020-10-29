//
//  XYZTodoTableViewController.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//

import UIKit

class XYZTodoTableViewController: UITableViewController {

    var sectionCellList = [TableViewSectionCell]()
    
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
        
            let dow = dayOfWeek.rawValue.localized()
            
            let groupSection = TableViewSectionCell(identifier: dow,
                                                    title: nil,
                                                    cellList: [dow],
                                                    data: nil)
            if hitTodayDoW {
                
                sectionCellListAfterAndTodayDoW.append(groupSection)
            } else {
                
                hitTodayDoW = dow == todayDoW
                if hitTodayDoW {
                 
                    sectionCellListAfterAndTodayDoW.append(groupSection)
                } else {
                    
                    sectionCellListBeforeTodayDoW.append(groupSection)
                }
            }
        }
        
        sectionCellList.append(contentsOf: sectionCellListAfterAndTodayDoW)
        sectionCellList.append(contentsOf: sectionCellListBeforeTodayDoW)
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
        
        return sectionCellList[section].cellList.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 0 ? 35 : 2.0 // 17.5
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
        let cellId = sectionCellList[indexPath.section].cellList[indexPath.row]
        
        switch sectionId {
        
            default:
                if indexPath.row <= 0 {

                    guard let newcell = tableView.dequeueReusableCell(withIdentifier: "todosTableViewCell", for: indexPath) as? XYZTodoTableViewCell else {
                        
                        fatalError("Exception: error on creating todosTableViewCell")
                    }
                    
                    newcell.title.text = cellId
                    cell = newcell
                } else {
                    
                    fatalError("Exception: error that \(indexPath.row) <= 0")
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
