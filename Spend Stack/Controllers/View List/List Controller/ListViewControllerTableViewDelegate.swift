//
//  ListViewControllerTableViewDelegate.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

extension ListViewController : UITableViewDelegate {
    
    // MARK: Headers
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard list != nil else { return nil }
        guard dataSource.listHasTaggedItems else { return nil}
        
        let snapshot = dataSource.snapshot()
        let tagKey = snapshot.sectionIdentifiers[section]
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SS_LIST_SECTION_HEADER_ID) as! SSListSectionHeaderView
        headerView.titleString = tagKey.name
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard list != nil else { return 0 }
        guard dataSource.listHasTaggedItems else { return 0}

        let headerView = self.tableView(tableView, viewForHeaderInSection: section) as! SSListSectionHeaderView
        return headerView.estimatedHeightForHeader(in: tableView)
    }
    
    // MARK: Footers
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let currentList = list else { return nil }
        guard ss_defaults().bool(forKey: Show_Tag_Footers) else { return nil }
        
        let snapshot = dataSource.snapshot()
        let tagKey = snapshot.sectionIdentifiers[section]
        let items = snapshot.itemIdentifiers(inSection: tagKey)
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SS_LIST_SECTION_FOOTER_ID) as! SSListSectionFooterView
        footerView.setTotalWith(tagKey, tagItems: items, taxInfo: currentList.taxInfo, currencyID: currentList.currencyIdentifier)
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard list != nil else { return 0 }
        guard ss_defaults().bool(forKey: Show_Tag_Footers) else { return 0 }
        guard let sectionFooter =  self.tableView(tableView, viewForFooterInSection: section) as? SSListSectionFooterView else { return 0 }
        return sectionFooter.estimatedHeightForHeader(in: tableView)
    }
    
    func updateFooters(with snap:ListDiff, footersToReload:[SSListTag]) {
        guard let currentList = list else { return }
        guard ss_defaults().bool(forKey: Show_Tag_Footers) else { return }
 
        footersToReload.forEach { tag in
            if let sectionIndex = snap.sectionIdentifiers.firstIndex(of: tag),
               let footer = tableView.footerView(forSection: sectionIndex) as? SSListSectionFooterView {
                let items = snap.itemIdentifiers.filter { $0.tag ?? dataSource.store.miscTag == tag}
                footer.setTotalWith(tag, tagItems: items, taxInfo: currentList.taxInfo, currencyID: currentList.currencyIdentifier)
            }
        }
    }
    
    // MARK: Two Finger Swipe Edit
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        self.setEditing(true, animated: true)
    }
    
    // MARK: Table View Swipe Actions
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let listItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let showCheckOption = list!.isShowingCheckboxes
        let showNewWindow = isOniPad
        var actions:[UIContextualAction] = []
        
        let delete = UIContextualAction(style: .destructive, title: ss_Localized("general.delete")) { action, view, handler in
            self.presentActionForDelete(for: listItem)
            
            handler(false)
        }
        delete.backgroundColor = UIColor.appleRed()
        delete.image = UIImage(systemName: "trash.circle.fill")
        actions.append(delete)
        
        // Check off it possible
        if showCheckOption {
            let checkString = listItem.checkedOff ? "ctx.ac.uncheck" : "ctx.ac.check"
            let image = listItem.checkedOff ? "circle" : "checkmark.circle"
            let check = UIContextualAction(style: .normal, title: ss_Localized(checkString)) { action, view, handler in
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(SSUIKitTableViewBatchAnimationDuration + 0.3)) {
                    listItem.checkedOff.toggle()
                    self.update(listItems: [listItem])
                }
                handler(true)
            }
            check.backgroundColor = UIColor.appleDarkBlue()
            check.image = UIImage(systemName: image)
            actions.append(check)
        }
        
        // New window if possible
        if showNewWindow {
            let newWindow = UIContextualAction(style: .normal, title: ss_Localized("ctx.ac.window")) { action, view, handler in
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(SSUIKitTableViewBatchAnimationDuration)) {
                    let activity = self.listActivityFor(listItem)
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
                    handler(true)
                }
            }
            newWindow.backgroundColor = UIColor.ssPrimary()
            newWindow.image = UIImage(systemName: "plus.rectangle.on.rectangle.fill")
            actions.append(newWindow)
        }
        
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    // MARK: Contextual Actions
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let listItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
        guard let currentList = list else { return nil }
        var contextActions:[UIMenuElement] = []
        
        let ac_Move = UIAction(title: ss_Localized("ctx.ac.move"), image: UIImage(systemName: "folder")) { [unowned self] action in
            DispatchQueue.main.asyncAfter(deadline: .now() + Int.tableViewBatchDuration()) {
                let selectVC = SelectListViewController(excluding: [currentList]) { list, controller in
                    controller.dismiss(animated: true) {
                        self.dataSource.store.moveItems([listItem], from: currentList, to: list, listTagID: nil) { (items, from, to, db) in
                                var snap = self.dataSource.snapshot()
                                snap.deleteItems(items)
                                
                                let emptySections = snap.sectionIdentifiers.filter { snap.numberOfItems(inSection: $0) == 0 }
                                snap.deleteSections(emptySections)
                                
                                let reloadableFooterSections = Set(items.map{ $0.tag ?? self.dataSource.store.miscTag })
                                self.updateFooters(with: snap, footersToReload: Array(reloadableFooterSections))
                            
                                // Will update other open windows with *this* list
                                self.dataSource.ss_apply(snap)
                            
                                // Will update other open windows where items were moved to
                                let externalPayload = ExternalListCRUDPayload(list: to)
                                externalPayload.send()
                            }
                        }
                    
                        let dragText = ss_Localized("dragThing.movedSingle")
                        let localized = String.localizedStringWithFormat(dragText, listItem.title, list.name)
                        self.view.window?.showDragThing(withIcon: "folder.fill", text: localized)
                    }
                SSPopupModalPresentationController.adaptivePresent(from: self, presented: selectVC)
            }
        }
        
        let ac_Copy = UIAction(title: ss_Localized("ctx.ac.copy"), image: UIImage(systemName: "doc.on.doc")) { action in
            DispatchQueue.main.asyncAfter(deadline: .now() + Int.tableViewBatchDuration()) {
                let title = ss_Localized("selectLists.copy")
                let selectVC = SelectListViewController(excluding: [currentList], title:title) { list, controller in
                    self.dataSource.store.copy(item: listItem, to: list) {
                        // Will update other open windows where items were moved to
                        let externalPayload = ExternalListCRUDPayload(list: list)
                        externalPayload.send()
                
                        controller.dismiss()
                        
                        let dragText = ss_Localized("dragThing.copiedSingle")
                        let localized = String.localizedStringWithFormat(dragText, listItem.title, list.name)
                        self.view.window?.showDragThing(withIcon: "doc.on.doc.fill", text: localized)
                    }
                }
                
                SSPopupModalPresentationController.adaptivePresent(from: self, presented: selectVC)
            }
        }
        
        let ac_Duplicate = UIAction(title: ss_Localized("ctx.ac.duplicate"), image: UIImage(systemName: "plus.square.on.square")) { action in
            DispatchQueue.main.asyncAfter(deadline: .now() + Int.tableViewBatchDuration()) { [unowned self] in
                self.dataSource.store.duplicate(item: listItem, on: currentList) { dupedItem in
                    self.save(item: dupedItem)
                    self.scrollTo(item: dupedItem)
                }
            }
        }
        
        contextActions.append(UIMenu(title: "", options: .displayInline, children: [ac_Move, ac_Copy, ac_Duplicate]))
        
        let ac_Info = UIAction(title: ss_Localized("ctx.ac.info" ), image: UIImage(systemName: "info.circle")) { action in
            DispatchQueue.main.asyncAfter(deadline: .now() + Int.tableViewBatchDuration()) { [unowned self] in
                self.open(item: listItem)
            }
        }
        contextActions.append(ac_Info)
        
        let ac_Rename = UIAction(title: ss_Localized("ctx.ac.rename" ), image: UIImage(systemName: "pencil")) { action in
            self.presentNameOrTitleEdit(list: nil, listItem: listItem)
        }
        contextActions.append(ac_Rename)
        
        let tagString = listItem.tag != nil ? "ctx.ac.removeTag" : "ctx.ac.addTag"
        let tagImg = listItem.tag != nil ? "minus.circle" : "tag"
        let ac_TagToggle = UIAction(title: ss_Localized(tagString), image: UIImage(systemName: tagImg)) { action in
            guard let currentList = self.list else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Int.tableViewBatchDuration()) {
                if let _ = listItem.tag {
                    listItem.deleteTag()
                    listItem.orderingIndex = Int.max.toNumber() // Put it at the end
                    self.dataSource.store.update(listItems: [listItem], inList: currentList) { [unowned self] in
                        self.dataSource.applyFreshSnapShot(withAnimation: true)
                    }
                } else {
                    self.listItemToEdit = listItem
                    let tagVC = SSTagsViewController(selectedTag: nil, delegate: self, scenario: .addingToItem)
                    SSPopupModalPresentationController.adaptivePresent(from: self, presented: tagVC)
                }
            }
        }
        contextActions.append(ac_TagToggle)
        
        let dateString = "ctx.ac.editDate"
        let dateImg = "calendar"
        let ac_DateEdit = UIAction(title: ss_Localized(dateString), image: UIImage(systemName: dateImg)) { action in
            let dateEditVC = DateEditorViewController(withListItem: listItem) { date in
                listItem.customDate = date
                self.update(listItems: [listItem])
            }
            let navVC = SSBottomNavigationViewController(rootViewController: dateEditVC)
            navVC.fixedHeight = 400
            self.present(navVC, animated: true)
        }
        contextActions.append(ac_DateEdit)
        
        if currentList.taxInfo.taxIsEnabled {
            let taxString = listItem.hasTaxApplied ? "ctx.ac.taxOff" : "ctx.ac.taxOn"
            let taxImg = listItem.hasTaxApplied ? "minus.circle" : "plus.circle"
            
            let ac_TaxToggle = UIAction(title: ss_Localized(taxString), image: UIImage(systemName: taxImg)) { action in
                listItem.hasTaxApplied.toggle()
                self.update(listItems: [listItem])
            }
            contextActions.append(ac_TaxToggle)
        }
        
        if currentList.isShowingCheckboxes {
            let checkBoxString = listItem.checkedOff ? "ctx.ac.uncheck" : "ctx.ac.check"
            let checkBoxImage = listItem.checkedOff ? "circle" : "checkmark.circle"
            
            let ac_CheckBoxToggle = UIAction(title: ss_Localized(checkBoxString), image: UIImage(systemName: checkBoxImage)) { action in
                listItem.checkedOff.toggle()
                self.update(listItems: [listItem])
            }
            contextActions.append(ac_CheckBoxToggle)
        }
        
        let openLinkAction:(URL) -> (UIAction) = { link in
            let linkString = "ctx.ac.openLink"
            let linkImg = "link.circle"
            let ac_ViewLink = UIAction(title: ss_Localized(linkString), image: UIImage(systemName: linkImg)) { action in
                let safariVC = SFSafariViewController(url: link)
                safariVC.modalPresentationStyle = .overFullScreen
                self.present(safariVC, animated: true)
            }
            
            return ac_ViewLink
        }
        
        if isOniPad {
            let ac_NewWindow = UIAction(title: ss_Localized("ctx.ac.newWindow"), image: UIImage(systemName: "square.split.2x1")) { action in
                let activity = self.listActivityFor(listItem)
                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
            }
                    
            if let validURL = listItem.linkAttachment, let link = URL(string: validURL) {
                let ac_ViewLink = openLinkAction(link)
                contextActions.append(UIMenu(title: "", options: .displayInline, children: [ac_NewWindow, ac_ViewLink]))
            } else {
                contextActions.append(UIMenu(title: "", options: .displayInline, children: [ac_NewWindow]))
            }
        } else {
            if let validURL = listItem.linkAttachment, let link = URL(string: validURL) {
                let ac_ViewLink = openLinkAction(link)
                contextActions.append(UIMenu(title: "", options: .displayInline, children: [ac_ViewLink]))
            }
        }
        
        let ac_Delete = UIAction(title: ss_Localized("general.delete"), image: UIImage(systemName: "trash")) { action in
            self.presentActionForDelete(for: listItem)
        }
        ac_Delete.attributes = .destructive
        contextActions.append(ac_Delete)
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return UIMenu(title: ss_Localized("ctx.title.item"), children: contextActions)
        }
    }
    
    fileprivate func presentActionForDelete(for item:SSListItem) {
        let acConfirmRemove = UIAlertAction(title: ss_Localized("list.vc.deleteItem"), style: .destructive) { _ in
            self.delete(items: [item])
        }
        
        let acCancel = UIAlertAction(title: ss_Localized("general.cancel"), style: .cancel, handler: nil)
        
        Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen {
            if self.traitCollection.horizontalSizeClass == .compact && !self.isOniPad {
                self.showActionSheet(withTitle: "", message: ss_Localized("list.vc.confirmDeleteItem"), actions:[acConfirmRemove, acCancel])
            } else {
                self.showAlert(withTitle: "", message: ss_Localized("list.vc.confirmDeleteItem"), actions:[acConfirmRemove, acCancel])
            }
        }
    }
    // MARK: Selection
    
    func open(item itemToOpen:SSListItem, completion:(() -> ())? = nil) {
        listItemToEdit = itemToOpen.deepCopy()
        let itemController = SSListItemViewController(listItem: itemToOpen, delegate: self)
        let navVC = SSModalCardNavigationController(rootViewController: itemController)
        navVC.presentationController?.delegate = self
        present(navVC, animated: true) {
            if let handler = completion {
                handler()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            toolBar.disableBarItems(atIndicies: [])
            return
        }
        
        if let tappedItem = dataSource.itemIdentifier(for: indexPath) {
            open(item: tappedItem) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            guard let selectedRows = tableView.indexPathsForSelectedRows else { return }
            
            if selectedRows.isEmpty {
                toolBar.disableBarItems(atIndicies: [NSNumber(integerLiteral: 0), NSNumber(integerLiteral: 2), NSNumber(integerLiteral: 4)])
            } else {
                toolBar.disableBarItems(atIndicies: [])
            }
        }
    }
}
