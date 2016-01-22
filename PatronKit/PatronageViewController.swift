//
//  PatronageViewController.swift
//  PatronKit
//
//  Created by Moshe Berman on 1/20/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit
import StoreKit

class PatronageViewController: UITableViewController {
    
    var formatter : NSNumberFormatter = NSNumberFormatter()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    // MARK: - Common initialization
    
    func commonInit() {
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "com.mosheberman.patronage.cell.default")
        
        formatter.numberStyle = .CurrencyStyle
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("com.mosheberman.patronage.cell.default", forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = NSLocalizedString("Why Patronage?", comment: "A title for the cell that when tapped explains patronage.")
            cell.detailTextLabel?.text = nil
        }
        else if indexPath.section == 1 {
            
            let count : Int = PatronManager.sharedManager.products.count
            
            if count == 0 /* there are no products  */
            {
                cell.textLabel?.text = NSLocalizedString("Loading Patronage Levels...", comment: "A title for a cell that is loading patronage information.")
                cell.detailTextLabel?.text = nil
            }
            else {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                let title : String = product.localizedDescription
                var price : String? = NSLocalizedString("---", comment: "A label for when the price isn't available.")
                
                if let productPrice = self.formatter.stringFromNumber(product.price) {
                    price = productPrice
                }
                
                
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = price
            }
        }
        else if indexPath.section == 2 {
            cell.textLabel?.text = NSLocalizedString("Restore Purchases", comment: "A label a button that restores previous purchases.")
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3 // Why patronage, products, restore purchases
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count : Int = 0
        
        if section == 0 {
            count = 1
        }
        else if section == 1 {
            
            count = PatronManager.sharedManager.products.count
            
            if count == 0 // there are no products
            {
                count = 1 // show loading text
            }
            
        }
        else if section == 2 {
            count = 1
        }
        
        return count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == 0 {
            // Your patronage makes possible.
            title = NSLocalizedString("Your patronage makes continued development possible. Thank you.", comment: "A thank you message for the patronage.")
        }
        else if section == 1 {
            // Become/Extend
            
        }
        else if section == 2 {
            // nil
        }
        
        return title
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == 0 {
            // Patronage end date
        }
        else if section == 1 {
            // Number of patrons
        }
        else if section == 2 {
            // Restore/auto-renew disclaimer
        }
        
        return title
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            // TODO: Show some explanation of the patronage model.
        }
        else if indexPath.section == 1 {
            
            if PatronManager.sharedManager.products.count > 0 {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                PatronManager.sharedManager.purchaseProduct(product: product, withCompletionHandler: { (success, error) -> Void in
                    print("Purchase complete. Success: \(success) Error: \(error)")
                })
                
            }
        }
        else if indexPath.section == 2 {
            PatronManager.sharedManager.restorePurchasedProductsWithCompletionHandler(completionHandler: { (success, error) -> Void in
                print("Restore complete. Success: \(success) Error: \(error)")
            })
        }
        
    }
    
}
