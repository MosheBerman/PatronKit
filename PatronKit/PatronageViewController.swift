//
//  PatronageViewController.swift
//  PatronKit
//
//  Created by Moshe Berman on 1/20/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit
import StoreKit

open class PatronageViewController: UITableViewController {
    
    var numberFormatter : NumberFormatter = NumberFormatter()
    var dateFormatter : DateFormatter = DateFormatter()
    var calendar : Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: .grouped)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    // MARK: - Common initialization
    
    func commonInit() {
        
        numberFormatter.numberStyle = .currency
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        
        self.tableView.register(PlainTextTableViewCell.self, forCellReuseIdentifier: "com.patronkit.cell.plain")
        self.tableView.register(PatronageOptionTableViewCell.self, forCellReuseIdentifier: "com.patronkit.cell.loading")
        self.tableView.register(PatronageOptionTableViewCell.self, forCellReuseIdentifier: "com.patronkit.cell.product")
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
        let oneMonth = self.oneUnitBefore(Date(), withUnit: NSCalendar.Unit.month)
        
        PatronManager.sharedManager.fetchPatronageExpiration { (date : Date?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            })
        }
        
        PatronManager.sharedManager.fetchPatronCountSince(date: oneMonth) { (count, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            })
        }
        
        PatronManager.sharedManager.fetchAvailablePatronageProducts { (products, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            })
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell
        
        if indexPath.section == 0 {
            
            let count : Int = PatronManager.sharedManager.products.count
            
            if count == 0 /* there are no products  */
            {
                let loadingCell : PatronageOptionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "com.patronkit.cell.loading", for: indexPath) as! PatronageOptionTableViewCell
                loadingCell.productLabel.text = NSLocalizedString("Loading Patronage Options...", comment: "A title for a cell that is loading patronage information.")
                loadingCell.priceLabel.text = "..."
                
                loadingCell.accessoryType = .none
                
                loadingCell.productLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
                loadingCell.priceLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
                
                cell = loadingCell
            }
            else {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                let title : String = product.localizedTitle
                var price : String? = NSLocalizedString("---", comment: "A label for when the price isn't available.")
                
                self.numberFormatter.locale = product.priceLocale
                
                if let productPrice = self.numberFormatter.string(from: product.price) {
                    price = productPrice
                }
                
                let productCell : PatronageOptionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "com.patronkit.cell.product", for: indexPath) as! PatronageOptionTableViewCell
                productCell.productLabel.text = title
                productCell.priceLabel.text = price
                
                productCell.accessoryType = .disclosureIndicator
                
                productCell.productLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
                productCell.priceLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
                
                cell = productCell
            }
        }
        else if indexPath.section == 1 {
            let restoreCell : PlainTextTableViewCell = tableView.dequeueReusableCell(withIdentifier: "com.patronkit.cell.plain", for: indexPath) as! PlainTextTableViewCell
            restoreCell.primaryLabel.text = NSLocalizedString("Restore Purchases", comment: "A label a button that restores previous purchases.")
            
            restoreCell.accessoryType = .disclosureIndicator
            
            restoreCell.primaryLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
            
            cell = restoreCell
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "com.patronkit.cell.plain", for: indexPath)
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Products, restore purchases
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == 0 {
            // Become/Extend
            if let _ = PatronManager.sharedManager.expirationDate {
                title = NSLocalizedString("Extend Your Patronage", comment: "A title for the patronage list encouraging returning patrons to donate again.")
            }
            else
            {
                title = NSLocalizedString("Become a Patron", comment: "A title for the patronage list encouraging first time patrons to donate.")
            }
        }
        else if section == 1 {
             title = nil
        }
        
        return title
    }
    
    override open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == 0 {
            // Number of patrons
            
            let count = PatronManager.sharedManager.patronCount
            if count > 1 {
                
                title = NSString(format: NSLocalizedString("%li people became patrons recently.", comment: "A string counting how many people donated recently.") as NSString, count) as String
            }
            else if count > 0 {
                title = NSString(format: NSLocalizedString("%li person became a patron recently.", comment: "A string counting how many people donated recently.") as NSString, count) as String
            }
            else {
                title = NSLocalizedString("Be the first to become a patron!", comment: "A comment encouraging users to become patrons.")
            }
        }
        else if section == 1 {
            // Restore/auto-renew disclaimer
            title = NSLocalizedString("Purchases credit the account in use at the time of purchase and can't be transferred.\n\nThese one-time purchases do not auto-renew.", comment: "An explanation of how the purchases work.")
        }
        
        return title
    }
    
    // MARK: - UITableViewDelegate
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            
            if PatronManager.sharedManager.products.count > 0 {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                // Step 1. Perform Purchase
                PatronManager.sharedManager.purchaseProduct(product: product, with: { (success, error) -> Void in
                    // Step 2. Fetch new expiration
                    PatronManager.sharedManager.fetchPatronageExpiration { (expiration : Date?) -> Void in
                        // Step 3. Update patron count
                        PatronManager.sharedManager.fetchPatronCountSince(date: self.oneUnitBefore(Date(), withUnit: .month), with: { (count, error) -> Void in
                            // Step 4. Update UI
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0,2).toRange()!), with: .automatic)
                                if let error = error
                                {
                                    print("Purchase failed. Error: \(error)")
                                }
                                else
                                {
                                    print("Purchase complete. Success: \(success)")
                                }
                            })
                        })
                    }
                })
                
            }
        }
        else if indexPath.section == 1 {
            PatronManager.sharedManager.restorePurchasedProducts { (success, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0,2).toRange()!), with: .automatic)
                    if let error = error
                    {
                        print("Restore failed. Error: \(error)")
                    }
                    else
                    {
                        print("Restore complete. Success: \(success)")
                    }
                })
            }
        }
        
    }
    
    
    // MARK: - Helpers
    
    /**

    Gets the date 1 calendar unit ago.
    
    - parameter date : The date to start from.
    - parameter unit : The unit to subtract.
    
    - returns: An NSDate that is one unit prior to the origal date.
    
    */
    
    func oneUnitBefore(_ date: Date, withUnit unit: NSCalendar.Unit) -> Date {
        
        return (self.calendar as NSCalendar).date(byAdding: unit, value: -1, to: date, options: [])!
    }
}
