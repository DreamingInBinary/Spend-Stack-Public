//
//  ListControllerDragDelegate.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit

extension ListViewController : UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let listItemTVC:SSListItemBasicTableViewCell = dataSource.tableView(tableView, cellForRowAt: indexPath) as? SSListItemBasicTableViewCell else { return [] }
        guard let listItem = dataSource.itemIdentifier(for: indexPath) else { return [] }
        
        // Provider to make new windows
        let provider = NSItemProvider(object: NSString())
        provider.registerObject(self.listActivityFor(listItem), visibility: NSItemProviderRepresentationVisibility.all)
        let drugListItem = UIDragItem(itemProvider: provider)
        
        // Drag data container
        let dragData = SSListItemDragData()
        dragData.indexPath = indexPath
        dragData.listItems.add(listItem)
        dragData.list = list!
        
        // Drag previews
        drugListItem.localObject = dragData
        drugListItem.previewProvider = {
            return listItemTVC.dragPreviewRepresentation()
        }
        
        session.localContext = dragData
        return [drugListItem]
    }
    
    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let listItemTVC:SSListItemBasicTableViewCell = dataSource.tableView(tableView, cellForRowAt: indexPath) as? SSListItemBasicTableViewCell else { return [] }
        guard let listItem = dataSource.itemIdentifier(for: indexPath) else { return [] }
        
        // Provider to make new windows
        let provider = NSItemProvider(object: NSString())
        provider.registerObject(self.listActivityFor(listItem), visibility: NSItemProviderRepresentationVisibility.all)
        let drugListItem = UIDragItem(itemProvider: provider)
        
        // Drag data container
        let dragData = session.localContext as! SSListItemDragData
        dragData.listItems.add(listItem)
        
        // Drag previews
        drugListItem.localObject = dragData
        drugListItem.previewProvider = {
            return listItemTVC.dragPreviewRepresentation()
        }
        
        session.localContext = dragData
        return [drugListItem]
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        guard let dragData = session.localContext as? SSListItemDragData else { return }
        guard let currentList = list else { return }
        
        let listItems = dragData.listItems as! [SSListItem]
        guard currentList.dbID == listItems.first?.fkListID ?? "" else {
            // Drug item(s) from this list to another one. Just update.
            dataSource.applyFreshSnapShot(withAnimation: true)
            return
        }
        
        // Local reordering happened here. So look for any empty sections.
        var snapshot = dataSource.snapshot()
        let emptySections = snapshot.sectionIdentifiers.filter {
            snapshot.itemIdentifiers(inSection: $0).isEmpty
        }

        if emptySections.count > 0 {
            snapshot.deleteSections(emptySections)
            dataSource.ss_apply(snapshot)
        }

        dataSource.store.update(withSnapshot: snapshot, list:currentList)
    }
}
