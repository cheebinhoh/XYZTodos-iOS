//
//  XYZTodoDetailTimeTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin HOH on 12/14/20.
//
//  Copyright © 2020 - 2021 Chee Bin HOH. All rights reserved.
//

import UIKit

@objc
protocol XYZTodoDetailTimeTableViewCellDelegate: AnyObject {

    func timeChanged(select: Bool, time: Date, sender: XYZTodoDetailTimeTableViewCell)
}

class XYZTodoDetailTimeTableViewCell: UITableViewCell {

    weak var delegate: XYZTodoDetailTimeTableViewCellDelegate?
    
    @IBOutlet weak var select: UISwitch!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBAction func timePickerChanged(_ sender: Any) {
        
        delegate?.timeChanged(select: select.isOn,
                              time: timePicker.date,
                              sender: self)
    }
    
    @IBAction func selectChanged(_ sender: Any) {
    
        timePicker.isEnabled = select.isOn

        delegate?.timeChanged(select: select.isOn,
                              time: timePicker.date,
                              sender: self)
    }
    
    func setValues(select: Bool, time: Date) {
        
        self.select.isOn = select
        self.timePicker.date = time
        
        self.timePicker.isEnabled = select
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
