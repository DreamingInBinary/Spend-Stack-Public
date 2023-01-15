//
//  AppleCardImport.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 4/11/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation

enum PurchaseType : CustomStringConvertible  {
    var description: String {
        return self == PurchaseType.Purchase ? "Purchase" : "Payment"
    }
    case Purchase, Payment
}

enum ImportOrder : Int {
    case transactionDate, clearingDate, itemDescription, merchant, category, purchaseType, amount
}

struct AppleCardImportItem : CustomStringConvertible {
    
    // MARK: Properties
    
    let transactionDate:Date?
    let clearingDate:Date?
    let itemDescription:String
    let merchant:String
    let category:String
    let purchaseType:PurchaseType
    let amount:String
    
    var description: String {
        return String(describing: transactionDate) +
               String(describing: clearingDate) +
                itemDescription +
                merchant +
                category +
                String(describing: purchaseType) +
                amount
    }
    
    // MARK: Initializers
    
    init(withDictionary data:[String:String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        guard let pasrsedTransactionDate = dateFormatter.date(from:data["Transaction Date"]!) else {
           fatalError("ERROR: Date conversion failed due to mismatched format.")
        }
        self.transactionDate = pasrsedTransactionDate
        
        guard let pasrsedClearingDate = dateFormatter.date(from:data["Clearing Date"]!) else {
           fatalError("ERROR: Date conversion failed due to mismatched format.")
        }
        self.clearingDate = pasrsedClearingDate
        self.itemDescription = data["Description"]!
        self.merchant = data["Merchant"]!
        self.category = data["Category"]!
        self.purchaseType = data["Type"]! == "Purchase" ? .Purchase : .Payment
        self.amount = data["Amount (USD)"]!
    }
    
    init(withDataArray data:[String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        if let pasrsedTransactionDate = dateFormatter.date(from:data[ImportOrder.transactionDate.rawValue]) {
            self.transactionDate = pasrsedTransactionDate
        } else {
            dateFormatter.dateFormat = "dd/MM/yyyy"
            self.transactionDate = dateFormatter.date(from:data[ImportOrder.transactionDate.rawValue]) 
        }
        
        if let parsedClearingDate = dateFormatter.date(from:data[ImportOrder.clearingDate.rawValue]) {
            self.clearingDate = parsedClearingDate
        } else {
            dateFormatter.dateFormat = "dd/MM/yyyy"
            self.clearingDate = dateFormatter.date(from:data[ImportOrder.transactionDate.rawValue])
        }
        
        self.itemDescription = data[ImportOrder.itemDescription.rawValue]
        self.merchant = data[ImportOrder.merchant.rawValue]
        self.category = data[ImportOrder.category.rawValue]
        self.purchaseType = data[ImportOrder.purchaseType.rawValue] == "Purchase" ? .Purchase : .Payment
        self.amount = data[ImportOrder.amount.rawValue]
    }
    
    // MARK: Transformers
    
    static func importItemToSpendStackItem(importItem item:AppleCardImportItem, forList list:SSList) -> SSListItem {
        let listItem = SSListItem(parentListRecordID: list.objCKRecord.recordID)
        listItem.title = item.merchant
        listItem.notes = item.itemDescription.capitalizingFirstLetter()
        listItem.baseAmount = NSDecimalNumber(string:item.amount)
        listItem.fkListID = list.dbID
        listItem.customDate = item.transactionDate
        listItem.cardImportName = "Apple Card"
        return listItem
    }
}
