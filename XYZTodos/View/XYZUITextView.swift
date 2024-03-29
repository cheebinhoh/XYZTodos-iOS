//
//  XYZUITextView.swift
//  XYZTodos
//
//  Created by Chee Bin HOH on 10/30/20.
//
//  Copyright © 2020 - 2021 Chee Bin HOH. All rights reserved.
//

import UIKit

extension UITextField {
    
    func addDoneToolbar(onDone: (target: Any, action: Selector)?) {
        
        let (target, action) = onDone ?? (target: self, action:#selector(doneButtonTapped))
        
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done".localized(), style: .done, target: target, action: action)
        ]
        
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
    }
    
    @objc
    func doneButtonTapped() {
        
        self.resignFirstResponder()
    }
}
