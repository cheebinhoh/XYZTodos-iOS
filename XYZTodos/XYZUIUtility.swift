//
//  XYZUIUtility.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//

import UIKit

struct TableViewSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]()
    var data: Any?
}

func createAttributeText(text: String, font: UIFont, link: String? = nil) -> NSMutableAttributedString {
    
    var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
    
    if #available(iOS 13.0, *) {
        
        attributes[NSAttributedString.Key.foregroundColor] = UIColor.label
    } else {
        
        // Fallback on earlier versions
    }
    
    if let link = link {
        
        attributes[NSAttributedString.Key.link] = link
    }
    
    return NSMutableAttributedString(string: text, attributes: attributes)
}
