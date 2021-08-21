//
//  XYZMoreAboutTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin HOH on 10/28/20.
//
//  Copyright © 2020 - 2021 Chee Bin HOH. All rights reserved.
//

import UIKit

class XYZMoreAboutTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var textView: UITextView!
    
    
    // MARK: - Function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // the following are necessary to allow textview to stretch according to its content and have multiple lines
        textView.textContainer.maximumNumberOfLines = 0
        textView.isScrollEnabled = false
        textView.sizeToFit()
    }

    override func setSelected(_ selected: Bool,
                              animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
