//
//  PatronageViewController.swift
//  PatronKit
//
//  Created by Moshe Berman on 1/20/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import UIKit
import StoreKit

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
        
        self.tableView.registerClass(PatronageCellSubtitleKind.self, forCellReuseIdentifier: "com.mosheberman.patronage.cell.default")
        
        numberFormatter.numberStyle = .CurrencyStyle
        dateFormatter.timeStyle = .NoStyle
        dateFormatter.dateStyle = .MediumStyle
        
        let oneMonth = self.oneUnitBefore(NSDate(), withUnit: NSCalendarUnit.Month)
        
        PatronManager.sharedManager.fetchPatronageExpiration { (date : NSDate?) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            })
        }
        
        PatronManager.sharedManager.fetchPatronCountSince(date: oneMonth) { (count, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            })
        }
        
        PatronManager.sharedManager.fetchAvailablePatronageProducts { (products, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            })
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("com.mosheberman.patronage.cell.default", forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            
            let count : Int = PatronManager.sharedManager.products.count
            
            if count == 0 /* there are no products  */
            {
                cell.textLabel?.text = NSLocalizedString("Loading Patronage Options...", comment: "A title for a cell that is loading patronage information.")
                cell.detailTextLabel?.text = nil
            }
            else {
                
                let product : SKProduct = PatronManager.sharedManager.products[indexPath.row]
                
                let title : String = product.localizedTitle
                var price : String? = NSLocalizedString("---", comment: "A label for when the price isn't available.")
                
                if let productPrice = self.numberFormatter.stringFromNumber(product.price) {
                    price = productPrice
                }
                
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = price
                cell.accessoryType = .DisclosureIndicator
            }
        }
        else if indexPath.section == 1 {
            cell.textLabel?.text = NSLocalizedString("Restore Purchases", comment: "A label a button that restores previous purchases.")
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2 // Products, restore purchases
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
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
    
    override public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var title : String? = nil
        
        if section == 0 {
            // Number of patrons
            
            let count = PatronManager.sharedManager.patronCount
            if count > 1 {
                
                title = NSString(format: NSLocalizedString("%li people became patrons recently.", comment: "A string counting how many people donated recently."), count) as String
            }
            else if count > 0 {
                title = NSString(format: NSLocalizedString("%li person became a patron recently.", comment: "A string counting how many people donated recently."), count) as String
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
