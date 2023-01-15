//
//  ListControllerToolBar.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import SwiftUI
import MobileCoreServices
import SwiftCSV
import UniformTypeIdentifiers

// MARK: Toolbar

extension ListViewController {
        
    func createToolBar() -> SSToolbar {
        let toolBar = SSToolbar(itemTypes: [])
        
        toolBar.shouldHideBarBackground = true
        toolBar.onDelete = deleteSelectedItems()
        toolBar.onExport = exportSelectedItems()
        toolBar.onBasicAdd = presentItemEntry()
        toolBar.onEdit = setTableViewToEditMode()
        toolBar.onPieChart = presentInsights()
        toolBar.onCreditCard = presentCardImport()
        toolBar.onTotal = showListTotal()
        toolBar.onGenericNoBorderAction = presentBulkAddTag()
        
        return toolBar
    }
    
    func toggleToolBar(with toolbar:SSToolbar) {
        if isEditing {
            toolbar.genericNoBorderButtonTitle = ss_Localized("list.vc.setTag")
            toolbar.setToolBarItems([SSToolBarItemTypeDelete,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeExport,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeGenericNoBorder])
            toolbar.disableBarItems(atIndicies: [0.toNumber(),
                                                 2.toNumber(),
                                                 4.toNumber()])
        } else if (list != nil && !dataSource.snapshot().itemIdentifiers.isEmpty) {
            toolbar.setToolBarItems([SSToolBarItemTypeTotal,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeEdit,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypePieChart,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeCreditCard,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeBasicAdd])
        } else {
            toolbar.setToolBarItems([SSToolBarItemTypeTotal,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypePieChart,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeCreditCard,
                                     SSToolBarItemTypeFlexSpace,
                                     SSToolBarItemTypeBasicAdd])
        }
        
        if #available(iOS 14.0, *) {
            if let tbExport = toolBar.item(fromType: SSToolBarItemTypeExport) {
                tbExport.target = nil
                tbExport.action = nil
                tbExport.menu = createExportMenu()
                toolBar.replaceToolBarItem(forType: SSToolBarItemTypeExport, with: tbExport)
            }
        }
    }
    
    fileprivate func deleteSelectedItems() -> () -> Void {
        return { [weak self] in
            let delete = UIAlertAction(title: ss_Localized("list.vc.deleteItems"), style: .destructive) { action in
                guard let currentList = self?.list else { return }
                let items:[SSListItem] = self?.listItemsForSelectedRows() ?? []
                
                var snap = self?.dataSource.snapshot()
                snap?.deleteItems(items)
                let emptyItems = snap?.sectionIdentifiers.filter{ snap?.numberOfItems(inSection: $0) == 0 }
                snap?.deleteSections(emptyItems ?? [])
                self?.dataSource.ss_apply(snap!)
                
                self?.dataSource.store.delete(listItems: items, inList: currentList)
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(SSUIKitTableViewBatchAnimationDuration)) {
                    self?.setEditing(false, animated: true)
                }
            }
            
            let cancel = UIAlertAction(title: ss_Localized("general.cancel"), style: .cancel, handler: nil)
            let multipleItems = self?.tableView.indexPathsForSelectedRows?.count ?? 1 > 1
            let title = multipleItems ? ss_Localized("list.vc.deleteItems") : ss_Localized("list.vc.deleteItem")
            let msg = multipleItems ? ss_Localized("list.vc.confirmDeleteItems") : ss_Localized("list.vc.confirmDeleteItem")
            self?.showAlert(withTitle: title, message: msg, actions: [delete, cancel])
        }
    }
    
    fileprivate func exportSelectedItems() -> () -> Void {
        return { [unowned self] in
            guard let idps = self.tableView.indexPathsForSelectedRows else { return }
            guard let currentList = self.list else { return }
            
            var items:[SSListItem] = []
            idps.forEach { idp in
                let item = self.dataSource.itemIdentifier(for: idp)
                if item != nil { items.append(item!) }
            }
            
            var sections:[SSListTag] = []
            items.forEach { item in
                let tag = item.tag ?? self.dataSource.store.miscTag
                if !sections.contains(tag) {
                    sections.append(tag)
                }
            }
            
            let snap = self.dataSource.newSnapShotFrom(listTags: sections, allItems: items)
            let exporter = SSListExporter(snapshot: snap as NSDiffableDataSourceSnapshotReference, list: currentList)
            self.showActivityController(with: exporter)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(SSUIKitTableViewBatchAnimationDuration)) {
                self.setEditing(false, animated: true)
            }
        }
    }
    
    fileprivate func createExportMenu() -> UIMenu? {
        guard let idps = self.tableView.indexPathsForSelectedRows else { return nil }
        guard let currentList = self.list else { return nil }
        
        var items:[SSListItem] = []
        idps.forEach { idp in
            let item = self.dataSource.itemIdentifier(for: idp)
            if item != nil { items.append(item!) }
        }
        
        var sections:[SSListTag] = []
        items.forEach { item in
            let tag = item.tag ?? self.dataSource.store.miscTag
            if !sections.contains(tag) {
                sections.append(tag)
            }
        }
        
        let snap = self.dataSource.newSnapShotFrom(listTags: sections, allItems: items)
        let exporter = SSListExporter(snapshot: snap as NSDiffableDataSourceSnapshotReference, list: currentList)
        return createExportMenu(with: exporter)
    }
    
    fileprivate func presentItemEntry() -> () -> () {
        return { [weak self] in
            self?.presentItemAdd()
        }
    }
    
    fileprivate func setTableViewToEditMode() -> () -> () {
        return { [weak self] in
            self?.setEditing(true, animated: true)
        }
    }
    
    fileprivate func presentInsights() -> () -> Void {
        return { [weak self] in
            guard let currentList = self?.list else { return }
            let insightsVC = SSListInsightsViewController(list: currentList)
            let navVC = SSModalCardNavigationController(rootViewController: insightsVC)
            self?.present(navVC, animated: true)
        }
    }
    
    fileprivate func presentCardImport() -> () -> Void {
        return { [weak self] in
            guard let _ = self?.list else { return }
            if !ss_defaults().bool(forKey: SS_HAS_SEEN_APPLE_CARD_SPLASH) {
                let cardSplashVC = AppleCardSplashViewController()
                cardSplashVC.onGetStartedTapped = {
                    self?.openFilePicker()
                }
                
                if self?.isOniPad ?? false {
                    // Need a bar button to dismiss on iPad if they have a mouse
                    let navVC = UINavigationController(rootViewController: cardSplashVC)
                    let style = UINavigationBarAppearance(barAppearance: navVC.navigationBar.standardAppearance)
                    style.configureWithTransparentBackground()
                    navVC.navigationBar.standardAppearance = style
                    self?.present(navVC, animated:true)
                } else {
                    self?.present(cardSplashVC, animated:true)
                }
        
            } else {
                self?.openFilePicker()
            }
        }
    }
    
    fileprivate func showListTotal() -> () -> Void {
        return { [weak self] in
            guard let currentList = self?.list else { return }
            let breakdownVC = SSListBreakdownViewController(list: currentList)
            let navVC = SSBottomNavigationViewController(rootViewController: breakdownVC)
            self?.present(navVC, animated: true)
        }
    }
    
    fileprivate func presentBulkAddTag() -> () -> Void {
        return { [unowned self] in
            let tagVC = SSTagsViewController(selectedTag: nil, delegate: self, scenario: .addingToItem)
            SSPopupModalPresentationController.adaptivePresent(from: self, presented: tagVC)
        }
    }
}

