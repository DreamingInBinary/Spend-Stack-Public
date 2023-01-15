//
//  ListsViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 6/19/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import Combine
import SnapKit
import SwiftUI

class ListsViewController: SSBaseViewController {    
    // MARK: Private properties
    private var tableView: UITableView! = nil
    private var listsDataSource: ListsTableViewDataSource! = nil
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
    private lazy var mapView: SSMapInfoHeaderView? = {
        guard NSLocale.isUnitedStates() else { return nil }
        let mapView = SSMapInfoHeaderView(frame: CGRect(x: 0, y: 0, width: view.boundsWidth, height: 1))
        mapView.updateTaxRateForLocation()
        return mapView
    }()
    
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
        deselectTableRow(tableView)
        mapView?.updateSize(with: tableView)
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
        tableView.setEditing(editing, animated: animated)
        toggleToolBar()
    }
}

// MARK: View Setup
extension ListsViewController {
    private func configureHierarchy() {
        definesPresentationContext = true
        setupNavBar()
        setupSearchBar()
        setupTableView()
        setupDataSource()
        setupToolBar()
        setConstraints()
    }

    private func setupNavBar() {
        title = ss_Localized("general.lists")
        
        var moreBarButton: UIBarButtonItem!
        let btnImg = UIImage(systemName: "ellipsis.circle")
        
        if #available(iOS 14.0, *) {
            let moreAction = UIAction(title: "") { handler in
                self.showHelpController()
            }
            
            moreBarButton = UIBarButtonItem(image: btnImg, primaryAction: moreAction)
        } else {
            moreBarButton = UIBarButtonItem(image: btnImg, style: .plain, target: self, action: #selector(showHelpController))
        }
        
        moreBarButton.title = ss_Localized("general.settings")
        moreBarButton.largeContentSizeImage = UIImage(systemName: "ellipsis.circle")?.imageScaled(to: CGSize(width: 80, height: 80))
        moreBarButton.landscapeImagePhone = UIImage(systemName: "ellipsis.circle")?.imageScaled(to: CGSize(width: 20, height: 20))
        navigationItem.rightBarButtonItem = moreBarButton
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @objc private func showHelpController() {
        let showMore = SSHelpAndMoreViewController()
        self.adaptivePresent(showMore)
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
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .grouped)
        view.addSubview(tableView)
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.delegate = self
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.separatorStyle = .none
        tableView.tableHeaderView = NSLocale.isUnitedStates() ? mapView : nil
        tableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 14.0, *) {
            tableView.selectionFollowsFocus = true
        }
    }
    
    private func setupDataSource() {
        tableView.register(SSListTableViewCell.self, forCellReuseIdentifier: VIEW_LISTS_VC_CELL_ID)
        listsDataSource = ListsTableViewDataSource(tableView: tableView) { [weak self] (tableView, indexPath, identifier) -> UITableViewCell? in
            if let cell = tableView.dequeueReusableCell(withIdentifier: VIEW_LISTS_VC_CELL_ID, for: indexPath) as? SSListTableViewCell {
                cell.setData(identifier)
                cell.updateColors(self?.isCompactWidth() ?? false)
                return cell
            } else {
                return nil
            }
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
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(toolBar.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
        }
    }
}

// MARK: Toolbar Functions

