//
//  ListControllerSearchResponder.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation

extension ListViewController {
    @objc func openListItem(with intent:SSListItemAttribute, item:SSListItem) {
        guard let ds = dataSource else { return }
        guard let localItem = ds.snapshot().itemIdentifiers.first(where: { $0.dbID == item.dbID }) else { return }
        
        listItemToEdit = localItem.deepCopy()
        let controller:SSListItemViewController
        if intent == .notes {
            controller = SSListItemViewController(listItem: localItem, delegate: self, editing: .notes)
        } else {
            controller = SSListItemViewController(listItem: localItem, delegate: self)
        }
        
        let navVC = SSModalCardNavigationController(rootViewController: controller)
        present(navVC, animated: true)
    }
}
