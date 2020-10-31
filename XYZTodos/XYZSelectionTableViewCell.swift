//
//  XYZSelectionTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/30/20.
//

import UIKit

class XYZSelectionTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selection: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var icon: UIImageView!
    

    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    func setLabel(_ label: String) {
        
        self.label.text = label
    }
    
    func setSelection(_ selection: String) {
        
        self.selection.text = selection.localized()
    }
    
    func setSeletionTextColor(_ color: UIColor) {
    
        self.selection.textColor = color
    }

}
