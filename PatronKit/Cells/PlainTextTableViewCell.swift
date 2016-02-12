//
//  PlainTextTableViewCell.swift
//  PatronKit
//
//  Created by Moshe Berman on 2/11/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit

class PlainTextTableViewCell: UITableViewCell {

    @IBOutlet weak var primaryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
