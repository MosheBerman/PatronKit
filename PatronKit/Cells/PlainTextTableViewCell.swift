//
//  PlainTextTableViewCell.swift
//  PatronKit
//
//  Created by Moshe Berman on 2/11/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit

class PlainTextTableViewCell: UITableViewCell {

    var primaryLabel: UILabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if (self.contentView.subviews.contains(self.primaryLabel))
        {
            self.contentView.removeConstraints(self.primaryLabel.constraints)
        }
        
        self.contentView.addSubview(self.primaryLabel)
        
        let views = ["primaryLabel" : self.primaryLabel]
        
        let x = NSLayoutConstraint.constraintsWithVisualFormat("H:|-15-[primaryLabel]-|", options: [], metrics: nil, views: views)
        let y = NSLayoutConstraint.constraintsWithVisualFormat("V:[primaryLabel(35@1000)]", options: [], metrics: nil, views: views)
        let center : NSLayoutConstraint = NSLayoutConstraint(item: primaryLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        
        let constraints = x + y + [center]
        
        self.contentView.addConstraints(constraints)
    }

}
