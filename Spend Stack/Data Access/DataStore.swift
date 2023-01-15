//
//  DataStore.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/15/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import WidgetKit

extension Notification.Name {
    static let listCRUD = Notification.Name.init("crudOccurredForList")
}

struct ListCRUDPayload {
    var lists: [SSList]
    // In some cases, a handler already fetched the list from the DB.
    // This allows consumers to skip another DB fetch in those cases.
    var listsHaveBeenUpdated: Bool = false
    
    func send() {
        NotificationCenter.default.post(name: .listCRUD, object: self)
    }
}

public typealias onDBCommit = () -> ()
public typealias onDuplicateItem = ((SSListItem)) -> ()
public typealias onDuplicateList = ((SSList)) -> ()
public typealias onMoveItems = ([SSListItem], SSList, SSList, FMDatabase) -> ()
public typealias TagViewModel = (color:String, name:String)

@objc class DataStore : NSObject {
    // Public properties
    lazy var miscTag:SSListTag = {
        return SSListTag.misc()
    }()
    
    // Private Properties
    private lazy var dbQueue:FMDatabaseQueue = {
        return FMDatabaseQueue(path: SSDataStore.databaseFilePath())!
    }()
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: DB Operations
    
    func closeDB() {
        dbQueue.close()
    }
    
    func enableWALMode() {
        dbQueue.inDatabase{ db in
           db.executeStatements("PRAGMA journal_mode=WAL;")
        }
    }

    // MARK: CRUD
    
    @objc func fetchAllLists(_ onFetch:([SSList]) -> Void) -> Void {
        dbQueue.inDatabase { db in
            let resultSet = try! db.executeQuery(sql_ListWithTaxRateInfoSelectAll, values:nil)
            var lists:[SSList] = []
            
            // All Items
            while (resultSet.next()) {
                let list = SSList(resultSet: resultSet)
                lists.append(list)
            }
            
            onFetch(lists)
        }
    }
    
    func fetch(lists listIDs: [String], onFetch:([SSList]?) -> Void) {
        dbQueue.inDatabase { db in
            var lists: [SSList] = []
            listIDs.forEach {
                let resultSet = try! db.executeQuery(sql_ListWithTaxRateInfoSelectFromListID, values:[$0])
                var list: SSList?
                
                // All Items
                while (resultSet.next()) {
                    list = SSList(resultSet: resultSet)
                }
                
                if let fetchedList = list {
                    lists.append(fetchedList)
                }
            }
            
            onFetch(lists)
        }
    }
    
    @objc func fetch(list listID: String, onFetch:(SSList?) -> Void) -> Void {
        dbQueue.inDatabase { db in
            let resultSet = try! db.executeQuery(sql_ListWithTaxRateInfoSelectFromListID, values:[listID])
            var list: SSList?
            
            // All Items
            while (resultSet.next()) {
                list = SSList(resultSet: resultSet)
            }
            
            onFetch(list)
        }
    }
    
    func fetch(list:SSList, onFetch:(((allTags:[SSListTag], allItems:[SSListItem], updatedList:SSList)) -> Void)) -> Void {
        dbQueue.inDatabase { db in
            let resultSet = try! db.executeQuery(sql_ListItemSelectByListID, values: [list.dbID])
            var allItems:[SSListItem] = []
            var allTags:[SSListTag] = []
            
            // All Items
            while (resultSet.next()) {
                let item = SSListItem(resultSet: resultSet)
                allItems.append(item)
            }
            
            // Any misc tagged items?
            if !(allItems.filter{ $0.tag == nil }).isEmpty {
                allTags.append(miscTag)
            }
            
            // All user created tags
            for listItem in allItems where listItem.tag != nil {
                guard let tag = listItem.tag else { continue }
                guard !allTags.contains(tag) else { continue }
                allTags.append(tag)
            }
            allTags.sort{ $0.orderingIndex.intValue < $1.orderingIndex.intValue }
            
            // Sort tags
            allTags.forEach { listTag in
                var tagItems:[SSListItem]
                if listTag == miscTag {
                    tagItems = allItems.filter { $0.tag == nil }
                } else {
                    tagItems = allItems.filter { $0.tag == listTag }
                }
                tagItems.sort{ $0.orderingIndex.intValue < $1.orderingIndex.intValue }
            }
            
            let listResultSet = try! db.executeQuery(sql_ListWithTaxRateInfoSelectFromListID, values: [list.dbID])
            var updatedList:SSList = SSList()
            while (listResultSet.next()) {
                updatedList = SSList(resultSet: listResultSet)
            }
            
            onFetch((allTags, allItems, updatedList))
        }
    }
    