extension ListsViewController {
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
            guard let self = self, let selections = self.tableView.indexPathsForSelectedRows else { return }
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
            if #available(iOS 14.0, *) {
                customEdit?.primaryAction = UIAction(title: ss_Localized("barItem.edit"), image: UIImage(systemName:"pencil.circle")) { handler in
                    self.manuallySetToEditing()
                }
            } else {
                customEdit?.target = self
                customEdit?.action = #selector(manuallySetToEditing)
            }
            navigationItem.leftBarButtonItem = customEdit
        }
        
        let disableExportAndDelete = tableView.isEditing && !snap.itemIdentifiers.isEmpty
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
        
        if #available(iOS 14.0, *) {
            if let tbExport = toolBar.item(fromType: SSToolBarItemTypeExport) {
                tbExport.target = nil
                tbExport.action = nil
                tbExport.menu = toolbarOnExport()
                tbExport.isEnabled = !disableExportAndDelete
                toolBar.replaceToolBarItem(forType: SSToolBarItemTypeExport, with: tbExport)
            }
        } else {
            toolBar.onExport = { [weak self] in
                let actionText = UIAlertAction(title: ss_Localized("general.text"), style: .default) { handler in
                    guard let self = self else { return }
                    self.setupExporter(for: self.listsForSelectedIndexPaths())
                    let textForLists = self.exporter.textRepresentationForLists()
                    let activityItemVC = UIActivityViewController(activityItems: [textForLists as Any], applicationActivities: nil)
                    self.setEditing(false, animated: true)
                    self.present(activityItemVC, animated: true)
                }
                
                let actionPDF = UIAlertAction(title: ss_Localized("general.pdf"), style: .default) { handler in
                    guard let self = self else { return }
                    self.setupExporter(for: self.listsForSelectedIndexPaths())
                    let textForLists = self.exporter.pdfRepresentationForLists()
                    let activityItemVC = UIActivityViewController(activityItems: [textForLists as Any], applicationActivities: nil)
                    self.setEditing(false, animated: true)
                    self.present(activityItemVC, animated: true)
                }
                
                let actionPrint = UIAlertAction(title: ss_Localized("general.print"), style: .default) { handler in
                    guard UIPrintInteractionController.isPrintingAvailable else {
                        self?.showAlert(withTitle: ss_Localized("general.print.no"), message: ss_Localized("general.print.no2"))
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
                
                let cancel = UIAlertAction(title: ss_Localized("cancel"), style: .cancel, handler: nil)
                
                self?.showActionSheet(withTitle: nil, message: nil, actions: [actionText, actionPDF, actionPrint, cancel])
            }
        }
        
        toolBar.onDelete = toolbarOnDelete()
        
        if #available(iOS 14.0, *) {
            if let tbSort = toolBar.item(fromType: SSToolBarItemTypeSort) {
                tbSort.target = nil
                tbSort.action = nil
                tbSort.menu = toolbarOnSort()
                toolBar.replaceToolBarItem(forType: SSToolBarItemTypeSort, with: tbSort)
            }
        } else {
            toolBar.onSort = { [weak self] in
                let acSortAlphabetically = UIAlertAction(title: ss_Localized("general.alphabetically"), style:.default) { handler in
                    self?.listsDataSource.applySortOption(.alphabetically)
                }
                
                let acSortNewest = UIAlertAction(title: ss_Localized("general.newest"), style:.default) { handler in
                    self?.listsDataSource.applySortOption(.newest)
                }
                
                let acSortOldest = UIAlertAction(title: ss_Localized("general.oldest"), style:.default) { handler in
                    self?.listsDataSource.applySortOption(.oldest)
                }
                
                let cancel = UIAlertAction(title: ss_Localized("cancel"), style: .cancel, handler: nil)
                
                self?.showActionSheet(withTitle: nil, message: nil, actions: [acSortAlphabetically, acSortNewest, acSortOldest, cancel])
            }
        }
        
        toolBar.onBasicAdd = { [weak self] in
            self?.presentWithBlurModalFor(controller: SSAddListViewController())
        }
    }
    
    @objc private func manuallySetToEditing() {
        self.setEditing(true, animated: true)
    }
}

