//
//  XYZSelectionTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin HOH on 10/30/20.
//
//  Copyright © 2020 - 2021 Chee Bin HOH. All rights reserved.
//

import UIKit

class XYZSelectionTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selection: UILabel!

    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool,
                              animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    func setLabel(_ label: String) {
        
        self.label.text = label
    }
    
    func setSelection(_ selection: String, textColor: UIColor? = nil) {
        
        self.selection.text = selection.localized()
        
        if let textColor = textColor {
            
            self.selection.textColor = textColor
        }
    }
    
    func setSeletionTextColor(_ color: UIColor) {
    
        self.selection.textColor = color
    }
}