    func fetch(listItem listItemID: String, onFetch:((SSListItem?) -> Void)) {
        dbQueue.inDatabase { db in
            if let result = try? db.executeQuery(sql_ListItemSelectByListItemID, values: [listItemID]) {
                var listItem: SSListItem?
                
                while (result.next()) {
                    listItem = SSListItem(resultSet: result)
                }
                
                onFetch(listItem)
            } else {
                onFetch(nil)
            }
        }
    }
    
    func fetch(tag tagID: String, onFetch:(SSTag?) -> Void) {
        dbQueue.inDatabase { db in
            let result = try? db.executeQuery(sql_TagSelectByTagID, values: [tagID])
            var tag: SSTag?
            
            while (result?.next() ?? false) {
                tag = SSTag(resultSet: result!)
            }
            
            onFetch(tag)
        }
    }
    
    @objc func listExists(_ listID:String, onFetch:((Bool) -> Void)) {
        dbQueue.inDatabase { db in
            onFetch(db.listExists(forID: listID))
        }
    }
    
    func createDatabaseInstance() -> FMDatabase {
        return FMDatabase(path: SSDataStore.databaseFilePath())
    }
        
    @objc func save(list:SSList, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            db.insertList(intoDB: list)
            list.taxInfo.fkListID = list.dbID
            db.insertTaxRateInfo(intoDB: list.taxInfo)
            notifiyListCrud(withLists: [list], completion: completion)
            list.dbForList().save([list, list.taxInfo], with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    @objc func save(listItem:SSListItem, inList list:SSList, completion:onDBCommit? = nil) -> Void {
        self.save(listItems: [listItem], inList: list, completion: completion)
    }
    
    @objc func save(listItems:[SSListItem], inList list:SSList, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            listItems.forEach {
                assert($0.fkListID == list.dbID, "List ID and item ID do not match.")
                db.insertListItem(intoDB: $0, taxInfo: list.taxInfo, taxUtil:list.taxUtil)
            }
            
            notifiyListCrud(withLists: [list], completion: completion)
            list.dbForList().save(listItems, with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    func create(tags:[TagViewModel], completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            var savedTags:[SSTag] = []
            tags.forEach { tagData in
                let orderingIndex:Int = db.mostRecentOrderingIndexForTags()
                let newTag = SSTag(color: tagData.color, name: tagData.name, order: orderingIndex.toNumber())
                db.insertTag(intoDB: newTag)
                savedTags.append(newTag)
            }
            
            if let handler = completion {
                handler()
            }
            
            SSDataStore.sharedInstance().ckManager.privateDB .save(savedTags, with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    @objc func update(list:SSList, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            db.updateList(inDB: list)
            db.updateTaxRateInfo(inDB: list.taxInfo)
            notifiyListCrud(withLists: [list], completion: completion)
            list.dbForList().save([list, list.taxInfo], with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    @objc func update(lists:[SSList], excludingListsFromSync:[SSList]? = nil, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            lists.forEach { list in
                db.updateList(inDB: list)
                db.updateTaxRateInfo(inDB: list.taxInfo)
            }

            var listsToSync:[SSList] = lists
            
            if let exlusions = excludingListsFromSync {
                listsToSync = listsToSync.filter { !exlusions.contains($0) }
            }
            
            listsToSync.forEach {
                $0.dbForList().save([$0, $0.taxInfo], with: .ifServerRecordUnchanged, delete: []) { error in
                    if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
                }
            }
        }
    }
    
    @objc func update(listItems:[SSListItem], inList list:SSList?, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            var listItemList: SSList! = list

            // Fetch list if needed.
            if listItemList == nil {
                guard let firstItem = listItems.first, let parentList = listFromListItem(firstItem, using: db) else { return }
                listItemList = parentList
            }
            
            listItems.forEach { listItem in
                assert(listItem.fkListID == listItemList.dbID, "List ID and item ID do not match.")
                db.updateListItem(inDB: listItem, taxInfo: listItemList.taxInfo, taxUtil:listItemList.taxUtil)
            }
            
            notifiyListCrud(withLists: [listItemList], completion: completion)
            listItemList.dbForList().save(listItems, with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    @objc func update(withSnapshot snap:ListDiff, list:SSList, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            snap.sectionIdentifiers.forEach { tag in
                let items = snap.itemIdentifiers(inSection: tag)
                for (index, item) in items.enumerated() {
                    item.orderingIndex = index.toNumber()
                    assert(item.fkListID == list.dbID, "List ID and item ID do not match.")
                    db.updateListItem(inDB: item, taxInfo: list.taxInfo, taxUtil:list.taxUtil)
                }
            }

            notifiyListCrud(withLists: [list], completion: completion)
            
            var saves:[SSObject] = snap.itemIdentifiers
            saves.append(list)
            
            list.dbForList().save(saves , with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    @objc func delete(listItems:[SSListItem], inList list:SSList?, completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            var listItemList: SSList! = list
            
            // Fetch list if needed.
            if listItemList == nil {
                guard let firstItem = listItems.first, let parentList = listFromListItem(firstItem, using: db) else { return }
                listItemList = parentList
            }
            
            listItems.forEach { item in
                db.deleteListItem(inDB: item)
            }
            
            notifiyListCrud(withLists: [listItemList], completion: completion)
            
            listItemList.dbForList().save([], with: .allKeys, delete: listItems) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
        }
    }
    
    @objc func delete(lists:[SSList], completion:onDBCommit? = nil) -> Void {
        dbQueue.inDatabase { db in
            let listActivities = lists.map(\.dbID)
            NSUserActivity.deleteSavedUserActivities(withPersistentIdentifiers: listActivities) {
                
            }
            
            lists.forEach { list in
                db.deleteList(inDB: list)
            }
            
            SSDataStore.sharedInstance().ckManager.privateDB.save([], with: .ifServerRecordUnchanged, delete: lists) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
            
            if let handler = completion {
                handler()
            }
        }
    }
    
    // MARK: Utils
    
    @objc func copy(item originalItem:SSListItem, to list:SSList, completion:onDBCommit? = nil) {
        let newItem = SSListItem(existing: originalItem, withParentListRecordID: list.objCKRecord.recordID)
        
        if let asset = originalItem.mediaAssetData {
            newItem.attachNewMediaDataToInstance(with: asset)
        }

        if let tag = originalItem.tag {
            newItem.orderingIndex = Int.max.toNumber() // Put it at the end
            newItem.onListTagSet = { tag in
                list.datasourceAdapter.add(newItem)
                self.save(listItem: newItem, inList: list) { [weak self] in
                    self?.notifiyListCrud(withLists: [list])
                    if let handler = completion {
                        handler()
                    }
                }
            }
            newItem.addTag(tag, with: list)
        } else {
            list.datasourceAdapter.add(newItem)
            self.save(listItem: newItem, inList: list) { [weak self] in
                self?.notifiyListCrud(withLists: [list])
                if let handler = completion {
                    handler()
                }
            }
        }
    }
    
    @objc func duplicate(item originalItem:SSListItem, on list:SSList, completion:@escaping onDuplicateItem) {
        let dupedItem = SSListItem(existing: originalItem, withParentListRecordID: list.objCKRecord.recordID)
        dupedItem.orderingIndex = (originalItem.orderingIndex.intValue + 1).toNumber() // Put it right below the duped item
        
        if let asset = originalItem.mediaAssetData {
            dupedItem.attachNewMediaDataToInstance(with: asset)
        }

        if let tag = originalItem.tag {
            dupedItem.onListTagSet = { tag in
                completion(dupedItem)
            }
            dupedItem.addTag(tag, with: list)
        } else {
            completion(dupedItem)
        }
    }
    
    @objc func duplicate(list originalList:SSList, completion:@escaping onDuplicateList) {
        let ogList = originalList.deepCopy()
        let dupedList = SSList(existing: ogList)
        
        // A list must be in the DB first, otherwise the items can't be added.
        save(list: dupedList) {
            let workCount = ogList.datasourceAdapter.allItems.count
            var workCompleted = 0
            
            // Might be duping a list with no items
            if workCount == 0 {
                completion(dupedList)
                return
            }
            
            ogList.datasourceAdapter.allItems.forEach { listItem in
                self.duplicate(item: listItem, on: dupedList) { [unowned self] item in
                    dupedList.add(item)
                    self.save(listItem: item, inList: dupedList) {
                        workCompleted += 1
                        
                        if workCompleted == workCount {
                            completion(dupedList)
                        }
                    }
                }
            }
        }
    }
    
    func restore(list deletedList:SSList, completion:@escaping onDuplicateList) {
        dbQueue.inDatabase { db in
            // Restore list
            let restoreZone = deletedList.objCKRecord.recordID.zoneID
            deletedList.initializeNewRecordsForRedo(with: restoreZone)
            db.insertList(intoDB: deletedList)
            
            // Then tax info
            deletedList.taxInfo.fkListID = deletedList.dbID
            deletedList.taxInfo.initializeNewRecordsForRedo(with: restoreZone)
            deletedList.taxInfo.resetReference(forRedo: deletedList)
            db.insertTaxRateInfo(intoDB: deletedList.taxInfo)
            
            // Items next
            deletedList.datasourceAdapter.allItems.forEach {
                $0.initializeNewRecordsForRedo(with: restoreZone)
                $0.resetReference(forRedo: deletedList)
                
                if let _ = $0.tag, let masterTag = SSListTag.masterTag(for: $0, db: db) {
                    $0.addListTag(masterTag, with: deletedList, withDB: db)
                }
                
                db.insertListItem(intoDB: $0, taxInfo: deletedList.taxInfo, taxUtil: deletedList.taxUtil)
            }
            
            var cloudSaves: [SSObject] = [deletedList, deletedList.taxInfo]
            cloudSaves.append(contentsOf: deletedList.datasourceAdapter.allItems)
            
            deletedList.dbForList().save(cloudSaves, with: .changedKeys, delete: []) { error in
                print("Spend Stack - Finished list restore with error: \(String(describing: error))")
            }
            
            notifiyListCrud(withLists: [deletedList], listsUpdated: true) {
                completion(deletedList)
            }
        }
    }
    
    func moveItems(_ items:[SSListItem], from:SSList, to:SSList, listTagID: String?, completion:onMoveItems? = nil) {
        dbQueue.inDatabase { db in
            var updatedItems: [SSListItem] = []
            var deepCopiedItems: [SSListItem] = []
            
            // Local commits.
            items.forEach {
                // Delete items in the from list
                db.deleteListItem(inDB: $0)
                
                // Deep copy to delete with original record in place
                deepCopiedItems.append($0.deepCopy())
                
                // Move and setup a new record
                $0.resetReference(forRedo: to)
                to.moveItem(toList: $0, withListTagID: listTagID, inDB: db)
                db.insertListItem(intoDB: $0, taxInfo: to.taxInfo, taxUtil: to.taxUtil)
                updatedItems.append($0)
            }
            
            // Cloud commits. Two different operations because they could have two different databases (i.e. a share)
            from.dbForList().save([], with: .allKeys, delete: deepCopiedItems) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
            
            to.dbForList().save(updatedItems, with: .allKeys, delete: []) { error in
                if error != nil { print("Spend Stack: Error in CloudKit op: \(error!.localizedDescription)")}
            }
            
            // Refresh lists and pass them back to the caller
            var updatedFrom: SSList?
            var updatedTo: SSList?
            
            var result = try? db.executeQuery(sql_ListWithTaxRateInfoSelectFromListID, values: [from.dbID])
            while (result?.next() ?? false) {
                updatedFrom = SSList(resultSet: result!)
            }
            
            result = try? db.executeQuery(sql_ListWithTaxRateInfoSelectFromListID, values: [to.dbID])
            while (result?.next() ?? false) {
                updatedTo = SSList(resultSet: result!)
            }
            
            if let handler = completion, let refreshedFrom = updatedFrom, let refreshedTo = updatedTo {
                handler(updatedItems, refreshedFrom, refreshedTo, db)
                notifiyListCrud(withLists: [refreshedFrom, refreshedTo], listsUpdated: true)
            }
        }
    }
    
    @objc func attachTagTo(listItem item:SSListItem, list:SSList, snap:ListDiff, tagVM:SSTagSelectionViewModel, completion:@escaping (() -> ())) {
        switch tagVM.type {
        case .listTag:
            item.onListTagSet = { tag in
                if snap.sectionIdentifiers.contains(tag) {
                    item.orderingIndex = NSNumber(integerLiteral:snap.numberOfItems(inSection: tag))
                }
                completion()
                
            }
            item.addSharedListTag(tagVM.underlyingListTag!, with: list)
        case .masterTag:
            item.onListTagSet = { tag in
                if snap.sectionIdentifiers.contains(tag) {
                    item.orderingIndex = NSNumber(integerLiteral:snap.numberOfItems(inSection: tag))
                }
                completion()
            }
            item.addListTag(tagVM.underlyingTag!, with: list)
        case .unset:
            item.orderingIndex = NSNumber(integerLiteral:snap.numberOfItems(inSection: miscTag))
            completion()
        @unknown default:
            fatalError()
        }
    }
    
    func restore(list:SSList, completion:onDBCommit? = nil) {
        dbQueue.inDatabase { db in
            // Reset records first
            let zoneID = list.objCKRecord.recordID.zoneID
            list.initializeNewRecordsForRedo(with: zoneID)
            list.taxInfo.initializeNewRecordsForRedo(with: zoneID)
            list.taxInfo.resetReference(forRedo: list)
            
            db.insertList(intoDB: list)
            db.insertTaxRateInfo(intoDB: list.taxInfo)
            
            // Now the items
            list.datasourceAdapter.allItems.forEach {
                $0.initializeNewRecordsForRedo(with: zoneID)
                $0.resetReference(forRedo: list)
                
                if let asset = $0.mediaAssetData {
                    $0.attachNewMediaDataToInstance(with: asset)
                }
                
                if let listTag = $0.tag {
                    if let masterTag = SSListTag.masterTag(for: $0, db: db) {
                        $0.addListTag(masterTag, with: list, withDB: db)
                    } else {
                        $0.addSharedListTag(listTag, with: list)
                    }
                    
                }
                
                db.insertListItem(intoDB: $0, taxInfo: list.taxInfo, taxUtil: list.taxUtil)
            }
            
            // CloudKit em'
            var ckSaveObjects: [SSObject] = [list, list.taxInfo]
            ckSaveObjects.append(contentsOf: list.datasourceAdapter.allItems)
            
            list.dbForList().save(ckSaveObjects, with: .allKeys, delete: []) { error in
                print("Spend Stack - Restored list with error: \(String(describing: error))")
            }
            
            notifiyListCrud(withLists: [list])
        }
    }
    
    // MARK: Private Methods
    
    private func notifiyListCrud(withLists lists: [SSList], listsUpdated: Bool = false, completion:onDBCommit? = nil) {
        DispatchQueue.main.async {
            let payload = ListCRUDPayload(lists: lists, listsHaveBeenUpdated: listsUpdated)
            payload.send()
            
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            } 
            
            if let handler = completion {
                handler()
            }
        }
    }
    
    private func listFromListItem(_ listItem:SSListItem, using db:FMDatabase) -> SSList? {
        var listItemList: SSList?

        let listID = listItem.fkListID
        let result = try! db.executeQuery(sql_ListSelectByListID, values: [listID])
        
        while (result.next()) {
            listItemList = SSList(resultSet: result)
        }
        
        return listItemList
    }
}
