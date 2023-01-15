//
//  ListsCollectionViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/6/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import Combine
import SnapKit
import SwiftUI

// This class is an experiment to work with the collection view list style.
// During Xcode 12 beta season, it was just too buggy to ship. This hasn't
// Had any logic added to this screen since August 7th, 2020.

@available(iOS 14.0, *)
class ListsCollectionViewController: SSBaseViewController {

    // MARK: Public properties
    var quickActionHandler: QuickActionShortcutHandler?
    
    // MARK: Private properties
    private var collectionView: UICollectionView! = nil
    private var listsDataSource: ListsCollectionViewDataSource! = nil
    private var exporter: SSListExporter! = nil
    private var subscriptions:[AnyCancellable] = []
    private lazy var searchController: UISearchController = {
        return UISearchController(searchResultsController: quickFindVC)
    }()
    private lazy var quickFindVC: SSQuickFindViewController = {
        return SSQuickFindViewController(delegate: self)
    }()
    private let toolBar:SSToolbar = SSToolbar(forDynamicStlyingWithItemTypes: [])
    private let modalAnimator: SSBlurModalAnimator = SSBlurModalAnimator()
    private var lastDeleteList: SSList?
    private var loadingHUD: LoadingHUDView?
    private let syncLabel = SSSyncLabelView(frame: .zero)
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        setupCombineSubs()
        listsDataSource.applyFreshSnapshot(animating: false) { [weak self] in
            self?.toggleToolBar()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocationUtil.sharedInstance().triggerLocationUpdate()
        applyCustomSidebarColors()
        deselectCollectionItem(collectionView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        print("Spend Stack - Skipping ratings prompt for debug build.")
        #else
        RatingsPrompter.sharedInstance().showRatingsPromptIfNeeded()
        #endif
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { ctx in
            self.applyCustomSidebarColors()
        } completion: { ctx in
            
        }

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.isDifferentThanTraitCollection(previousTraitCollection) {
            let note = Notification.Name(SS_TRAIT_COLLECTION_CHANGED)
            NotificationCenter.default.post(name: note, object: nil)
        }
    }
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
        toggleToolBar()
    }
}

// MARK: View Setup
@available(iOS 14.0, *)
extension ListsCollectionViewController {
    private func configureHierarchy() {
        definesPresentationContext = true
        setupNavBar()
        setupSearchBar()
        setupCollectionView()
        setupDataSource()
        setupToolBar()
        setConstraints()
    }

    private func setupNavBar() {
        title = ss_Localized("general.lists")
        
        let moreAction = UIAction(title: "") { handler in
            let showMore = SSHelpAndMoreViewController()
            self.adaptivePresent(showMore)
        }
        let moreBarButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), primaryAction: moreAction)
        moreBarButton.title = ss_Localized("general.settings")
        moreBarButton.largeContentSizeImage = UIImage(systemName: "ellipsis.circle")?.imageScaled(to: CGSize(width: 80, height: 80))
        moreBarButton.landscapeImagePhone = UIImage(systemName: "ellipsis.circle")?.imageScaled(to: CGSize(width: 20, height: 20))
        navigationItem.rightBarButtonItem = moreBarButton
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupSearchBar() {
        searchController = UISearchController(searchResultsController: quickFindVC)
        searchController.searchBar.autocapitalizationType = .none
        searchController.delegate = self
        searchController.showsSearchResultsController = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = quickFindVC
        searchController.searchResultsUpdater = quickFindVC
        quickFindVC.searchController = searchController
        navigationItem.searchController = searchController
    }
    
    private func setupCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .grouped)
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexpath in
            guard let self = self else { return nil }
            guard let list = self.listsDataSource.itemIdentifier(for: indexpath) else { return nil }
            var actions:[UIContextualAction] = []

            let ctxAcDelete = UIContextualAction(style: .destructive, title: ss_Localized("general.delete")) { action,view,handler  in
                Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen { [weak self] in
                    self?.presentDeleteListConfirmation(for: [list])
                    handler(true)
                }
            }
            ctxAcDelete.image = UIImage(systemName: "trash.circle.fill")
            actions.append(ctxAcDelete)

            let ctxAcNewWindow = UIContextualAction(style: .destructive, title: ss_Localized("ctx.ac.newWindow")) { action,view,handler  in
                Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen { [weak self] in
                    guard let self = self else { return }
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: self.listActivity(for: list), options: nil, errorHandler: nil)
                    handler(true)
                }
            }
            ctxAcNewWindow.image = UIImage(systemName: "plus.rectangle.fill.on.rectangle.fill")
            ctxAcNewWindow.backgroundColor = .ssPrimary()
            if self.isOniPad {
                actions.append(ctxAcNewWindow)
            }

            return UISwipeActionsConfiguration(actions: actions)
        }
        config.backgroundColor = .clear
        config.showsSeparators = false
        config.headerMode = .supplementary
    
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.addSubview(collectionView)
        collectionView.setCollectionViewLayout(layout, animated: false)

        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.delegate = self
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.contentInsetAdjustmentBehavior = .never
    }
    
    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<SSListCollectionViewCell, SSList> { [weak self] (cell, indexPath, list) in
            cell.setData(list)
            cell.updateColors(self?.isCompactWidth() ?? false)
            cell.accessories = [.multiselect(displayed: .whenEditing, options: .init())]
        }
    
        listsDataSource = ListsCollectionViewDataSource(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: SSList) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
        listsDataSource.reorderingHandlers.canReorderItem = { item in
            return true
        }
        listsDataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            let diff = transaction.finalSnapshot
            self.listsDataSource.saveNewOrder(from: diff)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration <SSMapInfoHeaderView>(elementKind: "Header") {
            (mapView, string, indexPath) in
            guard NSLocale.isUnitedStates(),
                  LocationUtil.sharedInstance().locationServicesEnabled() else {
                mapView.isHidden = true
                mapView.snp.remakeConstraints { make in
                    make.height.equalTo(0.0)
                }
                return
            }
            
            if mapView.isHidden {
                mapView.isHidden = false
                mapView.setConstraints()
                mapView.forceUpdateUI()
            } else {
                mapView.updateTaxRateForLocation()
            }
        }
        
        listsDataSource.supplementaryViewProvider = { (collectionView, elementKind, indexPath) in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func setupToolBar() {
        view.addSubview(toolBar)
        toolBar.addSubview(syncLabel)
        syncLabel.snp.makeConstraints { make in
            make.center.equalTo(toolBar.snp.center)
            make.height.equalTo(toolBar.snp.height)
            make.width.equalTo(toolBar.snp.width).multipliedBy(0.5)
        }
    }
    
    fileprivate func setConstraints() {
        toolBar.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.width.equalTo(view.snp.width)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(toolBar.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
        }
    }
}