// MARK: Search Result Delegate
extension ListsViewController : SSQuickFindViewControllerDelegate {
    func ss_searchTermWasTapped(_ result: SSQuickFindResult) {
        switch result.type {
        case .list:
            if let matchedList = listsDataSource.snapshot().itemIdentifiers.first(where: { $0.dbID == result.objectID }) {
                open(matchedList)
            }
        case .listItem:
            open(listItem: result.objectID)
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
extension ListsViewController : SSTagsManagerViewControllerDelegate {
    // do.nothing()
}

// MARK: List Item Controller Delegate
extension ListsViewController : SSListItemViewControllerDelegate {
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
extension ListsViewController {
    private func setupCombineSubs() {
        let nc = NotificationCenter.default
        
        // Shortcut actions
        nc.publisher(for: .handleShortcutAction)
        .compactMap{ $0.object as? IncomingShortcutItem }
        .receive(on: RunLoop.main)
        .sink { [weak self] shortcutItem in
            guard let self = self else { return }
            self.processApplicationShortcutAction(shortcutItem)
        }.store(in: &subscriptions)
        
        // Open this list from a widget tap
        nc.publisher(for: .openListFromWidgetTap)
        .compactMap{ $0.object as? String }
        .receive(on: RunLoop.main)
        .sink { [weak self] listID in
            guard let self = self else { return }
            guard let listToOpen = self.listsDataSource.snapshot().itemIdentifiers.first(where: { $0.dbID == listID}) else { return }
            self.open(listToOpen)
        }.store(in: &subscriptions)
        
        // Accepted CloudKit Share. Scroll to the list and highlight it
        let shareNote = Notification.Name(rawValue: SS_CK_MANAGER_ACCEPTED_SHARE)
        nc.publisher(for: shareNote)
        .compactMap { $0.object as? String }
        .receive(on: RunLoop.main)
        .sink { [weak self] listID in
            guard let self = self else { return }
            guard let acceptedSharedList = self.listsDataSource.snapshot().itemIdentifiers.first(where: { $0.dbID == listID}), let idp = self.listsDataSource.indexPath(for: acceptedSharedList) else { return }

            self.tableView.scrollToRow(at: idp, at: .bottom, animated: true)
            0.5.secondDelayThen {
                self.tableView.cellForRow(at: idp)?.animateHighlightCallout()
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
            let currentSelectedList = self.tableView.indexPathsForSelectedRows?.first
            
            self.listsDataSource.applyFreshSnapshot(animating: true) {
                let isSameWindow = self.windowSceneID == payload.windowSceneID
                if isSameWindow && payload.selectAndOpenNewList {
                    let snap = self.listsDataSource.snapshot()
                    let listCount = snap.itemIdentifiers.count
                    let idpOfList = IndexPath(item: listCount - 1, section: 0)
                    
                    self.tableView.selectRow(at: idpOfList,
                                             animated: payload.animateReload,
                                             scrollPosition: .top)
                    
                    if let newList = snap.itemIdentifiers.last {
                        self.open(newList)
                    }
                } else {
                    // Retain selection
                    if let selectedIDP = currentSelectedList {
                        self.tableView.selectRow(at: selectedIDP, animated: false, scrollPosition: .top)
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
                let idp = self?.tableView.indexPathsForSelectedRows?.first
                self?.tableView.reloadData()
                if let selectedIDP = idp {
                    self?.tableView.selectRow(at: selectedIDP, animated: false, scrollPosition: .top)
                }
            }
        }
    }
}

// MARK: Controller Specific Functions

extension ListsViewController {
    fileprivate func applyCustomSidebarColors() {
        guard let cv = tableView, let ssNav = navigationController as? SSNavigationController else { return }
        let compact = isCompactWidth()
        let color = compact ? UIColor.colorMDVCompact : UIColor.colorMDVRegular
        view.backgroundColor = color
        cv.backgroundColor = color
        cv.visibleCells.forEach {
            if let listCell: SSListTableViewCell = $0 as? SSListTableViewCell {
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
        let selectedIDPs = self.tableView.indexPathsForSelectedRows ?? []
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
               let sourceItemView = self.tableView.cellForRow(at: indexPath) {
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
            
            if let listSceneDelegate = view.window?.windowScene?.delegate as? ListsSceneDelegate {
                listSceneDelegate.quickActionHandler.addDynamicQuickActionForList(selectedList)
            }
            
           // quickActionHandler?.addDynamicQuickActionForList(selectedList)
            splitViewController?.showDetailViewController(detailNavVC!, sender: self)
        }
    }
    
    func open(listItem listItemID:String) {
        listsDataSource.store.fetch(listItem: listItemID) { listItem in
            guard let item = listItem else { return }
            let listItemVC = SSListItemViewController(listItem: item, delegate: self)
            let navVC = SSModalCardNavigationController(rootViewController: listItemVC)
            present(navVC, animated: true)
        }
    }
}

// MARK: UIApplicationShortCutItem Handling

extension ListsViewController {
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

// MARK: Table View Delegate

extension ListsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isEditing else {
            toolBar.disableBarItems(atIndicies: [])
            return
        }
        
        guard let list = listsDataSource.itemIdentifier(for: indexPath) else { return }
        open(list)
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] (suggestions:[UIMenuElement]) -> UIMenu? in
            guard let self = self else { return nil }
            guard let list = self.listsDataSource.itemIdentifier(for: indexPath) else { return nil }
            return self.createContextMenu(with: list)
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let list = self.listsDataSource.itemIdentifier(for: indexPath) else { return nil }
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
}

// MARK: Drag Delegate

extension ListsViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let list = listsDataSource.itemIdentifier(for: indexPath) else { return [] }
        return dragItemsFor(list: list, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let list = listsDataSource.itemIdentifier(for: indexPath) else { return [] }
        return dragItemsFor(list: list, at: indexPath, registerActivity: false)
    }
    
    private func dragItemsFor(list:SSList, at indexPath:IndexPath, registerActivity:Bool = true) -> [UIDragItem] {
        let listTVC = listsDataSource.tableView(tableView, cellForRowAt: indexPath) as! SSListTableViewCell
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

extension ListsViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // Since we only support dropping into existing rows, make sure the destinationIndexPath is valid.
        guard let idp = coordinator.destinationIndexPath, idp.item < listsDataSource.snapshot().itemIdentifiers.count else { return }
        
        let lists = listsDataSource.snapshot().itemIdentifiers
        
        if let dragData = coordinator.session.localDragSession?.localContext as? SSListItemDragData {
            let cell = listsDataSource.tableView(tableView, cellForRowAt: idp)
            let fromList = dragData.list
            let toList = lists[idp.item]
            let fromListIDX = lists.firstIndex(where: { $0.dbID == fromList.dbID })
            
            if let fromIDX = fromListIDX, idp.item != fromIDX {
                listsDataSource.store.moveItems(dragData.listItems as! [SSListItem], from: fromList, to: toList, listTagID: nil) { [weak self] (listItems, updatedFrom, updatedTo, db) in
                    
                    let dropRect = CGRect(x: SSSpacingMargin, y: cell.contentView.center.y, width: 1, height: 1)
                    for drop in coordinator.items {
                        coordinator.drop(drop.dragItem, intoRowAt: idp, rect: dropRect)
                    }
                    
                    Double(SSUIKitTableViewBatchAnimationDuration).secondDelayThen {
                        if let cell = tableView.cellForRow(at: idp) {
                            cell.bobbleBigToSmall()
                            UIFeedbackGenerator.playFeedback(of: .success)
                        }
                    }
                    
                    let dragText = ss_Localized("dragThing.moved")
                    let localized = String.localizedStringWithFormat(dragText, String(listItems.count), (listItems.count > 1 ? "items" : "item"), toList.name)
                    self?.view.window?.showDragThing(withIcon: "folder.fill", text: localized)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        // Check if we're dropping in some other content from Spend Stack
        for dragItem in session.localDragSession?.items ?? [] {
            if let listItemDrag = dragItem.localObject as? SSListItemDragData {
                listItemDrag.indexPathToReselect = tableView.indexPathForSelectedRow
                session.localDragSession?.localContext = listItemDrag
                break
            }
        }
    }
        
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let localSession = session.localDragSession else { return UITableViewDropProposal(operation: .cancel, intent: .unspecified) }
        
        var dropOp: UIDropOperation = .move
        var intent: UITableViewDropProposal.Intent = .insertAtDestinationIndexPath
        
        // Is this a list item?
        if localSession.localContext is SSListItemDragData {
            dropOp = .copy
            intent = .insertIntoDestinationIndexPath
            
            tableView.indexPathsForVisibleRows?.forEach {
                if let cell = tableView.cellForRow(at: $0) {
                    if cell.isSelected && $0 != destinationIndexPath {
                        cell.setSelected(false, animated: true)
                    } else if !cell.isSelected && $0 == destinationIndexPath {
                        cell.setSelected(true, animated: true)
                    }
                }
            }
        }
        
        return UITableViewDropProposal(operation: dropOp, intent: intent)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        listsDataSource.saveNewOrder(from: listsDataSource.snapshot())
        
        if let localSession = session.localDragSession?.localContext as? SSListItemDragData,
           let ogSelectedIDP = localSession.indexPathToReselect {
            tableView.selectRow(at: ogSelectedIDP, animated: true, scrollPosition: .middle)
        }
    }
}

// MARK: Tags Delegate

extension ListsViewController: SSTagsViewControllerDelegate {
    func onTagSelectionChanged(_ tag: SSTagSelectionViewModel?, controller: SSTagsViewController) {
        // do.nothing()
    }
    
    func controllerShouldPushTagsManagerWhenPresenting() -> Bool {
        return true
    }
}

// MARK: UISearchController Delegate

extension ListsViewController: UISearchControllerDelegate {
    
}

// MARK: Undo and Redo
extension ListsViewController {
    
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
