//
//  XYZTodoDetailTableViewController.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/30/20.
//

import UIKit

class XYZTodoDetailTableViewController: UITableViewController,
                                        XYZSelectionDelegate,
                                        XYZTextViewTableViewCellDelegate {
    
    // MARK: - XYZTextViewTableViewCellDelegate
    
    func textViewDidChange(_ text: String, sender: XYZTextViewTableViewCell ) {
        
        detail = text
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    // MARK: - XYZSelectionDelegate
    
    func selectedItem(_ item: String?,
                      sender: XYZSelectionTableViewController) {
  
        dow = DayOfWeek(rawValue: item!)
        
        if let dow = dow {
            
            dowLocalized = dow.rawValue.localized()
        } else {
            
            dowLocalized = other
        }
        
        tableView.reloadData()
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    // MARK: - IBAction
    
    @IBAction func cancel(_ sender: Any) {
        
        if editmode {
            
            navigationController?.popViewController(animated: true)
        } else {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Property
    
    var sectionCellList = [TableViewSectionCell]()
    var dowLocalized: String?
    var dow: DayOfWeek?
    var detail: String?
    
    // communicate between detail view with list view
    var editmode = false
    var indexPath: IndexPath?
    
    
    // MARK: - Function
    
    func loadModelData() {
        
        if editmode {
               
            dowLocalized = dow?.rawValue.localized() ?? other.localized()
        } else {
        
            dowLocalized = todayDowLocalized
            dow = todayDoW
            
            detail = ""
        }
    }
    
    func loadSectionCellData() {

        sectionCellList = []
        
        let timeSection = TableViewSectionCell(identifier: "Time",
                                                title: nil,
                                                cellList: ["dow"],
                                                data: nil)
        
        sectionCellList.append(timeSection)
        
        let detailSection = TableViewSectionCell(identifier: "Detail",
                                                 title: nil,
                                                 cellList: ["text"],
                                                 data: nil)
        
        sectionCellList.append(detailSection)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = false
        
        if editmode {
            
            navigationItem.title = "Edit todo".localized()
        } else {
            
            navigationItem.title = "New todo".localized()
        }
        
        loadModelData()
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

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return sectionCellList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        
        var height: CGFloat = 5.0
        
        if section == 0 {
            
            height = 35.0
        } 
        
        return height
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        
        return 2.0
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell?
        
        let sectionId = sectionCellList[indexPath.section].identifier
        let cellId = sectionCellList[indexPath.section].cellList[indexPath.row]
        
        switch sectionId {
        
            case "Time":
                switch cellId {
                    case "dow":
                        guard let newcell = tableView.dequeueReusableCell(withIdentifier: "todoDetailSelectionTableViewCell", for: indexPath) as? XYZSelectionTableViewCell else {
                            
                            fatalError("Exception: error on creating todoTableViewCell")
                        }
                        
                        newcell.setSelection( dowLocalized ?? "" )
                        newcell.selectionStyle = .none
                
                        cell = newcell
                        
                    default:
                        fatalError("Exception: unsupported cell id \(cellId)")
                }
                
            case "Detail":
                switch cellId {
                    case "text":
                        guard let newcell = tableView.dequeueReusableCell(withIdentifier: "todoDetailTextViewTableViewCell", for: indexPath) as? XYZTextViewTableViewCell else {
                            
                            fatalError("Exception: error on creating todoTableViewCell")
                        }
                
                        newcell.textview.text = detail
                        newcell.delegate = self
                        cell = newcell
                        
                    default:
                        fatalError("Exception: unsupported cell id \(cellId)")
                }
            
            default:
                fatalError("Exception: unsupported section id \(sectionId)")
        } // switch sectionId

        return cell!
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
    
        let sectionId = sectionCellList[indexPath.section].identifier
        let cellId = sectionCellList[indexPath.section].cellList[indexPath.row]
        
        switch sectionId {
        
            case "Time":
                switch cellId {
                
                    case "dow":
                        let dowsLocalized = DayOfWeek.allCasesStringLocalized
                        let dows = DayOfWeek.allCasesString
                        
                        guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                            
                            fatalError("Exception: error on instantiating SelectionNavigationController")
                        }
                        
                        selectionTableViewController.selectionIdentifier = "dow"
                        selectionTableViewController.setSelections("Day of week".localized(),
                                                                   false,
                                                                   dows,
                                                                   dowsLocalized)
                        
                        selectionTableViewController.setSelections(other,
                                                                   false,
                                                                   [other],
                                                                   [other.localized()])
                        
                        selectionTableViewController.setSelectedItem(dow?.rawValue ?? other)
                        selectionTableViewController.delegate = self
                        
                        let nav = UINavigationController(rootViewController: selectionTableViewController)
                        nav.modalPresentationStyle = .popover
                        
                        self.present(nav, animated: true, completion: nil)
                        
                    default:
                        fatalError("Exception: unsupported cell id \(cellId)")
                } // switch cellId 
        
            default:
                fatalError("Exception: unsupported section id \(sectionId)")
        } // switch sectionId
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        guard let returnButton = sender as? UIBarButtonItem, returnButton == saveButton else {
        
            return
        }
    }
}
