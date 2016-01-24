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

public class PatronManager : NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    // Singleton Access
    public static let sharedManager = PatronManager()
    
    // Patronage Stats
    public var expirationDate : NSDate? = nil
    public var patronCount : Int? = nil
    public var reviewCount : Int? = nil
    
    // StoreKit
    public var productIdentifiers : Set<String> = []
    public var products : [SKProduct] = []
    public var appID : String? = nil
    
    // StoreKit Private
    private var productsRequest : SKProductsRequest? = nil
    
    // Keys - used for CKRecord objects.
    private let keyPurchasesOfUser : String = "purchases"
    private let keyUserWhoMadePurchase : String = "userRecordID"
    private let keyProductIdentifier : String = "productIdentifier"
    private let keyPurchaseDate : String = "purchaseDate"
    private let keyExpirationDate : String = "expirationDate"
    
    // CloudKit Accessors
    private let publicDatabase : CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
    private let defaultRecordZone : CKRecordZone = CKRecordZone.defaultRecordZone()
    
    // Completion Handlers
    private var fetchProductsCompletionHandler : FetchProductsCompletionHandler? = nil
    private var purchasePatronageCompletionHandler : PurchaseCompletionHandler? = nil
    private var restorePurchaseCompletionHandler : RestorePurchasesCompletionHandler? = nil
    
    // Date calculation
    let gregorianCalendar : NSCalendar? = NSCalendar(identifier: NSCalendarIdentifierGregorian)
    
    // MARK: - Designated Initializer
    
    private override init() {
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    // MARK: - Fetching Available Products
    
    /**

    Looks up available patronage products and passes them back to the handler.
    
    - parameter completionHandler : A handler to pass back SKProducts representing patronage levels. If this method is called multiple times in succession, only the last completion handler will be executed.
    
    */
    
    func fetchAvailablePatronageProducts(withCompletionHandler completionHandler : FetchProductsCompletionHandler) {
        
        guard let request : SKProductsRequest = SKProductsRequest(productIdentifiers: self.productIdentifiers) else {
            return
        }
        
        self.fetchProductsCompletionHandler = completionHandler
        
        request.delegate = self
        self.productsRequest = request
        request.start()
    }
    
    // MARK: - Purchasing Patronage
    
    /**

    Perform a purchase with the StoreKit API.
    
    - parameter product : The product to purchase.
    - parameter completionHandler : A handler to pass back the results of the purchase. If this method is called multiple times in succession, only the last completion handler will be executed.
    
    */
    
    func purchaseProduct(product product: SKProduct, withCompletionHandler completionHandler: PurchaseCompletionHandler) {
        
        if (!SKPaymentQueue.canMakePayments()) {
            
            let error : NSError = NSError(domain: "com.patronkit.purchase.failed", code: -1, userInfo: ["reason" : "The payment queue reported that it cannot make payments."])
            completionHandler(success:false, error: error)
            
            return
        }
        
        self.purchasePatronageCompletionHandler = completionHandler
        
        let payment : SKPayment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    // MARK: - Restoring Purchases 
    
    /**
    
    Restore previously purchased patronage.
    
    Required by App Store Review, probably a good idea anyway.
    
    - parameter completionHandler : A handler executed after the restoration finishes, with a boolean describing if the operation succeeded. If this method is called multiple times in succession, only the last completion handler will be executed.

    */
    
    func restorePurchasedProductsWithCompletionHandler(completionHandler handler: RestorePurchasesCompletionHandler) {
        self.restorePurchaseCompletionHandler = handler
        
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // MARK: - Recording a Purchase

    /**
    
    Records the purchase in iCloud.
    
    - parameter product : The product that was purchased.
    - parameter completion : A completion handler that is called after the operation completes.
    
    */
    
    func recordPurchaseOfPatronage(payment payment : SKPayment, withCompletion completion:(recorded : Bool) -> Void) {
        
        CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler { (recordID : CKRecordID?, error : NSError?) -> Void in

            guard let userRecordID = recordID else {
                
                print("Couldn't get a logged in user while recording purchase. Bailing.")
                
                completion(recorded: false)
                
                return
                
            }
            
            print("Got user record ID.")
            
            // Get the current user.
            self.publicDatabase.fetchRecordWithID(userRecordID, completionHandler: { (userRecord : CKRecord?, error : NSError?) -> Void in
                
                if let user = userRecord {
                    
                    // Get the previous expiration, in case the user is extending support.
                    self.fetchPatronageExpiration(withCompletionHandler: { (expirationDate : NSDate?) -> Void in
                        
                        var purchaseDate = NSDate()
                        
                        // If there's an expiration date that's in the future, use that date as the purchase date.
                        if let fetchedExpirationDate = expirationDate {
                            if fetchedExpirationDate.timeIntervalSinceDate(purchaseDate) > 0 {
                                purchaseDate = fetchedExpirationDate
                            }
                        }
                        
                        // Create a purchase
                        let purchase : CKRecord = CKRecord(recordType: "Purchase", zoneID: self.defaultRecordZone.zoneID)
                        purchase[self.keyUserWhoMadePurchase] =  user.recordID.recordName
                        purchase[self.keyPurchaseDate] = purchaseDate
                        purchase[self.keyProductIdentifier] = payment.productIdentifier
                        purchase[self.keyExpirationDate] = self.expirationDateForPayment(payment: payment, withPurchaseDate: purchaseDate)
                        
                        // Add it to iCloud.
                        let addPurchaseOperation : CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [purchase], recordIDsToDelete: nil);
                        
                        addPurchaseOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecordIDs : [CKRecordID]?, operationError : NSError?) -> Void in
                            
                            completion(recorded: true)
                            
                        }
                        
                        self.publicDatabase.addOperation(addPurchaseOperation)
                    })
                }
                else
                {
                    completion(recorded: false)
                    print("Got user record ID but failed to get user record.")
                }
            })

        }
    }

    // MARK: - Fetching Patron Counts
    
    /**

     Fetches the number of patrons who have purchases associated with their accounts.
    
     - parameter completionHandler : A callback passing you the number of patrons who've purchased patronage.
     
     */
    
    func fetchPatronCountWithCompletion(completionHandler completionHandler: (count : NSInteger, error : NSError?) -> Void) {
        
        let predicate : NSPredicate = NSPredicate(format: "TRUEFORMAT") // The documentation says to use this for "all of the given type."
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
    
     Fetches all of the purchases since a given date, then grabs the recordIDs of the related users. Returns the number of unique IDs.
     
     - parameter completionHandler: A callback which is executed after we successfully or unsuccessfully count the number of patrons.
    
    */
    
    func fetchPatronCountSince(date date: NSDate, withCompletionHandler completionHandler: (count : NSInteger?, error : NSError?) -> Void) {
        
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
    
    // MARK: - Checking a User's Patronage status
    
    /**

    Iterate the expiration dates for the current user and find the latest one.
    
    - parameter completionHandler : A handler which returns either an expiration date, or nil.
    
    */
    
    func fetchPatronageExpiration(withCompletionHandler completionHandler: (NSDate?) -> Void) {
        
        CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler { (userRecordID : CKRecordID?, error : NSError?) -> Void in
            
            let predicate : NSPredicate = NSPredicate(format: "\(self.keyUserWhoMadePurchase) == \(userRecordID)")
            let query : CKQuery = CKQuery(recordType: "Purchase", predicate: predicate)
            
            self.publicDatabase.performQuery(query, inZoneWithID: self.defaultRecordZone.zoneID, completionHandler: { (records : [CKRecord]?, error : NSError?) -> Void in
                
                var expirationDate : NSDate? = nil
                
                if let purchases = records {
                    
                    for purchase in purchases {
                        
                        guard let purchaseExpirationDate = purchase[self.keyExpirationDate] as? NSDate else {
                            print("Weird, couldn't find a purchase for \(purchase.recordID)")
                            continue
                        }
                        
                        // If there's no earliest purchase date
                        guard let previousExpirationDate = expirationDate else {
                            expirationDate = purchaseExpirationDate
                            continue
                        }
                        
                        if purchaseExpirationDate.timeIntervalSinceDate(previousExpirationDate) < 0 {
                            expirationDate = purchaseExpirationDate
                        }
                    }
                }
                
                completionHandler(expirationDate)
            })
        }
    }
    
    // MARK: - Calculating an Expiration Date
    
    /** 

    Calculates an expiration date based on the kind of payment, and the purchase date.
    This assumes that your product identifier ends with a period, followed by a number. 
    We're also assuming that the number represents months, not weeks or days.

    - parameter payment : An SKPayment that was processed by StoreKit.
    - parameter purchaseDate : The date of purchase.
    
    - returns : NSDate if we are able to calculate the date, or nil if there was an error.
    
    */
    
    private func expirationDateForPayment(payment payment: SKPayment, withPurchaseDate date: NSDate) -> NSDate? {
    
        var expirationDate : NSDate? = nil
        
        if let monthString : String = payment.productIdentifier.componentsSeparatedByString(".").last {
        
            if let months : Int = Int(monthString) {
                let components : NSDateComponents = NSDateComponents()
                components.month = months
            
                expirationDate = self.gregorianCalendar?.dateByAddingComponents(components, toDate: date, options: .WrapComponents)
            }
        }
        
        return expirationDate
    }
    
    // MARK: - SKProductsRequestDelegate
    
    /**
    
    The SKProductsRequestDelegate stores the retrieved products locally then calls the callback.
    
    */
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {

        self.products = response.products.sort({ (productA : SKProduct, productB : SKProduct) -> Bool in

            let priceA = productA.price.floatValue
            let priceB = productB.price.floatValue
            
            return priceA < priceB
        })
        
        if let handler = self.fetchProductsCompletionHandler {
            
            handler(products: response.products, error: nil)
        }
        else
        {
            print("Received new products, but there's no callback defined.")
        }
    }
    
    // MARK: - SKPaymentTransactionObserver
    
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            
            let payment : SKPayment = transaction.payment
            let state : SKPaymentTransactionState = transaction.transactionState
            
            switch state {
                
            case.Purchasing:
                break
                
            case .Purchased:
                
                self.recordPurchaseOfPatronage(payment: payment, withCompletion: { (recorded : Bool) -> Void in
                    
                    if let handler = self.purchasePatronageCompletionHandler
                    {
                        handler(success: true, error: nil)
                    }
                    
                })

                break
                
            case .Restored:

                if let handler = self.restorePurchaseCompletionHandler
                {
                    handler(success: true, error: nil)
                }
                
                break
                
            case .Failed:
                if let handler = self.purchasePatronageCompletionHandler
                {
                    handler(success: false, error: transaction.error)
                }
                break
            case .Deferred: break
                
            }
            
            
        }
    }
}