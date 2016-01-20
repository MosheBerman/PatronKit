//
//  PatronManager.swift
//  PatronKit
//
//  Created by Moshe Berman on 1/19/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import Foundation
import CloudKit
import StoreKit

public class PatronManager {
    
    // Singleton Access
    static let sharedManager = PatronManager()
    
    // Keys
    private let keyPurchasesOfUser : String = "purchases"
    private let keyUserWhoMadePurchase : String = "userRecordID"
    
    // CloudKit Accessors
    private let publicDatabase : CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
    private let defaultRecordZone : CKRecordZone = CKRecordZone.defaultRecordZone()
    
    // Completion Handlers
//    private let fetchProductsCompletionHandler : (() -> Void)? // Change to block.
//    private let purchasePatronageCompletionHandler : (() -> Void)? // Change to block.
//    private let restorePurchaseCompletionHandler : (() -> Void)? // Change to block.
    
    // MARK: - Fetching Available Products
    
    /**

    Looks up available patronage products and passes them back to the handler.
    
    - parameter completionHandler : A handler to pass back SKProducts representing patronage levels.
    
    */
    
    func fetchAvailablePatronageProducts(withCompletionHandler completionHandler : () -> Void) {
        
    }
    
    // MARK: - Purchasing Patronage
    
    /**

    Perform a purchase with the StoreKit API.
    
    */
    
    func purchaseProduct(product product: SKProduct, withCompletion:() -> Void) {
        
    }
    
    // MARK: - Restoring Purchases 
    
    /**
    
    Restore previously purchased patronage.
    
    Required by App Store Review, probably a good idea anyway.
    
    - parameter completionHandler : A callback executed after the restoration finishes, with a boolean describing if the operation failed.

    */
    
    // MARK: - Recording a Purchase

    func recordPurchaseOfPatronage(product product : SKProduct, withCompletion completion:() -> Void) {
        
    }
    
    
    // MARK: - Fetching Patron Counts
    
    /**

     Fetches the number of patrons who have purchases associated with their accounts.
    
     - parameter completionHandler : A callback passing you the number of patrons who've purchased patronage.
     
     */
    
    func fetchPatronCountWithCompletion(completionHandler completionHandler: (count : NSInteger, error : NSError?) -> Void) {
        
        let predicate : NSPredicate = NSPredicate(format: "TRUEFORMAT") // The documentation
        let query : CKQuery = CKQuery(recordType: "User", predicate: predicate)
        
        self.publicDatabase.performQuery(query, inZoneWithID: self.defaultRecordZone.zoneID) { (records : [CKRecord]?, error : NSError?) -> Void in
            
            var count = 0;
            
            if let records = records {
                for record : CKRecord in records {
                    
                    if let purchases : [CKReference] = record[self.keyPurchasesOfUser] as? [CKReference] {
                        
                        if purchases.count > 0 {
                            count = count + 1
                        }
                    }
                    else
                    {
                        print("Could not read purchase references from record: \(record)")
                    }
                }
            }
            else
            {
                print("Could not retrieve records from public database: \(error)")
            }
            
            completionHandler(count: count, error: error)
        }
    }
    
    /**
    
    Fetches all of the purchases since a given date, then grabs the recordIDs of the related users.
    
    */
    
    func fetchPatronCountSince(date date: NSDate, withCompletionHandler completionHandler: (count : NSInteger, error : NSError?) -> Void) {
        
        let predicate : NSPredicate = NSPredicate(format: "creationDate > %@ || (date = nil)", date)
        let query : CKQuery = CKQuery(recordType: "Purchase", predicate: predicate)
        
        self.publicDatabase.performQuery(query, inZoneWithID: self.defaultRecordZone.zoneID) { (records : [CKRecord]?, error : NSError?) -> Void in
            
            var userIDs : Set<CKRecordID> = Set()
            
            if let records = records {
                for purchase : CKRecord in records {
                    if let userID = purchase[self.keyUserWhoMadePurchase] as? CKRecordID {
                        userIDs.insert(userID)
                    }
                    else
                    {
                        print("Purchase is missing a user record ID. This is a probably a bug.")
                    }
                }
            }
            else
            {
                print("Could not retrieve records from public database.")
            }
            
            let count = userIDs.count
            
            print("Found \(count) users who purchased since \(date)")
            
            completionHandler(count: count, error: error)
        }
    }
}