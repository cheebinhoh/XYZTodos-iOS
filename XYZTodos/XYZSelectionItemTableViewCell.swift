//
//  XYZSelectionItemTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/30/20.
//

import UIKit

class XYZSelectionItemTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    var color = UIColor.clear
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        colorView.backgroundColor = color
        // Configure the view for the selected state
    }

}
