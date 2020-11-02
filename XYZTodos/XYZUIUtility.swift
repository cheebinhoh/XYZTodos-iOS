//
//  XYZUIUtility.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/28/20.
//

import UIKit
import CoreData
import CloudKit

// MARK: - Type

struct TableViewSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]()
    var data: Any?
}


// Mark: - Function

func createAttributeText(text: String,
                         font: UIFont,
                         link: String? = nil) -> NSMutableAttributedString {
    
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

func createDownDisclosureIndicatorImage() -> UIImageView {
    
    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 20, y: 20),
                                              size: CGSize(width: 18, height: 15)))
    imageView.image = UIImage(named: "down_disclosure_indicator")
    
    return imageView
}




