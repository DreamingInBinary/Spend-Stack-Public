//
//  ListControllerDropDelegate.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

extension ListViewController : UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        if let _ = session.localDragSession {
            return true
        }
        
        let itemDropTypes = [kUTTypeText as String, kUTTypeURL as String, kUTTypeImage as String]
        return session.hasItemsConforming(toTypeIdentifiers: itemDropTypes)
    }

    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        if let localSession = session.localDragSession {
            // Drags from Spend Stack
            for item in localSession.items {
                if let listItemDrag = item.localObject as? SSListItemDragData {
                    // We're dropping in some other content from within Spend Stack
                    localSession.localContext = listItemDrag
                    break
                }
            }
        } else {
            // Drags outside Spend Stack
            print("from outside")
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil {
            let op = session.localDragSession != nil ? UIDropOperation.move : UIDropOperation.cancel
            let intent = session.localDragSession != nil ? UITableViewDropProposal.Intent.insertAtDestinationIndexPath : UITableViewDropProposal.Intent.unspecified
            return UITableViewDropProposal(operation: op, intent: intent)
        } else {
            let op = UIDropOperation.copy
            let intent = UITableViewDropProposal.Intent.insertIntoDestinationIndexPath
            return UITableViewDropProposal(operation: op, intent: intent)
        }
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let currentList = list else { return }
        
        let idp = coordinator.destinationIndexPath ?? IndexPath(row: 0, section: 0)
        let snapshot = dataSource.snapshot()
        
        // Drops originating from within Spend Stack
        if let dragData = coordinator.session.localDragSession?.localContext as? SSListItemDragData  {
            let from = dragData.list
            let to = currentList.deepCopy()
            let listItems = dragData.listItems as! [SSListItem]
            
            // Did we drag into a tagged section without an existing tag attached? Add it. The method below will commit it.
            var listTagID:String? = nil
            if dataSource.listHasTaggedItems && coordinator.destinationIndexPath != nil {
                let sectionTag = snapshot.sectionIdentifiers[idp.section]
                listTagID = sectionTag.fkTagID
            }
            
            // Prep items, give them a proposed row and list tag ID
            var shouldRemoveAllTags = false
            dragData.listItems.forEach { item in
                let listItem = item as! SSListItem
                listItem.proposedInsertionIndex = NSNumber(integerLiteral: idp.row)
                
                // Edge case, they might've moved a tagged item into misc
                if listTagID == nil && coordinator.destinationIndexPath != nil && coordinator.destinationIndexPath?.section == 0 {
                    shouldRemoveAllTags = true
                }
            }
            
            // If they drug items into Misc, delete any tags they currently have
            if shouldRemoveAllTags {
                dragData.listItems.forEach { item in
                    let listItem = item as! SSListItem
                    listItem.deleteTag()
                }
            }
            
            if !isOniPad {
                let dragText = ss_Localized("dragThing.moved")
                let localized = String.localizedStringWithFormat(dragText, String(listItems.count), (listItems.count > 1 ? "items" : "item"), to.name)
                view.window?.showDragThing(withIcon: "folder.fill", text: localized)
            }

            dataSource.store.moveItems(listItems, from: from, to: to, listTagID: listTagID) { [weak self] items, updatedFrom, updatedTo, db in
                guard let self = self else { return }
                
                // Animate drops
                coordinator.items.forEach { element in
                    let dragItem = element.dragItem
                    coordinator.drop(dragItem, toRowAt: idp)
                }
                
                // Update ordering
                to.saveOrderingForItems(withDB: db, forceRefresh: false)
                
                self.list = to
                
                // Reload
                let snapshot = self.dataSource.newSnapShotFrom(listTags: to.datasourceAdapter.sortedTags, allItems: to.datasourceAdapter.allItems)
                self.dataSource.ss_apply(snapshot, animatingDifferences: true)
            }
        } else {
            // From outside of Spend Stack
            guard let item = dataSource.itemIdentifier(for: idp) else { return }
            let session:UIDropSession = coordinator.session
            var itemType:NSItemProviderReading.Type?
            var dragIcon:String = ""
            var dragPrompt:String = ""
            
            if session.canLoadObjects(ofClass: NSString.self) {
                itemType = NSString.self
                dragIcon = "doc.plaintext"
                dragPrompt = ss_Localized("drop.noteOnItem") + item.title
            } else if session.canLoadObjects(ofClass: NSURL.self) {
                itemType = NSURL.self
                dragIcon = "link.circle"
                dragPrompt = ss_Localized("drop.linkOnItem") + item.title
            } else if session.canLoadObjects(ofClass: UIImage.self) {
                itemType = UIImage.self
                dragIcon = "photo"
                dragPrompt = ss_Localized("drop.imageOnItem") + item.title
            }
            
            if let droppedType = itemType {
                session.loadObjects(ofClass: droppedType) { [weak self] items in
                    guard !items.isEmpty else { return }
                    let droppedData = items.first!
                    
                    if itemType == NSString.self {
                        let text = droppedData as! String
                        
                        if text.contains("http") {
                            dragIcon = "link.circle"
                            dragPrompt = ss_Localized("drop.linkOnItem") + item.title
                            item.linkAttachment = text
                        } else {
                            item.notes = text
                        }

                    } else if itemType == UIImage.self {
                        let image = droppedData as! UIImage
                        
                        if item.mediaAttachment != nil {
                            item.removeMediaFromItem()
                        }
                        
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            item.attachNewMediaDataToInstance(with: data)
                        }
                    } else if itemType == URL.self {
                        
                    }
                    
                    UIFeedbackGenerator.playFeedback(of: .success)
                    self?.view.window?.showDragThing(withIcon: dragIcon, text: dragPrompt)
                    self?.update(listItems: [item])
                }
            }
        }
    }
}
