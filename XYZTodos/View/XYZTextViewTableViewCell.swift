//
//  XYZTextTableViewCell.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/30/20.
//
//  Copyright © 2020 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

@objc
protocol XYZTextViewTableViewCellDelegate: AnyObject {

    func textViewDidChange(_ text: String, sender: XYZTextViewTableViewCell)
    func textViewDidBeginEditing(sender: XYZTextViewTableViewCell)
    func textViewDidEndEditing(sender: XYZTextViewTableViewCell)
}

class XYZTextViewTableViewCell: UITableViewCell,
                                UITextViewDelegate {

    // MARK: - Property
    
    var delegate: XYZTextViewTableViewCellDelegate?
    
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var textview: UITextView!
    
    
    // MARK: - function

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        textview.textContainer.maximumNumberOfLines = 0
        textview.isScrollEnabled = false
        textview.sizeToFit()
        
        textview.delegate = self

        let (target, action) = (target: self, action:#selector(doneButtonTapped))
        let toolbar = UIToolbar()
        
        toolbar.barStyle = .default
        toolbar.items = [
            
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done".localized(), style: .done, target: target, action: action)
        ]
        
        toolbar.sizeToFit()
        textview.inputAccessoryView = toolbar
    }
    
    @objc
    func doneButtonTapped() {
        
        textview.resignFirstResponder()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        delegate?.textViewDidChange(textview.text, sender: self)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        delegate?.textViewDidChange(textview.text, sender: self)
        delegate?.textViewDidEndEditing(sender: self)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        delegate?.textViewDidBeginEditing(sender: self)
    }
    
    override func setSelected(_ selected: Bool,
                              animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