// MARK: Toolbar Functions
@available(iOS 14.0, *)
extension ListsCollectionViewController {
    fileprivate func toolbarOnAddCircleTag() -> () -> Void {
        return { [weak self] in
            guard let self = self else { return }
            let tagsVC = SSTagsViewController(selectedTag: nil, delegate: self, scenario: .manageTags)
            self.adaptivePresent(tagsVC)
        }
    }
    
    fileprivate func toolbarOnExport() -> UIMenu {
        let imgText = UIImage(systemName: "doc.text")
        let actionText = UIAction(title: ss_Localized("general.text"), image: imgText) { handler in
            self.setupExporter(for: self.listsForSelectedIndexPaths())
            let textForLists = self.exporter.textRepresentationForLists()
            let activityItemVC = UIActivityViewController(activityItems: [textForLists as Any], applicationActivities: nil)
            self.setEditing(false, animated: true)
            self.present(activityItemVC, animated: true)
        }
        
        let imgRichText = UIImage(systemName: "doc.richtext")
        let actionPDF = UIAction(title: ss_Localized("general.pdf"), image: imgRichText) { handler in
            self.setupExporter(for: self.listsForSelectedIndexPaths())
            let textForLists = self.exporter.pdfRepresentationForLists()
            let activityItemVC = UIActivityViewController(activityItems: [textForLists as Any], applicationActivities: nil)
            self.setEditing(false, animated: true)
            self.present(activityItemVC, animated: true)
        }
        
        let imgPrint = UIImage(systemName: "printer")
        let actionPrint = UIAction(title: ss_Localized("general.print"), image: imgPrint) { handler in
            guard UIPrintInteractionController.isPrintingAvailable else {
                self.showAlert(withTitle: ss_Localized("general.print.no"), message: ss_Localized("general.print.no2"))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                self.setupExporter(for: self.listsForSelectedIndexPaths())
                let printer = self.exporter.printControllerForLists()
                self.setEditing(false, animated: true)
                printer?.present(animated: true) { printer, completed, error in
                    
                }
            }
        }
        
        return UIMenu(title: "", children: [actionText, actionPDF, actionPrint])
    }
    
    fileprivate func toolbarOnDelete() -> () -> Void {
        return { [weak self] in
            guard let self = self, let selections = self.collectionView.indexPathsForSelectedItems else { return }
            let lists: [SSList] = selections.compactMap { self.listsDataSource.itemIdentifier(for: $0) }
            self.presentDeleteListConfirmation(for: lists)
        }
    }
        
