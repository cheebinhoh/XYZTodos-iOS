//
//  XYZMoreAboutTableViewController.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//

import UIKit

class XYZMoreAboutTableViewController: UITableViewController {

    var sectionCellList = [TableViewSectionCell]()
    
    func loadSectionCellData() {

        let aboutSection = TableViewSectionCell(identifier: "about",
                                                title: nil,
                                                cellList: ["copyright"],
                                                data: nil)
        sectionCellList.append(aboutSection)
        
        let creditSection = TableViewSectionCell(identifier: "credit",
                                                 title: nil,
                                                 cellList: ["credit"],
                                                 data: nil)
        
        sectionCellList.append(creditSection)
    }
    
    func showBarButtons() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal)
        backButton.setTitle(" \("Back")", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        
        showBarButtons()
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        let cellId = sectionCellList[indexPath.section].cellList[indexPath.row]
        
        switch cellId {
            
            case "copyright" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreAboutTableViewCell", for: indexPath) as? XYZMoreAboutTableViewCell else {
                    
                    fatalError("Exception: error on creating moreAboutTableViewCell")
                }
                
                let appName = """
                
                \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "")
                """
                
                let textVersion
                    = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                
                let authorName = """
                Chee Bin HOH

                """
                
                let copyrightText = createAttributeText(text: appName,
                                                        font: newcell.textView.font!,
                                                        link: "https://apps.apple.com/us/app/xyztodos-what-is-next/id1537702920")
                
                let authorPreText = createAttributeText(text: " (\(textVersion)) \("was created by ")",
                                                        font: newcell.textView.font!)
                
                copyrightText.append(authorPreText)
                
                let authorText = createAttributeText(text: authorName,
                                                     font: newcell.textView.font!,
                                                     link: "https://www.linkedin.com/in/cheebinhoh")
                
                copyrightText.append(authorText)
                
                newcell.textView.attributedText = copyrightText
                cell = newcell
                
            case "credit":
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreAboutTableViewCell", for: indexPath) as? XYZMoreAboutTableViewCell else {
                    
                    fatalError("Exception: error on creating moreAboutTableViewCell")
                }
                
                let preText = """
                
                \("The icons are from Noun Project by")

                """
                
                let attributeCreditText = createAttributeText(text: preText, font: newcell.textView.font!)
                
                let authorText = """
                \("Kimmi Studio")

                """
                
                let attributeAuthorText = createAttributeText(text: authorText,
                                                              font: newcell.textView.font!,
                                                              link: "https://thenounproject.com/KimmiStudio/")
                attributeCreditText.append(attributeAuthorText)

                newcell.textView.attributedText = attributeCreditText
                cell = newcell
            
                    
            default:
                fatalError("Unsupport more table view cell \(cellId)")
                break;
        }

        return cell!
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
