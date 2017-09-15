//
//  PatronageOptionTableViewCell.swift
//  PatronKit
//
//  Created by Moshe Berman on 2/11/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit

class PatronageOptionTableViewCell: UITableViewCell {

    var productLabel: UILabel = UILabel()
    var priceLabel : RoundedLabel = RoundedLabel()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.productLabel.translatesAutoresizingMaskIntoConstraints = false
        self.priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if(self.contentView.subviews.contains(self.productLabel))
        {
            self.contentView.removeConstraints(self.productLabel.constraints)
            self.productLabel.removeFromSuperview()
        }
        
        if(self.subviews.contains(self.priceLabel))
        {
            self.contentView.removeConstraints(self.priceLabel.constraints)
            self.priceLabel.removeFromSuperview()
        }
        
        self.contentView.addSubview(self.productLabel)
        self.contentView.addSubview(self.priceLabel)
        
        let views = ["productLabel" : productLabel, "priceLabel" : priceLabel]
        
        let x = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[productLabel]-20-[priceLabel(64@1000)]-|", options: [.alignAllCenterY], metrics: nil, views: views)
        
        let y = NSLayoutConstraint.constraints(withVisualFormat: "V:[productLabel(32)]", options: [], metrics: nil, views: views)
        
        let constraints = x + y
        
        self.contentView.addConstraints(constraints)
    }
}