    fileprivate func toolbarOnSort() -> UIMenu {
        let imgAlpha = UIImage(systemName: "a.circle")
        let acSortAlphabetically = UIAction(title: ss_Localized("general.alphabetically"), image:imgAlpha) { handler in
            self.listsDataSource.applySortOption(.alphabetically)
        }
        
        let imgNewest = UIImage(systemName: "arrow.up.square")
        let acSortNewest = UIAction(title: ss_Localized("general.newest"), image:imgNewest) { handler in
            self.listsDataSource.applySortOption(.newest)
        }
        
        let imgOldest = UIImage(systemName: "arrow.down.square")
        let acSortOldest = UIAction(title: ss_Localized("general.oldest"), image:imgOldest) { handler in
            self.listsDataSource.applySortOption(.oldest)
        }
    
        return UIMenu(title: "", children: [acSortOldest,acSortNewest, acSortAlphabetically])
    }
    
    fileprivate func toggleToolBar() {
        var items: [String] = []

        let snap = listsDataSource.snapshot()
        if snap.itemIdentifiers.isEmpty {
            navigationItem.leftBarButtonItem = nil
        } else {
            let customEdit = toolBar.item(fromType: SSToolBarItemTypeEdit)
            customEdit?.primaryAction = UIAction(title: ss_Localized("barItem.edit"), image: UIImage(systemName:"pencil.circle")) { handler in
                self.setEditing(true, animated: true)
            }
            navigationItem.leftBarButtonItem = customEdit
        }
        
        let disableExportAndDelete = collectionView.isEditing && !snap.itemIdentifiers.isEmpty
        if disableExportAndDelete {
            items = [SSToolBarItemTypeExport, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeDelete]
            toolBar.setToolBarItems(items)
            toolBar.disableBarItems(atIndicies: [0.toNumber(), 2.toNumber()])
            navigationItem.leftBarButtonItem = self.editButtonItem
        } else {
            if snap.itemIdentifiers.count >= 2 {
                items = [SSToolBarItemTypeSort, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeAddCircleTag, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeBasicAdd]
            } else {
                items = [SSToolBarItemTypeAddCircleTag, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeBasicAdd]
            }
            
            toolBar.setToolBarItems(items)
        }
        
        toolBar.onAddCircleTag = toolbarOnAddCircleTag()
        
        if let tbExport = toolBar.item(fromType: SSToolBarItemTypeExport) {
            tbExport.target = nil
            tbExport.action = nil
            tbExport.menu = toolbarOnExport()
            tbExport.isEnabled = !disableExportAndDelete
            toolBar.replaceToolBarItem(forType: SSToolBarItemTypeExport, with: tbExport)
        }
        
        toolBar.onDelete = toolbarOnDelete()
        
        if let tbSort = toolBar.item(fromType: SSToolBarItemTypeSort) {
            tbSort.target = nil
            tbSort.action = nil
            tbSort.menu = toolbarOnSort()
            toolBar.replaceToolBarItem(forType: SSToolBarItemTypeSort, with: tbSort)
        }
        
        toolBar.onBasicAdd = { [weak self] in
            self?.presentWithBlurModalFor(controller: SSAddListViewController())
        }
    }
}

// MARK: Search Result Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController : SSQuickFindViewControllerDelegate {
    func ss_searchTermWasTapped(_ result: SSQuickFindResult) {
        switch result.type {
        case .list:
            if let matchedList = listsDataSource.snapshot().itemIdentifiers.first(where: { $0.dbID == result.objectID }) {
                open(matchedList)
            }
        case .listItem:
            listsDataSource.store.fetch(listItem: result.objectID) { listItem in
                guard let item = listItem else { return }
                let listItemVC = SSListItemViewController(listItem: item, delegate: self)
                let navVC = SSModalCardNavigationController(rootViewController: listItemVC)
                present(navVC, animated: true)
            }
        case .note:
            listsDataSource.store.fetch(listItem: result.objectID) { listItem in
                guard let item = listItem else { return }
                let listItemVC = SSListItemViewController(listItem: item, delegate: self, editing: .notes)
                let navVC = SSModalCardNavigationController(rootViewController: listItemVC)
                present(navVC, animated: true)
            }
        case .tag:
            listsDataSource.store.fetch(tag: result.objectID) { tag in
                guard let selectedTag = tag else { return }
                let tagsManagerVC = SSTagsManagerViewController(tag: selectedTag, delegate: self)
                adaptivePresent(tagsManagerVC)
            }
        case .unknown:
            print()
        @unknown default:
            print()
        }
    }
}

// MARK: Tags Manager Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController : SSTagsManagerViewControllerDelegate {
    // do.nothing()
}

// MARK: List Item Controller Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController : SSListItemViewControllerDelegate {
    func onEditsCommitted(_ editedListItem: SSListItem) {
        listsDataSource.store.update(listItems: [editedListItem], inList: nil) {
            DispatchQueue.main.async { [weak self] in
                self?.listsDataSource.store.fetch(list: editedListItem.fkListID) { list in
                    guard let fetchedList = list else { return }
                    let payload = ExternalListCRUDPayload(list: fetchedList)
                    payload.send()
                }
            }
        }
    }
    
    func requestDelete(_ itemToDelete: SSListItem) -> Bool {
        listsDataSource.store.delete(listItems: [itemToDelete], inList: nil) {
            DispatchQueue.main.async { [weak self] in
                self?.listsDataSource.store.fetch(list: itemToDelete.fkListID) { list in
                    guard let fetchedList = list else { return }
                    let payload = ExternalListCRUDPayload(list: fetchedList)
                    payload.send()
                }
            }
        }
        
        return true
    }
}

