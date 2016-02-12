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

        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if (self.contentView.subviews.contains(self.primaryLabel))
        {
            self.contentView.removeConstraints(self.primaryLabel.constraints)
        }
        
        self.contentView.addSubview(self.primaryLabel)
        
        let views = ["primaryLabel" : self.primaryLabel]
        
        let x = NSLayoutConstraint.constraintsWithVisualFormat("H:|-7-[primaryLabel]", options: [NSLayoutFormatOptions.AlignAllCenterY], metrics: nil, views: views)
        self.contentView.addConstraints(x)
    }

}