// MARK: Doc Picker Delegate

extension ListViewController : UIDocumentPickerDelegate {

    fileprivate func openFilePicker() {
        var docPicker: UIDocumentPickerViewController!
        
        if #available(iOS 14.0, *) {
            let csvType = UTType.commaSeparatedText
            docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [csvType], asCopy: true)
        } else {
            docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeCommaSeparatedText as String], in: .import)
        }
        
        docPicker.delegate = self
        self.present(docPicker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let currentList = list else { return }
        guard let filePath = urls.first?.path else { return }
        
        do {
            let importStatement = URL(fileURLWithPath: filePath)
            let csvFile: CSV = try CSV(url: importStatement)

            var items:[AppleCardImportItem] = []
            
            try? csvFile.enumerateAsArray(startAt:1) {
                let item = AppleCardImportItem(withDataArray: $0)
                items.append(item)
            }
            items = items.filter({ $0.purchaseType != .Payment})
            
            let importVC = AppleCardImportViewController(withAppleCardImportItems: items, list:currentList, dataSource:dataSource)
            if (SSCitizenship.allowCustomPresentation()) {
                importVC.view.backgroundColor = .clear
                importVC.definesPresentationContext = true
                importVC.modalPresentationStyle = .custom
                importVC.transitioningDelegate = modalAnimator
            }
            
            importVC.onImport = { [unowned self] items in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    guard let thisWindow = self.view.window else { return }
                    thisWindow.showDragThing(withIcon: "checkmark.circle.fill", text: ss_Localized("appleCard.done"))
                    UIImpactFeedbackGenerator.playFeedback(of: .success)
                }
                
                self.dataSource.applyFreshSnapShot(withAnimation: true, postChange: true) { list in
                    let payload = ListCRUDPayload(lists: [list])
                    payload.send()
                }
            }
            
            self.present(importVC, animated: true)
        } catch {
            print("Spend Stack: Error importing file: \(error)")
            self.showAlert(withTitle: ss_Localized("general.error.title"), message: ss_Localized("error.appleCardImport"))
        }
    }
}

// MARK: Nav bar

extension ListViewController {
    func toggleNavBar() {
        var items:[UIBarButtonItem] = []
        
        if self.isEditing {
            items.append(self.editButtonItem)
        } else {
            let share = createShareBarButton()
            let more = createMoreBarButton()
            items = [more, share]
        }
        
        navigationItem.rightBarButtonItems = items
        
        let isSingleWindow = navigationController == nil
        if isSingleWindow && isOniPad {
            navigationItem.leftBarButtonItems = [createDoneBarButton()]
        }
    }
    
