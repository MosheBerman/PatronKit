//
//  RoundedLabel.swift
//  PatronKit
//
//  Created by Moshe Berman on 2/11/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit

@IBDesignable class RoundedLabel: UILabel {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        if let tint = UIView.appearance().tintColor {
            self.tintColor = tint
        }
        
        self.backgroundColor = self.tintColor.colorWithAlphaComponent(0.2)
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        self.textAlignment = .Center
        self.textColor = self.tintColor
    }

}
