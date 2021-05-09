//
//  XYZMoreTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//
//  Copyright © 2020 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZMoreTableViewCell: UITableViewCell {

    
    // MARK: - IBOutlet
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var onOff: UISwitch!

    var switchValueChangedAction: ((Bool) -> Void)?
    
    
    // MARK: - Function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        onOff.isHidden = true
        // Initialization code
    }
    
    func enableSwitch(value: Bool,
                      action: @escaping (Bool) -> Void) {
        
        onOff.isOn = value
        onOff.isHidden = false
        onOff.addTarget(self, action: #selector(switchChanged(_:)), for: UIControl.Event.valueChanged)
        
        switchValueChangedAction = action
    }
    
    func disableSwitch() {
        
        onOff.isHidden = true
        switchValueChangedAction = nil
    }
    
    @objc
    func switchChanged(_ switchValue: UISwitch) {
        
        switchValueChangedAction?(switchValue.isOn)
    }

    override func setSelected(_ selected: Bool,
                              animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
