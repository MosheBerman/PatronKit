//
//  PatronKitBlockTypes.swift
//  PatronKit
//
//  Created by Moshe Berman on 1/19/16.
//  Copyright © 2016 Moshe Berman. All rights reserved.
//

import StoreKit
import CloudKit

/**
 
 A block called after fetching `SKProduct`s from the server.
 
 - parameter products : An array of `SKProduct` objects if the fetch completed successfully, otherwise `nil`.
 - parameter error : Populated withy information if the fetch failed, otherwise `nil`.
 
*/
typealias FetchProductsCompletionHandler = (_ products : [SKProduct]?, _ error : NSError?) -> Void

/**

 A closure called after a StoreKit purchase completes.
 
 - parameter success : `true` if the purchase successfully completed, otherwise `false`.
 - parameter error : Populated with information if the purchase failed, otherwise `nil`.
 
*/

typealias PurchaseCompletionHandler = (_ success : Bool, _ error : NSError?) -> Void

/**
 
 A closure called after a StoreKit restore completes.
 
 - parameter success : `true` if the restore successfully completed, otherwise `false`.
 - parameter error : Populated with information if the restore failed, otherwise `nil`.
 
 */

typealias RestorePurchasesCompletionHandler = (_ success : Bool, _ error : NSError?) -> Void