// MARK: Combine Subscriptions
@available(iOS 14.0, *)
extension ListsCollectionViewController {
    private func setupCombineSubs() {
        let nc = NotificationCenter.default
        
        // Accepted CloudKit Share. Scroll to the list and highlight it
        let shareNote = Notification.Name(rawValue: SS_CK_MANAGER_ACCEPTED_SHARE)
        nc.publisher(for: shareNote)
        .compactMap { $0.object as? String }
        .receive(on: RunLoop.main)
        .sink { [weak self] listID in
            guard let self = self else { return }
            guard let acceptedSharedList = self.listsDataSource.snapshot().itemIdentifiers.first(where: { $0.dbID == listID}), let idp = self.listsDataSource.indexPath(for: acceptedSharedList) else { return }

            self.collectionView.scrollToItem(at: idp, at: .bottom, animated: true)
            0.5.secondDelayThen {
                self.collectionView.cellForItem(at: idp)?.animateHighlightCallout()
            }
        }.store(in: &subscriptions)
        
        // Custom sidebar colors
        nc.publisher(for: UIApplication.didBecomeActiveNotification)
        .sink { [weak self] note in
            guard let self = self else { return }
            self.applyCustomSidebarColors()
        }.store(in: &subscriptions)
        
        // List created reloading
        nc.publisher(for: .listCreated)
        .compactMap { $0.object as? ListCreatedPayload }
        .sink { [weak self] payload in
            guard let self = self else { return }
            let isSameWindow = self.windowSceneID == payload.windowSceneID
            let currentSelectedList = self.collectionView.indexPathsForSelectedItems?.first
            
            self.listsDataSource.applyFreshSnapshot(animating: true) {
                if isSameWindow && payload.selectAndOpenNewList {
                    let snap = self.listsDataSource.snapshot()
                    let listCount = snap.itemIdentifiers.count
                    let idpOfList = IndexPath(item: listCount - 1, section: 0)
                    
                    self.collectionView.selectItem(at: idpOfList,
                                                   animated: payload.animateReload,
                                                   scrollPosition: .top)
                    
                    if let newList = snap.itemIdentifiers.last {
                        self.open(newList)
                    }
                } else {
                    // Retain selection
                    if let selectedIDP = currentSelectedList {
                        self.collectionView.selectItem(at: selectedIDP, animated: false, scrollPosition: .top)
                    }
                }
    
                // Select the row
                self.toggleToolBar()
            }
        }.store(in: &subscriptions)
        
        // Force a header to show when we get our first tax rate
        if NSLocale.isUnitedStates() && ss_defaults().object(forKey: SS_LAST_FETCHED_CITY_TAX_RATE_KEY) == nil {
            var cancellable: AnyCancellable?
            let taxRateRoundNote = Notification.Name(SS_FOUND_TAX_RATE)
            cancellable = nc.publisher(for: taxRateRoundNote)
            .sink(receiveCompletion: {_ in
                cancellable?.cancel()
            }) { [weak self] _ in
                let idp = self?.collectionView.indexPathsForSelectedItems?.first
                self?.collectionView.reloadData()
                if let selectedIDP = idp {
                    self?.collectionView.selectItem(at: selectedIDP, animated: false, scrollPosition: .centeredVertically)
                }
            }
        }
    }
}

// MARK: Controller Specific Functions
@available(iOS 14.0, *)
extension ListsCollectionViewController {
    fileprivate func applyCustomSidebarColors() {
        guard let cv = collectionView, let ssNav = navigationController as? SSNavigationController else { return }
        let compact = isCompactWidth()
        let color = compact ? UIColor.colorMDVCompact : UIColor.colorMDVRegular
        view.backgroundColor = color
        cv.backgroundColor = color
        cv.visibleCells.forEach {
            if let listCell: SSListCollectionViewCell = $0 as? SSListCollectionViewCell {
                listCell.updateColors(compact)
            }
        }
        syncLabel.updateBackgroundColor(color)
        ssNav.configureStyling()
        ssNav.navigationBar.setNeedsLayout()
    }
    
    func listActivity(for list:SSList) -> NSUserActivity {
        let activity = NSUserActivity(activityType: ss_ListActivityOpenWindowType)
        activity.title = ss_ListActivityOpenWindowTypeTitle
        activity.userInfo = [ss_ListActivityOpenWindowTypeListUserInfoKey:list.dbID]
        return activity
    }
    
