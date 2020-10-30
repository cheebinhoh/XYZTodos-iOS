//
//  XYZMoreTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//

import UIKit

class XYZMoreTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var title: UILabel!
    

    // MARK: - Function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