    func createShareBarButton() -> UIBarButtonItem {
        var isSharingList = false
        if let currentList = list {
            isSharingList = currentList.objCKRecord.share != nil
        }

        let shareImg = isSharingList ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus"
        let shareTitle = isSharingList ? "list.vc.collabDetails" : "list.vc.collabPrompt"
        let sharBarIcon = UIImage(systemName: shareImg)
        let shareButton = UIBarButtonItem(image: sharBarIcon, style: .plain, target: self, action: #selector(presentCloudKitShareController))
        shareButton.title = ss_Localized(shareTitle)
        shareButton.largeContentSizeImage = sharBarIcon?.imageScaled(to: CGSize(width: 80, height: 80))
        shareButton.landscapeImagePhone = sharBarIcon?.imageScaled(to: CGSize(width: 20, height: 20))
        
        return shareButton
    }
    
    func createMoreBarButton() -> UIBarButtonItem {
        let image = UIImage(systemName: "ellipsis.circle")
        let moreBarButton = UIBarButtonItem(image: image, style: .plain
            , target: self, action: #selector(presentListSettings))
        moreBarButton.title = ss_Localized("list.vc.settings")
        moreBarButton.largeContentSizeImage = image?.imageScaled(to: CGSize(width: 80, height: 80))
        moreBarButton.landscapeImagePhone = image?.imageScaled(to: CGSize(width: 20, height: 20))
        
        return moreBarButton
    }
    
    func createDoneBarButton() -> UIBarButtonItem {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(destroyScene))
        button.accessibilityHint = "Close this list's window."
        return button
    }
    
    @objc func presentCloudKitShareController() {
        SSDataStore.sharedInstance().presentSharing(self, for: list!, anchorBarItem: navigationItem.rightBarButtonItems?[1], sourceView: nil)
    }
    
    @objc func presentListSettings() {
        guard let currentList = list else { return }
        let settingsVC = SSListSettingsViewController(list: currentList, delegate: self)
        SSPopupModalPresentationController.adaptivePresent(from: self, presented: settingsVC)
    }
    
    @objc func destroyScene() {
        guard let session = view.window?.windowScene?.session else { return }
        UIApplication.shared.requestSceneSessionDestruction(session, options: nil, errorHandler: nil)
    }
}

// MARK: Exporting

extension ListViewController {
    func showActivityController(with exporter:SSListExporter) {
        let text = UIAlertAction(title: ss_Localized("list.vc.text"), style: .default) { action in
            let activityVC = UIActivityViewController(activityItems: [exporter.textRepresentationForList() ?? ""], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
        
        let image = UIAlertAction(title: ss_Localized("list.vc.image"), style: .default) { action in
            let activityVC = UIActivityViewController(activityItems: [exporter.imageRepresentation(forList: self.tableView) ?? ""], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
        
        let pdf = UIAlertAction(title: ss_Localized("list.vc.pdf"), style: .default) { action in
            let activityVC = UIActivityViewController(activityItems: [exporter.pdfRepresentationForList() ?? ""], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
        
        let cancel = UIAlertAction(title: ss_Localized("general.cancel"), style: .cancel, handler: nil)
        
        showActionSheet(withTitle: ss_Localized("list.vc.share"), message: ss_Localized("list.vc.shareMethod"), actions: [text,image,pdf,cancel])
    }
    
    func createExportMenu(with exporter:SSListExporter) -> UIMenu {
        let text = UIAction(title: ss_Localized("list.vc.text"), image: UIImage(systemName: "square.fill.text.grid.1x2")) { _ in
            Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen {
                let activityVC = UIActivityViewController(activityItems: [exporter.textRepresentationForList() ?? ""], applicationActivities: nil)
                self.present(activityVC, animated: true) {
                    if self.isEditing {
                        self.setEditing(false, animated: true)
                    }
                }
            }
        }
        
        let image = UIAction(title: ss_Localized("list.vc.image"), image: UIImage(systemName: "photo")) { _ in
            Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen {
                let activityVC = UIActivityViewController(activityItems: [exporter.imageRepresentation(forList: self.tableView) ?? ""], applicationActivities: nil)
                self.present(activityVC, animated: true) {
                    if self.isEditing {
                        self.setEditing(false, animated: true)
                    }
                }
            }
        }
        
        let pdf = UIAction(title: ss_Localized("list.vc.pdf"), image: UIImage(systemName: "doc.richtext")) { _ in
            Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen {
                let activityVC = UIActivityViewController(activityItems: [exporter.pdfRepresentationForList() ?? ""], applicationActivities: nil)
                self.present(activityVC, animated: true) {
                    if self.isEditing {
                        self.setEditing(false, animated: true)
                    }
                }
            }
        }
            
        return UIMenu(title: ss_Localized("list.vc.share"), children: [text, image, pdf])
    }
}
