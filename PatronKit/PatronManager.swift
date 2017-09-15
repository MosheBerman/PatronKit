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
    public var expirationDate : Date? = nil
    public var patronCount : Int = 0
    public var reviewCount : Int = 0
    
    // StoreKit
    public var productIdentifiers : Set<String> = []
    public var products : [SKProduct] = []
    public var appID : NSString? = nil
    
    // StoreKit Private
    private var productsRequest : SKProductsRequest? = nil
    
    // Keys - used for CKRecord objects.
    private let keyPurchasesOfUser : String = "purchases"
    private let keyUserWhoMadePurchase : String = "userRecordID"
    private let keyProductIdentifier : String = "productIdentifier"
    private let keyPurchaseDate : String = "purchaseDate"
    private let keyExpirationDate : String = "expirationDate"
    
    // CloudKit Accessors
    private let publicDatabase : CKDatabase = CKContainer.default().publicCloudDatabase
    private let defaultRecordZone : CKRecordZone = CKRecordZone.default()
    
    // Completion Handlers
    private var fetchProductsCompletionHandler : FetchProductsCompletionHandler? = nil
    private var purchasePatronageCompletionHandler : PurchaseCompletionHandler? = nil
    private var restorePurchaseCompletionHandler : RestorePurchasesCompletionHandler? = nil
    
    // Date calculation
    let gregorianCalendar : Calendar = Calendar(identifier: .gregorian)
    
    // MARK: - Designated Initializer
    
    private override init() {
        super.init()
    }
    
    // MARK: - Fetching Available Products
    
    /**

    Looks up available patronage products and passes them back to the handler.
    
    - parameter completionHandler : A handler to pass back SKProducts representing patronage levels. If this method is called multiple times in succession, only the last completion handler will be executed.
    
    */
    
    func fetchAvailablePatronageProducts(withCompletionHandler completionHandler : @escaping FetchProductsCompletionHandler) {
        
        let request : SKProductsRequest = SKProductsRequest(productIdentifiers: self.productIdentifiers)
        
        
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
    
    func purchaseProduct(product: SKProduct, with completionHandler: @escaping PurchaseCompletionHandler) {
        
        if (!SKPaymentQueue.canMakePayments()) {
            
            let error : NSError = NSError(domain: "com.patronkit.purchase.failed", code: -1, userInfo: ["reason" : "The payment queue reported that it cannot make payments."])
            completionHandler(false, error)
            
            return
        }
        
        SKPaymentQueue.default().add(self)
        
        self.purchasePatronageCompletionHandler = completionHandler
        
        let payment : SKPayment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Restoring Purchases 
    
    /**
    
    Restore previously purchased patronage.
    
    Required by App Store Review, probably a good idea anyway.
    
    - parameter completionHandler : A handler executed after the restoration finishes, with a boolean describing if the operation succeeded. If this method is called multiple times in succession, only the last completion handler will be executed.

    */
    
    func restorePurchasedProducts(with completionHandler: @escaping RestorePurchasesCompletionHandler) {
        self.restorePurchaseCompletionHandler = completionHandler
        
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Recording a Purchase

    /**
    
    Records the purchase in iCloud.
    
    - parameter product : The product that was purchased.
    - parameter completion : A completion handler that is called after the operation completes.
    
    */
    
    func recordPurchaseOfPatronage(payment : SKPayment, with completion: @escaping (_ recorded : Bool) -> Void) {
        
        CKContainer.default().fetchUserRecordID { (recordID : CKRecordID?, error : Error?) -> Void in

            guard let userRecordID = recordID else {
                
                print("Couldn't get a logged in user while recording purchase. Bailing.")
                
                completion(false)
                
                return
                
            }
            
            // Get the current user.
            self.publicDatabase.fetch(withRecordID: userRecordID, completionHandler: { (userRecord : CKRecord?, error : Error?) -> Void in
                
                if let user = userRecord {
                    
                    // Get the previous expiration, in case the user is extending support.
                    self.fetchPatronageExpiration { (expirationDate : Date?) -> Void in
                        
                        var purchaseDate = Date()
                        
                        // If there's an expiration date that's in the future, use that date as the purchase date.
                        if let fetchedExpirationDate = expirationDate {

                            if fetchedExpirationDate.timeIntervalSince(purchaseDate) > 0 {
                                purchaseDate = fetchedExpirationDate
                            }
                            else
                            {
                               print("The fetched expiry is in the past, keeping current date as starting point.")
                            }
                        }
                        else {
                            print("Failed to fetch expiration date.")
                        }
                        
                        // Create a purchase
                        let purchase : CKRecord = CKRecord(recordType: "Purchase", zoneID: self.defaultRecordZone.zoneID)
                        purchase[self.keyUserWhoMadePurchase] =  user.recordID.recordName as CKRecordValue
                        purchase[self.keyPurchaseDate] = purchaseDate as CKRecordValue
                        purchase[self.keyProductIdentifier] = payment.productIdentifier as CKRecordValue
                        purchase[self.keyExpirationDate] =  (self.expirationDate(for: payment, with: purchaseDate)! as NSDate) as CKRecordValue
                        
                        // Add it to iCloud.
                        let addPurchaseOperation : CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [purchase], recordIDsToDelete: nil);
                        
                        addPurchaseOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecordIDs : [CKRecordID]?, operationError : Error?) -> Void in
                            
                            completion(true)
                            
                        }
                        
                        self.publicDatabase.add(addPurchaseOperation)
                    }
                }
                else
                {
                    completion(false)
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
    
    func fetchPatronCount(with completionHandler: @escaping (_ count : NSInteger, _ error : Error?) -> Void) {
        
        let predicate : NSPredicate = NSPredicate(format: "TRUEFORMAT") // The documentation says to use this for "all of the given type."
        let query : CKQuery = CKQuery(recordType: "User", predicate: predicate)
        
        self.publicDatabase.perform(query, inZoneWith: self.defaultRecordZone.zoneID) { (records : [CKRecord]?, error : Error?) -> Void in
            
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
                if let error = error
                {
                    print("Could not retrieve records from public database: \(error)")
                }
                else
                {
                    print("Could not retrieve records from public database. No further error info.")
                }
            }
            
            completionHandler(count, error)
        }
    }
    
    /**
    
     Fetches all of the purchases since a given date, then grabs the recordIDs of the related users. Returns the number of unique IDs.
     
     - parameter completionHandler: A callback which is executed after we successfully or unsuccessfully count the number of patrons.
    
    */
    
    func fetchPatronCountSince(date : Date, with completion: @escaping (_ count : NSInteger?, _ error : Error?) -> Void) {
        
        let predicate : NSPredicate = NSPredicate(format: "purchaseDate > %@ ", date as NSDate)
        let query : CKQuery = CKQuery(recordType: "Purchase", predicate: predicate)
        
        self.publicDatabase.perform(query, inZoneWith: self.defaultRecordZone.zoneID) { (records : [CKRecord]?, error : Error?) -> Void in
            
            var userIDs : Set<String> = Set()
            
            if let records = records {
                
                for purchase : CKRecord in records {
                    if let userID = purchase[self.keyUserWhoMadePurchase] as? String {
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

            self.patronCount = count
            completion(count, error)
        }
    }
    
    // MARK: - Checking a User's Patronage status
    
    /**

    Iterate the expiration dates for the current user and find the latest one.
    
    - parameter completionHandler : A handler which returns either an expiration date, or nil.
    
    */
    
    func fetchPatronageExpiration(with completionHandler: @escaping (Date?) -> Void) {
        
        CKContainer.default().fetchUserRecordID { (userRecordID : CKRecordID?, error : Error?) -> Void in
            
            guard let userRecordName = userRecordID?.recordName else {
                
                print("Couldn't unwrap the CKRecordID for the user record.")
                completionHandler(nil)
                
                return
            }
            
            let predicate : NSPredicate = NSPredicate(format: "\(self.keyUserWhoMadePurchase) == %@ ", userRecordName)
            let query : CKQuery = CKQuery(recordType: "Purchase", predicate: predicate)
            
            self.publicDatabase.perform(query, inZoneWith: self.defaultRecordZone.zoneID, completionHandler: { (records : [CKRecord]?, error : Error?) -> Void in
                
                var expirationDate : Date? = nil
                
                if let purchases = records {
                    
                    for purchase in purchases {
                        
                        guard let purchaseExpirationDate = purchase[self.keyExpirationDate] as? Date else {
                            print("Weird, couldn't find an expiration date for \(purchase.recordID).")
                            continue
                        }
                        
                        // If there's no earliest purchase date
                        guard let previousExpirationDate = expirationDate else {
                            expirationDate = purchaseExpirationDate
                            
                            continue
                        }
                        
                        if purchaseExpirationDate.timeIntervalSince(previousExpirationDate) > 0 {
                            print("\(purchaseExpirationDate) is after \(previousExpirationDate)")
                            expirationDate = purchaseExpirationDate
                        }
                    }
                }
                else {
                    print("Found no prior purchases for user.")
                }
                
                if let expirationDate = expirationDate
                {
                    print("(\(self.self)): Latest expiration date \(expirationDate)")
                }
                
                self.expirationDate = expirationDate
                completionHandler(expirationDate)
            })
        }
    }
    
    // MARK: - Counting App Reviews
    
    func fetchNumberOfAppReviews(with completionHandler : @escaping (_ reviews : NSInteger?, _ error : Error?) -> Void) {
        
        guard let appID = self.appID else
        {
            print("\(self.self): Cannot fetch reviews without an App ID.")
            let error : NSError = NSError(domain: "com.patronkit.review", code: -1, userInfo: ["reason" : "The app ID was not configured before calling this method."])
            completionHandler(0, error)
            return
        }
        
        if let url = URL(string: "https://itunes.apple.com/lookup?id=\(appID)") {
         
            let request = URLRequest(url: url)
            let session = URLSession.shared
            let task = session.dataTask(with: request) { (data : Data?, respone : URLResponse?, error: Error?) -> Void in
                
                var count : Int = 0
        
                
                if let responseDate = data {
                    do {
                        
                        if let results : Dictionary<String, AnyObject> = try JSONSerialization.jsonObject(with: responseDate, options: []) as? Dictionary<String, AnyObject> {
                            
                            if let resultSet : [[String : AnyObject]] = results["results"] as? [[String : AnyObject]] {
                            
                                if let appData : [String : AnyObject] = resultSet.first {
                                    
                                    if let reviewCount = appData["userRatingCountForCurrentVersion"] as? Int {
                                        count = reviewCount
                                    }
                                    else
                                    {
                                        print("Failed to read review count for current version.")
                                    }
                                }
                                else
                                {
                                    print("Failed to read results from app query.")
                                }
                            }
                            else {
                                print("Failed to cast search results to a useful type.")
                            }
                        }
                    }
                    catch let e {
                        print("Failed to deserialize response. \(e)")
                    }
                }
                
                self.reviewCount = count
                completionHandler(count, error)
            }
            
            task.resume()
            
        }
    }
    
    // MARK: - Helpers
    
    /** 

    Calculates an expiration date based on the kind of payment, and the purchase date.
    This assumes that your product identifier ends with a period, followed by a number. 
    We're also assuming that the number represents months, not weeks or days.

    - parameter payment : An SKPayment that was processed by StoreKit.
    - parameter purchaseDate : The date of purchase.
    
    - returns : Date if we are able to calculate the date, or nil if there was an error.
    
    */
    
    private func expirationDate(for payment: SKPayment, with purchaseDate: Date) -> Date? {
    
        var expirationDate : Date? = nil
        
        if let monthString : String = payment.productIdentifier.components(separatedBy: ".").last {
        
            if let months : Int = Int(monthString) {
                var components : DateComponents = DateComponents()
                components.month = months
            
                expirationDate = self.gregorianCalendar.date(byAdding: components, to: purchaseDate, wrappingComponents: false)
            }
        }
        
        return expirationDate
    }
    
    // MARK: - SKProductsRequestDelegate
    
    /**
    
    The SKProductsRequestDelegate stores the retrieved products locally then calls the callback.
    
    */
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        self.products = response.products.sorted(by: { (productA : SKProduct, productB : SKProduct) -> Bool in

            let priceA = productA.price.floatValue
            let priceB = productB.price.floatValue
            
            return priceA < priceB
        })
        
        if let handler = self.fetchProductsCompletionHandler {
            
            handler(response.products, nil)
        }
        else
        {
            print("Received new products, but there's no callback defined.")
        }
    }
    
    // MARK: - SKPaymentTransactionObserver
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            
            let payment : SKPayment = transaction.payment
            let state : SKPaymentTransactionState = transaction.transactionState
            
            switch state {
                
            case.purchasing:
                break
                
            case .purchased:
                
                SKPaymentQueue.default().finishTransaction(transaction)
                
                self.recordPurchaseOfPatronage(payment: payment, with: { (recorded : Bool) -> Void in
                    
                    if let handler = self.purchasePatronageCompletionHandler
                    {
                        handler(true, nil)
                    }
                    
                })

                break
                
            case .restored:

                if let handler = self.restorePurchaseCompletionHandler
                {
                    handler(true, nil)
                }
                
                break
                
            case .failed:
                if let handler = self.purchasePatronageCompletionHandler
                {
                    handler(false, transaction.error as NSError?)
                }
                break
            case .deferred: break
                
            }
            
            
        }
    }
}
