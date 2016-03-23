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
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
        
        // Horizontal Axis
        let productLabelLeading : NSLayoutConstraint = NSLayoutConstraint(item: productLabel, attribute: .Leading, relatedBy: .Equal, toItem: self.contentView, attribute: .Leading, multiplier: 1, constant: 15.0)
        let productLabelPriceLabelSpacing : NSLayoutConstraint = NSLayoutConstraint(item: productLabel, attribute: .Trailing, relatedBy: .Equal, toItem: priceLabel, attribute: .Leading, multiplier: 1.0, constant: 10.0)
        productLabelPriceLabelSpacing.priority = 750
        
        let priceLabelWidth : NSLayoutConstraint = NSLayoutConstraint(item: priceLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 60)
        priceLabelWidth.priority = UILayoutPriorityRequired
        
        let priceLabelTrailing : NSLayoutConstraint = NSLayoutConstraint(item: priceLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self.contentView, attribute: .TrailingMargin, multiplier: 1.0, constant: 10)
        
        // Vertical Axis
        let productLabelHeight : NSLayoutConstraint = NSLayoutConstraint(item: productLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 35.0)
        let priceLabelHeight : NSLayoutConstraint = NSLayoutConstraint(item: priceLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 25.0)
        
        let productLabelCenterOnPriceLabel : NSLayoutConstraint = NSLayoutConstraint(item: priceLabel, attribute: .CenterY, relatedBy: .Equal, toItem: productLabel, attribute: .CenterY, multiplier: 1.0, constant:0.0)
        let productLabelCenterY : NSLayoutConstraint = NSLayoutConstraint(item: productLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
        
        let constraints = [productLabelLeading, productLabelPriceLabelSpacing, priceLabelWidth, priceLabelTrailing, productLabelHeight, priceLabelHeight, productLabelCenterOnPriceLabel, productLabelCenterY]
        
        self.contentView.addConstraints(constraints)
    }
}