    fileprivate func listsForSelectedIndexPaths() -> [SSList] {
        let selectedIDPs = self.collectionView.indexPathsForSelectedItems ?? []
        return selectedIDPs.compactMap {
            return self.listsDataSource.itemIdentifier(for: $0)
        }
    }
    
    fileprivate func setupExporter(for lists:[SSList]) {
        let lists: [SSList] = listsForSelectedIndexPaths()
        
        if lists.count == 1 {
            self.exporter = SSListExporter(list: lists.first!)
        } else {
            self.exporter = SSListExporter(lists: lists)
        }
    }
    
    fileprivate func adaptivePresent(_ controller:UIViewController) {
        if UIScreen.isTinyPhone() {
            let nav = SSNavigationController(rootViewController: controller)
            self.present(nav, animated: true)
        } else {
            SSPopupModalPresentationController.presentPresentationController(from: self, presentedController: controller)
        }
    }
    
    fileprivate func createControllerForLoadingHUD() -> UIViewController {
        let hudVC = UIHostingController(rootView: self.loadingHUD)
        hudVC.modalPresentationStyle = .overFullScreen
        hudVC.view.backgroundColor = .clear
        return hudVC
    }
    
    fileprivate func presentWithBlurModalFor(controller:UIViewController) {
        let navVC = SSNavigationController(rootViewController: controller)
        navVC.setHairlineVisibility(false)
        
        if SSCitizenship.allowCustomPresentation() {
            navVC.view.backgroundColor = .clear
            self.navigationController?.definesPresentationContext = true
            navVC.modalPresentationStyle = .custom
            navVC.transitioningDelegate = modalAnimator
        }
        
        navigationController?.present(navVC, animated: true)
    }
    
    fileprivate func isCompactWidth() -> Bool {
        guard let splitVC = splitViewController else { return false }
        return !splitVC.isCollapsed && splitVC.displayMode == .oneBesideSecondary
    }
    
