//
//  XYZTodoDetailTimeTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 12/14/20.
//

import UIKit

class XYZTodoDetailTimeTableViewCell: UITableViewCell {

    @IBOutlet weak var select: UISwitch!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBAction func timePickerChanged(_ sender: Any) {
        
    }
    
    @IBAction func selectChanged(_ sender: Any) {
    
        timePicker.isEnabled = select.isOn
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        select.isOn = false
        timePicker.isEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
