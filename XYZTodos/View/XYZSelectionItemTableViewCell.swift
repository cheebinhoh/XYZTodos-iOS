//
//  XYZSelectionItemTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/30/20.
//
//  Copyright © 2020 - 2021 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZSelectionItemTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    var color = UIColor.clear
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool,
                              animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