    fileprivate func presentDeleteListConfirmation(for lists:[SSList]) {
        func deleteWithPromptFor(lists: [SSList], skipPrompt:Bool = false) {
            func performDelete(lists: [SSList]) {
                self.lastDeleteList = lists.first!
                self.undoManager.registerUndo(withTarget: self, selector: #selector(self.undoDeleteList), object: nil)
                self.undoManager.setActionName(ss_Localized("general.deleteList"))

                self.listsDataSource.removeLists(lists: lists) { [weak self] in
                    guard let self = self else { return }
                    if self.isEditing {
                        self.setEditing(false, animated: true)
                    }
                    
                    // Let any open list viewing a deleted one know it's been deleted
                    lists.forEach {
                        let payload = ExternalListCRUDPayload(list: $0, listDeleted: true, windowSceneID: self.windowSceneID)
                        payload.send()
                    }
                }
            }
            
            if skipPrompt {
                performDelete(lists: lists)
                return
            }
            
            let isMultiSelection = lists.count > 1
            let title = isMultiSelection ? ss_Localized("general.deleteLists") : ss_Localized("general.deleteList")
            let acDelete = UIAlertAction(title: title, style: .destructive) { handler in
                performDelete(lists: lists)
            }
            
            let acCancel = UIAlertAction(title: ss_Localized("general.cancel"), style: .cancel, handler: nil)
            let message = isMultiSelection ? ss_Localized("general.deleteLists.method") : ss_Localized("general.deleteList.method")
            
            if self.traitCollection.horizontalSizeClass == .compact && !self.isOniPad {
                self.showActionSheet(withTitle: title, message: message, actions: [acDelete, acCancel])
            } else {
                self.showAlert(withTitle: title, message: message, actions: [acDelete, acCancel])
            }
        }
        
        // Check for iCloud share. If they are deleting multiple lists, they're gone.
        if let firstList = lists.first, firstList.listIsShared() {
            let title = ss_Localized("general.deleteList.shared")
            let messageKey = firstList.listIsSharedWithMe() ? "general.deleteList.sharedExp" : "general.deleteList.sharedExp2"
            let messageLocalized = ss_Localized(messageKey)
            
            let confirm = UIAlertAction(title: ss_Localized("general.delete"), style: .destructive) { _ in
                deleteWithPromptFor(lists: lists, skipPrompt: true)
            }
            
            let cancel = UIAlertAction(title: ss_Localized("general.cancel"), style: .cancel) { _ in

            }
            
            showAlert(withTitle: title, message: messageLocalized, actions: [confirm, cancel])
        } else {
            deleteWithPromptFor(lists: lists)
        }
    }
    
    fileprivate func createContextMenu(with list:SSList) -> UIMenu {
        let iCloudEnabled = SSDataStore.sharedInstance().ckManager.accountStatus == .available
        var actions: [UIMenuElement] = []
        
        // Rename
        let acRename = UIAction(title: ss_Localized("ctx.ac.rename"), image: UIImage(systemName: "pencil")) { _ in
            let rename = SSEditNameViewController(list: list)
            self.presentWithBlurModalFor(controller: rename)
        }
        actions.append(acRename)
        
        if list.isShowingCheckboxes {
            // Check All
            let acCheckAll = UIAction(title: ss_Localized("ctx.ac.checkAll"), image: UIImage(systemName: "checkmark.circle")) { _ in
                let items = list.datasourceAdapter.allItems
                items.forEach {
                    $0.checkedOff = true
                }
                Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen { [weak self] in
                    guard let self = self else { return }
                    self.listsDataSource.update(listItems: items, inList: list)
                    UIFeedbackGenerator.playFeedback(of: .success)
                    self.view.window?.showDragThing(withIcon: "checkmark.circle.fill", text: ss_Localized("dragThing.checkedAll"))
                }
            }
            
            // Uncheck All
            let acUncheckAll = UIAction(title: ss_Localized("ctx.ac.uncheckAll"), image: UIImage(systemName: "circle")) { _ in
                let items = list.datasourceAdapter.allItems
                items.forEach {
                    $0.checkedOff = false
                }
                
                Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen { [weak self] in
                    guard let self = self else { return }
                    self.listsDataSource.update(listItems: items, inList: list)
                    UIFeedbackGenerator.playFeedback(of: .success)
                    self.view.window?.showDragThing(withIcon: "circle", text: ss_Localized("dragThing.uncheckedAll"))
                }
            }
            actions.append(contentsOf: [acCheckAll, acUncheckAll])
        }
        
        if iCloudEnabled {
            let text = list.listIsShared() ? "list.vc.collabDetails" : "ctx.ac.invite"
            let icon = list.listIsShared() ? "person.icloud" : "person.crop.circle.badge.plus"
            if let indexPath = self.listsDataSource.indexPath(for: list),
               let sourceItemView = self.collectionView.cellForItem(at: indexPath) {
                // Sharing
                let acShare = UIAction(title: ss_Localized(text), image: UIImage(systemName: icon)) { handler in
                    let dispatchtime = Double(SSUIKitTableViewBatchAnimationDuration)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + dispatchtime) { [weak self] in
                        guard let self = self else { return }
                        SSDataStore.sharedInstance().presentSharing(self,
                                                                    for: list.deepCopy(),
                                                                    anchorBarItem: nil,
                                                                    sourceView: sourceItemView)
                        
                    }
                }
                actions.append(acShare)
            }
        }
        
        // Exports
        let imgText = UIImage(systemName: "doc.text")
        let acText = UIAction(title: ss_Localized("general.text"), image: imgText) { handler in
            self.setupExporter(for: self.listsForSelectedIndexPaths())
            let textForLists = self.exporter.textRepresentationForLists()
            let activityItemVC = UIActivityViewController(activityItems: [textForLists as Any], applicationActivities: nil)
            self.setEditing(false, animated: true)
            self.present(activityItemVC, animated: true)
        }
        
        let imgRichText = UIImage(systemName: "doc.richtext")
        let acPDF = UIAction(title: ss_Localized("general.pdf"), image: imgRichText) { handler in
            self.setupExporter(for: self.listsForSelectedIndexPaths())
            let textForLists = self.exporter.pdfRepresentationForLists()
            let activityItemVC = UIActivityViewController(activityItems: [textForLists as Any], applicationActivities: nil)
            self.setEditing(false, animated: true)
            self.present(activityItemVC, animated: true)
        }
        
        let exportMenu = UIMenu(title: ss_Localized("ctx.ac.export.trailing"), children: [acText, acPDF])
        
        // Print
        let imgPrint = UIImage(systemName: "printer")
        let acPrint = UIAction(title: ss_Localized("general.print"), image: imgPrint) { handler in
            guard UIPrintInteractionController.isPrintingAvailable else {
                self.showAlert(withTitle: ss_Localized("general.print.no"), message: ss_Localized("general.print.no2"))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else { return }
                self.setupExporter(for: self.listsForSelectedIndexPaths())
                let printer = self.exporter.printControllerForLists()
                self.setEditing(false, animated: true)
                printer?.present(animated: true) { printer, completed, error in
                    
                }
            }
        }
        
        let acDupe = UIAction(title: ss_Localized("ctx.ac.duplicate"), image: UIImage(systemName: "plus.square.on.square")) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(SSUIKitTableViewBatchAnimationDuration)) { [weak self] in
                guard let self = self else { return }
                self.loadingHUD = LoadingHUDView(loadingHudText: ss_Localized("hud.duping"))
                let hudVC = self.createControllerForLoadingHUD()
                
                self.present(hudVC, animated: false) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        guard let self = self else { return }
                        self.listsDataSource.store.duplicate(list: list) { dupedList in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                hudVC.dismiss(animated: false)
                                if self.isEditing {
                                    self.setEditing(false, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        actions.append(acDupe)
        
        var acNewWindow: UIAction? = nil
        if isOniPad {
            acNewWindow = UIAction(title: ss_Localized("ctx.ac.newWindow"), image: UIImage(systemName: "square.split.2x1")) { _ in
                Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen { [weak self] in
                    guard let self = self else { return }
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: self.listActivity(for: list), options: nil, errorHandler: nil)
                }
            }
        }
        
        let menu = UIMenu(title: "", options: .displayInline, children: [exportMenu, acPrint, acDupe, acNewWindow].compactMap{ $0 })
        actions.append(menu)
        
        let acRemoveAllItems = UIAction(title: ss_Localized("ctx.ac.removeAllItems"), image: UIImage(systemName: "minus.circle")) { _ in
            let acConfirmRemove = UIAlertAction(title: ss_Localized("general.deleteListItems.yesConfirm"), style: .destructive) { _ in
                self.listsDataSource.removeAllItems(from: list)
                UIFeedbackGenerator.playFeedback(of: .success)
                self.view.window?.showDragThing(withIcon: "trash.circle.fill", text: ss_Localized("dragThing.deletedAll"))
            }
            
            let acCancel = UIAlertAction(title: ss_Localized("general.cancel"), style: .cancel, handler: nil)
            
            Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen {
                if self.traitCollection.horizontalSizeClass == .compact && !self.isOniPad {
                    self.showActionSheet(withTitle: "", message: ss_Localized("list.vc.clear1"), actions:[acConfirmRemove, acCancel])
                } else {
                    self.showAlert(withTitle: ss_Localized("list.vc.clear"), message: ss_Localized("list.vc.clear1"), actions:[acConfirmRemove, acCancel])
                }
            }
        }
        acRemoveAllItems.attributes = .destructive
        
        let acDelete = UIAction(title: ss_Localized("general.delete"), image:UIImage(systemName: "trash")) { _ in
            Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen { [weak self] in
                self?.presentDeleteListConfirmation(for: [list])
            }
        }
        acDelete.attributes = .destructive
        
        let deleteMenu = UIMenu(title: "", options: .displayInline, children: [acRemoveAllItems, acDelete])
        actions.append(deleteMenu)
        
        return UIMenu(title: "", children: actions)
    }
    
    fileprivate func open(_ list:SSList) {
        listsDataSource.store.fetch(list: list.dbID) { hydratedList in
            guard let selectedList = hydratedList else { return }

            var detailNavVC: SSNavigationController? = splitViewController?.viewControllers.last as? SSNavigationController
            var listVC: ListViewController! = detailNavVC?.topViewController as? ListViewController
                
            // On iPhone, it could be nil due to the delegate handling
            if listVC == nil {
                listVC = ListViewController(with: selectedList)
                detailNavVC = SSNavigationController(rootViewController: listVC)
            } else {
                listVC.toggleUI(for: selectedList)
            }
            
            listVC.navigationItem.leftItemsSupplementBackButton = true
            listVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            
            quickActionHandler?.addDynamicQuickActionForList(selectedList)
            splitViewController?.showDetailViewController(detailNavVC!, sender: self)
        }
    }
}

// MARK: UIApplicationShortCutItem Handling
@available(iOS 14.0, *)
extension ListsCollectionViewController {
    fileprivate func processApplicationShortcutAction(_ shortCutAction:IncomingShortcutItem) {
        switch shortCutAction {
        case .CreateAction:
            presentWithBlurModalFor(controller: SSAddListViewController())
        case .SearchAction:
            searchController.searchBar.becomeFirstResponder()
        case .ExportAction:
            setEditing(true, animated: true)
        case .OpenList(_, let info):
            if let listID = info?[IncomingShortcutItem.UserInfoListIDKey] as? String,
               let list = listsDataSource.snapshot().itemIdentifiers.first(where: { $0.dbID == listID }) {
                open(list)
            }
        }
    }
}

// MARK: Collection View Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isEditing else {
            toolBar.disableBarItems(atIndicies: [])
            return
        }
        
