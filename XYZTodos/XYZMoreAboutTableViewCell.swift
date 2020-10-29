//
//  XYZMoreAboutTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//

import UIKit

class XYZMoreAboutTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        textView.textContainer.maximumNumberOfLines = 0
        textView.isScrollEnabled = false
        textView.sizeToFit()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
