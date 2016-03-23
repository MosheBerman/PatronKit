//
//  PatronageViewController.swift
//  PatronKit
//
//  Created by Moshe Berman on 1/20/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit
import StoreKit

enum PatronageTableSection : NSInteger {
 
    case Purchase = 0
    case PurchaseStatistics = 1
    case Review = 2
    case RestorePurchases = 3
    
}

public class PatronageViewController: UITableViewController {
    
    var numberFormatter : NSNumberFormatter = NSNumberFormatter()
    var dateFormatter : NSDateFormatter = NSDateFormatter()
    var calendar : NSCalendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: .Grouped)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    // MARK: - Common initialization
    
    func commonInit() {
        
        numberFormatter.numberStyle = .CurrencyStyle
        dateFormatter.timeStyle = .NoStyle
        dateFormatter.dateStyle = .MediumStyle
        
        self.tableView.registerClass(PlainTextTableViewCell.self, forCellReuseIdentifier: "com.patronkit.cell.plain")
        self.tableView.registerClass(PatronageOptionTableViewCell.self, forCellReuseIdentifier: "com.patronkit.cell.loading")
        self.tableView.registerClass(PatronageOptionTableViewCell.self, forCellReuseIdentifier: "com.patronkit.cell.product")
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        
        let oneMonth = self.oneUnitBefore(NSDate(), withUnit: NSCalendarUnit.Month)
        
        PatronManager.sharedManager.fetchPatronageExpiration { (date : NSDate?) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            })
        }
        
        PatronManager.sharedManager.fetchPatronCountSince(date: oneMonth) { (count, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            })
        }
        
        PatronManager.sharedManager.fetchAvailablePatronageProducts { (products, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            })
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell
        
        if indexPath.section == 0 {
            
            let count : Int = PatronManager.sharedManager.products.count
            
            if count == 0 /* there are no products  */
            {
                let loadingCell : PatronageOptionTableViewCell = tableView.dequeueReusableCellWithIdentifier("com.patronkit.cell.loading", forIndexPath: indexPath) as! PatronageOptionTableViewCell
                loadingCell.productLabel.text = NSLocalizedString("Loading Patronage Options...", comment: "A title for a cell that is loading patronage information.")
                loadingCell.priceLabel.text = "..."
                
                loadingCell.accessoryType = .None
                
                loadingCell.productLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
                loadingCell.priceLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
                
                cell = loadingCell
            }
            else {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                var title : String = product.localizedTitle
                
                if title.characters.count == 0 {
                    title = NSLocalizedString("Product Name Unavailable", comment: "")
                }
                
                var price : String? = NSLocalizedString("---", comment: "A label for when the price isn't available.")
                
                if let productPrice = self.numberFormatter.stringFromNumber(product.price) {
                    price = productPrice
                }
                
                let productCell : PatronageOptionTableViewCell = tableView.dequeueReusableCellWithIdentifier("com.patronkit.cell.product", forIndexPath: indexPath) as! PatronageOptionTableViewCell
                productCell.productLabel.text = title
                productCell.priceLabel.text = price
                
                productCell.accessoryType = .None
                
                productCell.productLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
                productCell.priceLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
                
                cell = productCell
            }
        }
        else if indexPath.section == 1 {
            let restoreCell : PlainTextTableViewCell = tableView.dequeueReusableCellWithIdentifier("com.patronkit.cell.plain", forIndexPath: indexPath) as! PlainTextTableViewCell
            restoreCell.primaryLabel.text = NSLocalizedString("Restore Purchases", comment: "A label a button that restores previous purchases.")
            
            restoreCell.accessoryType = .DisclosureIndicator
            
            restoreCell.primaryLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            
            cell = restoreCell
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("com.patronkit.cell.plain", forIndexPath: indexPath)
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2 // Products, restore purchases
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count : Int = 0
        
        if section == 0 {
            
            count = PatronManager.sharedManager.products.count
            
            if count == 0 // there are no products
            {
                count = 1 // show loading text
            }
            
        }
        else if section == 1 {
            count = 1
        }
        
        return count
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == PatronageTableSection.Purchase.rawValue {
            // Become/Extend
            if let _ = PatronManager.sharedManager.expirationDate {
                title = NSLocalizedString("Extend Your Patronage", comment: "A title for the patronage list encouraging returning patrons to donate again.")
            }
            else
            {
                title = NSLocalizedString("Become a Patron", comment: "A title for the patronage list encouraging first time patrons to donate.")
            }
        }
        else if section == PatronageTableSection.Review.rawValue {
            title = NSLocalizedString("App Store Reviews", comment: "A title for the App Store review section.")
        }
        
        return title
    }
    
    override public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == PatronageTableSection.Purchase.rawValue {
            // Number of patrons
            title = NSLocalizedString("These purchases do not auto-renew.", comment: "A message informing users that IAPs do not automatically renew.")
        }
        
        

        return title
    }
    
    // MARK: - UITableViewDelegate
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            
            if PatronManager.sharedManager.products.count > 0 {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                // Step 1. Perform Purchase
                PatronManager.sharedManager.purchaseProduct(product: product, withCompletionHandler: { (success, error) -> Void in
                    // Step 2. Fetch new expiration
                    PatronManager.sharedManager.fetchPatronageExpiration(withCompletionHandler: { (expiration : NSDate?) -> Void in
                        // Step 3. Update patron count
                        PatronManager.sharedManager.fetchPatronCountSince(date: self.oneUnitBefore(NSDate(), withUnit: .Month), withCompletionHandler: { (count, error) -> Void in
                            // Step 4. Update UI
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0,2)), withRowAnimation: .Automatic)
                                print("Purchase complete. Success: \(success) Error: \(error)")
                            })
                        })
                    })
                })
                
            }
        }
        else if indexPath.section == 1 {
            PatronManager.sharedManager.restorePurchasedProductsWithCompletionHandler(completionHandler: { (success, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0,2)), withRowAnimation: .Automatic)
                    print("Restore complete. Success: \(success) Error: \(error)")
                })
            })
        }
        
    }
    
    
    // MARK: - Helpers
    
    /**

    Gets the date 1 calendar unit ago.
    
    - parameter date : The date to start from.
    - parameter unit : The unit to subtract.
    
    - returns: An NSDate that is one unit prior to the origal date.
    
    */
    
    func oneUnitBefore(date: NSDate, withUnit unit: NSCalendarUnit) -> NSDate {
        
        return self.calendar.dateByAddingUnit(unit, value: -1, toDate: date, options: [])!
    }
}
