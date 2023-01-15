//
//  ListControllerListItemDelegate.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/15/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit

extension ListViewController : SSListItemViewControllerDelegate {
    
    func onEditsCommitted(_ editedListItem: SSListItem) {
        guard let currentList = list else { return }
        guard let ogItem = listItemToEdit, ogItem != editedListItem  else { return }
        let tagChanged = ogItem.tag != editedListItem.tag
        var snapshot = dataSource.snapshot()
        
        if tagChanged {
            let newTag = editedListItem.tag ?? dataSource.store.miscTag
            let allItems = snapshot.itemIdentifiers
            var newSections:[SSListTag] = snapshot.sectionIdentifiers
            if (!newSections.contains(newTag)) {
                newSections.append(newTag)
                newSections.sort{ $0.orderingIndex.intValue < $1.orderingIndex.intValue }
            }
            editedListItem.orderingIndex = Int.max.toNumber() // Put it at the end
            snapshot = dataSource.newSnapShotFrom(listTags: newSections, allItems: allItems)
        }
        snapshot.reloadItems([editedListItem])
        
        if (!tagChanged) { dataSource.defaultRowAnimation = .fade }
        dataSource.ss_apply(snapshot) { [unowned self] in
            self.dataSource.defaultRowAnimation = .right
        }
        dataSource.store.update(withSnapshot: snapshot, list:currentList)
    }
    
    func requestDelete(_ itemToDelete: SSListItem) -> Bool {
        delete(items: [itemToDelete])
        return true
    }
}