        guard let list = listsDataSource.itemIdentifier(for: indexPath) else { return }
        open(list)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (suggestions:[UIMenuElement]) -> UIMenu? in
            guard let self = self else { return nil }
            guard let list = self.listsDataSource.itemIdentifier(for: indexPath) else { return nil }
            return self.createContextMenu(with: list)
        }
    }
}

// MARK: Drag Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let list = listsDataSource.itemIdentifier(for: indexPath) else { return [] }
        return dragItemsFor(list: list, at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let list = listsDataSource.itemIdentifier(for: indexPath) else { return [] }
        return dragItemsFor(list: list, at: indexPath, registerActivity: false)
    }
    
    private func dragItemsFor(list:SSList, at indexPath:IndexPath, registerActivity:Bool = true) -> [UIDragItem] {
        let listTVC = listsDataSource.collectionView(collectionView, cellForItemAt: indexPath) as! SSListCollectionViewCell
        let provider = NSItemProvider(object: "" as NSString)
        
        if let list = listsDataSource.itemIdentifier(for: indexPath) {
            if registerActivity {
                provider.registerObject(listActivity(for: list), visibility: .all)
            }
            
            let drugList = UIDragItem(itemProvider: provider)
            drugList.previewProvider = {
                return listTVC.dragPreviewRepresentation()
            }
            
            return [drugList]
        } else {
            return []
        }
    }
}

