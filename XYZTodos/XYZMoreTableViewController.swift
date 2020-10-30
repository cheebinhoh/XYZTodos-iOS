//
//  XYZMoreTableViewController.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//

import UIKit

class XYZMoreTableViewController: UITableViewController {

    // MARK: - Property
    
    var sectionCellList = [TableViewSectionCell]()
    
    
    // MARK: - Function
    
    func loadSectionCellData() {

        let aboutSection = TableViewSectionCell(identifier: "about",
                                                title: nil,
                                                cellList: ["about"],
                                                data: nil)
        sectionCellList.append(aboutSection)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        loadSectionCellData()
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        let sectionId = sectionCellList[indexPath.section].identifier
        let cellId = sectionCellList[indexPath.section].cellList[indexPath.row]
        
        switch sectionId {
        
            case "about":
                switch cellId {
                    
                    case "about" :
                        guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                            
                            fatalError("Exception: error on creating moreTableViewCell")
                        }
                        
                        newcell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                        newcell.title.text = "About".localized()
                        cell = newcell
                        
                    default:
                        fatalError("Exception: unsupport cell id \(cellId)")
                        break;
                }
        
            default:
                fatalError("Exception: unsupport section id \(sectionId)")
        }

        return cell!
    }
    
    func showAbout() {
        
        guard let moreAboutNavigator = self.storyboard?.instantiateViewController(withIdentifier: "moreAboutNavigator") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating moreAboutNavigator")
        }

        self.present(moreAboutNavigator, animated: false, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sectionId = sectionCellList[indexPath.section].identifier
        let cellId = sectionCellList[indexPath.section].cellList[indexPath.row]
        
        switch sectionId {
        
            case "about":
                switch cellId {
                    case "about":
                        showAbout()
                        
                    default:
                        fatalError("Exception: unsupport cell id \(cellId)")
                }
                
            default:
                fatalError("Exception: Unsupport section id \(sectionId)")
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 0 ? 35 : 17.5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionCellList[section].title
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
