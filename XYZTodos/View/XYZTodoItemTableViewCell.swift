//
//  XYZTodoItemTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin HOH on 10/29/20.
//
//  Copyright © 2020 - 2021 Chee Bin HOH. All rights reserved.
//

import UIKit

class XYZTodoItemTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var time: UILabel!
    
    // MARK: - Function
    
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