// MARK: Drop Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: UIDropSession) {
        // Check if we're dropping in some other content from Spend Stack
        for dragItem in session.localDragSession?.items ?? [] {
            if let listItemDrag = dragItem.localObject as? SSListItemDragData {
                session.localDragSession?.localContext = listItemDrag
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let localSession = session.localDragSession else { return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified) }
        
        var dropOp: UIDropOperation = .move
        var intent: UICollectionViewDropProposal.Intent = .insertAtDestinationIndexPath
        
        // Is this a list item?
        if localSession.localContext is SSListItemDragData {
            dropOp = .copy
            intent = .insertIntoDestinationIndexPath
            
            // Highlight the cell we're dragging over
            if let idp = destinationIndexPath {
                collectionView.indexPathsForVisibleItems.forEach {
                    let cell = listsDataSource.collectionView(collectionView, cellForItemAt: $0)
                    cell.isSelected = $0 == idp
                }
            }
        }
        
        return UICollectionViewDropProposal(operation: dropOp, intent: intent)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        //listsDataSource.updateSortOrder()
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // Since we only support dropping into existing rows, make sure the destinationIndexPath is valid.
        guard let idp = coordinator.destinationIndexPath, idp.item < listsDataSource.snapshot().itemIdentifiers.count else { return }
        
        let lists = listsDataSource.snapshot().itemIdentifiers
        
        if let dragData = coordinator.session.localDragSession?.localContext as? SSListItemDragData {
            let cell = listsDataSource.collectionView(collectionView, cellForItemAt: idp)
            let fromList = dragData.list
            let toList = lists[idp.item]
            let fromListIDX = lists.firstIndex(where: { $0.dbID == fromList.dbID })
            
            if let fromIDX = fromListIDX, idp.item != fromIDX {
                listsDataSource.store.moveItems(dragData.listItems as! [SSListItem], from: fromList, to: toList, listTagID: nil) { [weak self] (listItems, updatedFrom, updatedTo, db) in
                    
                    let dropRect = CGRect(x: SSSpacingMargin, y: cell.contentView.center.y, width: 1, height: 1)
                    for drop in coordinator.items {
                        coordinator.drop(drop.dragItem, intoItemAt: idp, rect: dropRect)
                    }
                    cell.bobbleBigToSmall()
                    UIFeedbackGenerator.playFeedback(of: .success)
                    
                    let dragText = ss_Localized("dragThing.moved")
                    let localized = String.localizedStringWithFormat(dragText, String(listItems.count), (listItems.count > 1 ? "items" : "item"), toList.name)
                    self?.view.window?.showDragThing(withIcon: "folder.fill", text: localized)
                }
            }
        }
    }
}

// MARK: Tags Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController: SSTagsViewControllerDelegate {
    func onTagSelectionChanged(_ tag: SSTagSelectionViewModel?, controller: SSTagsViewController) {
        // do.nothing()
    }
    
    func controllerShouldPushTagsManagerWhenPresenting() -> Bool {
        return true
    }
}

// MARK: UISearchController Delegate
@available(iOS 14.0, *)
extension ListsCollectionViewController: UISearchControllerDelegate {
    
}

// MARK: Undo and Redo
@available(iOS 14.0, *)
extension ListsCollectionViewController {
    
    @objc func redoDeleteList(_ list:SSList) {
        lastDeleteList = list
        undoManager.registerUndo(withTarget: self, selector: #selector(undoDeleteList), object: nil)
        undoManager.setActionName(ss_Localized("general.deleteList"))
        
        listsDataSource.removeLists(lists: [list])
    }
    
    @objc func undoDeleteList() {
        guard let list = lastDeleteList else { return }
        undoManager.registerUndo(withTarget: self, selector: #selector(redoDeleteList(_:)), object: list)
        undoManager.setActionName(ss_Localized("general.deleteList"))
        
        // Put the list back
        listsDataSource.store.restore(list: list) { [weak self] _ in
            UIFeedbackGenerator.playFeedback(of: .success)
            self?.view.window?.showDragThing(withIcon: "checkmark.circle.fill", text: "List Restored")
        }
    }
}
