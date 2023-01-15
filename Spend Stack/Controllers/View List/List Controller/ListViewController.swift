//
//  ListViewController.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/6/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import Combine

@objc class ListViewController: SSBaseViewController {
    // MARK: Private Properties
    
    private static let sectionHeaderElementKind = "section-header-element-kind"
    private static let sectionFooterElementKind = "section-footer-element-kind"
    private var quickAddView:SSQuickAddView! = nil
    private lazy var headerView:SSListTotalHeaderView = {
        let header = SSListTotalHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        if let currentList = list {
            header.updateUI(for: currentList)
        }
        return header
    }()
    private var noListDimmingView:UIView?
    private var lockView:SSLockView?
    
    // MARK: Public properties
    
    let modalAnimator = SSBlurModalAnimator()
    var taxUtil:TaxUtility = TaxUtility(localeID: nil)
    var tableView:UITableView! = nil
    var listItemToEdit:SSListItem?
    var toolBar:SSToolbar = SSToolbar(itemTypes: [])
    var dataSource:ListDataSource! = nil
    var exporter:SSListExporter! = nil
    var subscriptions:[AnyCancellable] = []
    @objc var list:SSList?
    
    // MARK: Initializers/View Lifecycle
    
    @objc init(with list:SSList?) {
        super.init(nibName: nil, bundle: nil)
        self.doesPreferCustomBroadcastContentSize = true
        self.list = list
        self.exporter = SSListExporter(list: list)
        self.title = list?.name
        self.navigationItem.largeTitleDisplayMode = .never
        self.toggleNavBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        quickAddView = SSQuickAddView(list: list)
        
        toolBar = createToolBar()
    
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.backgroundColor = UIColor.systemBackground
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.tableHeaderView = headerView
        if #available(iOS 14.0, *) {
            tableView.selectionFollowsFocus = true
        }
        
        // Cells
        tableView.register(SSListItemBasicTableViewCell.self, forCellReuseIdentifier: SS_LIST_ITEM_BASIC_CELL_ID)
        tableView.register(SSListItemLeadingExtraDetailsTableViewCell.self, forCellReuseIdentifier: SS_LIST_ITEM_LEADING_EXTRA_DETAILS_CELL_ID)
        tableView.register(SSListItemTrailingExtraDetailsTableViewCell.self, forCellReuseIdentifier: SS_LIST_ITEM_TRAILING_EXTRA_DETAILS_CELL_ID)
        tableView.register(SSListItemExtraDetailsTableViewCell.self, forCellReuseIdentifier: SS_LIST_ITEM_EXTRA_DETAILS_CELL_ID)
        tableView.register(SSListSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SS_LIST_SECTION_HEADER_ID)
        tableView.register(SSListSectionFooterView.self, forHeaderFooterViewReuseIdentifier: SS_LIST_SECTION_FOOTER_ID)

        view.addSubviews([tableView, toolBar, quickAddView])
        
        setConstraints()
        
        if let ssNav = navigationController as? SSNavigationController {
            ssNav.addTappableNavbarLabel(self) { [weak self] in
                guard let currentList = self?.list else { return }
                self?.presentNameOrTitleEdit(list: currentList, listItem: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toggleUI(for: list)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createSubscriptions()
        nudgeOver(.discoveredContextMenus)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        headerView.list = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.isDifferentThanTraitCollection(previousTraitCollection) {
            let note = Notification.Name(SS_TRAIT_COLLECTION_CHANGED)
            NotificationCenter.default.post(name: note, object: nil)
        }
    }
    
    deinit {
        unsubscribeSubscriptions()
    }

    // MARK: Layout and Constraints
    
    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(toolBar.snp.top)
        }
        
        toolBar.snp.makeConstraints { make in
            make.width.equalTo(view.snp.width)
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        quickAddView.snp.makeConstraints { make in
            make.width.equalTo(view.snp.width).multipliedBy(0.92)
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(view.snp.bottom).offset(100)
            make.height.equalTo(quickAddView.snp.height)
        }
    }
    
    // MARK: List Toggling
    
    @objc func toggleUI(for list:SSList?) {
        self.list = list
        
        if let newList = list {
            updateListUserActivity()
            updateNavBarTitle()
            taxUtil = TaxUtility(localeID: newList.currencyIdentifier)
            dataSource = nil
            configureDataSource()
            quickAddView.toggle(newList)
            
            headerView.updateUI(for: newList)
            headerView.updateSize(with: self.tableView)
            
            UIView.animate(withDuration: TimeInterval(SSFastAnimationDuration), animations:{
                self.noListDimmingView?.alpha = 0
            }) { done in
                self.noListDimmingView?.removeFromSuperview()
                self.noListDimmingView = nil
            }
            
            navigationController?.navigationBar.layer.zPosition = 0
            
            let allItems = newList.datasourceAdapter.allItems
            let allTags = newList.datasourceAdapter.sortedTags
            let snap = dataSource.newSnapShotFrom(listTags: allTags, allItems: allItems)
            dataSource.apply(snap, animatingDifferences: false) { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.toggleNavBar()
                weakSelf.toggleToolBar(with: weakSelf.toolBar)
                weakSelf.dataSource.showEmptyViewIfNeeded(delay: false)
            }
            
            if newList.isLocked {
                guard lockView?.superview == nil else { return }
                lockView = SSLockView(containing: self)
                view.addSubview(lockView!)
                lockView!.snp.makeConstraints { make in
                    make.edges.equalTo(view)
                }
                
                func toggleRightBarItems(on:Bool) {
                    navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = on }
                }
                
                toggleRightBarItems(on: false)
                lockView?.onDismiss = { [weak self] in
                    toggleRightBarItems(on: true)
                    self?.lockView?.removeFromSuperview()
                }
            } else {
                lockView?.removeFromSuperview()
                lockView = nil
            }
        } else {
            navigationController?.navigationBar.layer.zPosition = -1
            if noListDimmingView?.superview == nil {
                noListDimmingView = UIView(frame: view.frame)
                noListDimmingView?.backgroundColor = .systemBackground
                noListDimmingView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(noListDimmingView!)
            }
        }
        
        toggleToolBar(with: self.toolBar)
    }
    
    // MARK: Datasoure
    
    func configureDataSource() {
        guard let currentList = list else { return }
        
        dataSource = ListDataSource(tableView: tableView) { [weak self]
            (tableView: UITableView, indexPath: IndexPath, identifier: SSListItem) -> UITableViewCell? in

            guard let currentList = self?.list else { return nil }
            let taxInfo = currentList.taxInfo
            let cellID:String
            
            if identifier.itemHasNoExtraDetails(taxInfo) {
                cellID = SS_LIST_ITEM_BASIC_CELL_ID
            } else if identifier.itemHasOnlyLeadingExtraDetails(taxInfo) {
                cellID = SS_LIST_ITEM_LEADING_EXTRA_DETAILS_CELL_ID
            } else if identifier.itemHasOnlyTrailingExtraDetails(taxInfo) {
                cellID = SS_LIST_ITEM_TRAILING_EXTRA_DETAILS_CELL_ID
            } else if identifier.itemHasAllExtraDetails(taxInfo) {
                cellID = SS_LIST_ITEM_EXTRA_DETAILS_CELL_ID
            } else {
                cellID = ""
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! SSListItemBasicTableViewCell
            cell.setData(identifier, taxInfo: taxInfo, with: currentList)
            cell.onCheckToggled = { [weak self] listItemID, checked in
                if let li = self?.dataSource.snapshot().itemIdentifiers.first(where:{ $0.dbID == listItemID}) {
                    li.checkedOff.toggle()
                    self?.update(listItems: [li])
                }
            }
            
            return cell
        }
        
        dataSource.list = currentList
        dataSource.emptyView = SSEmptyStateView(stateText: ss_Localized("list.vc.empty"))
        dataSource.emptyViewConstraints = { [weak self] make in
            guard let weakSelf = self else { return }
            let lg = weakSelf.view.safeAreaLayoutGuide
            make.top.equalTo(lg.snp.top)
            make.bottom.equalTo(weakSelf.toolBar.snp.top)
            make.centerX.equalTo(lg.snp.centerX)
            make.width.equalTo(lg.snp.width)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        toggleToolBar(with: toolBar)
        toggleNavBar()
        let noteName = Notification.Name.init(SS_PARENT_TABLE_VIEW_IS_EDIT_MODE_CHANGED)
        NotificationCenter.default.post(name: noteName, object: nil)
    }
}

// MARK: Ex: Item Entry

extension ListViewController {

    func presentItemAdd() {
        let tb = SSToolbar(itemTypes: [])
        tb.clipsToBounds = true
        
        tb.onAddItem = { [unowned self] in
            guard let currentList = self.list else { return }
            
            let item = SSListItem(parentListRecordID: currentList.objCKRecord.recordID)
            let data:[AnyHashable:Any] = self.quickAddView.itemDataFromInput()
            item.title = data[ITEM_TITLE_KEY] as? String ?? ss_Localized("general.untitled")
            item.title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            item.baseAmount = data[ITEM_AMOUNT_KEY] as? NSDecimalNumber ?? NSDecimalNumber(decimal: 0.0)
            item.hasTaxApplied = currentList.taxInfo.taxIsEnabled
            item.fkListID = currentList.dbID
            
            func saveAndScroll() {
                self.save(item: item)
                self.quickAddView.clearoutUIForMoreInput()
                self.scrollTo(item: item)
            }
            
            if let tagVM = data[ITEM_TAG_KEY] as? SSTagSelectionViewModel {
                let snap = self.dataSource.snapshot()
                self.dataSource.store.attachTagTo(listItem: item, list: currentList, snap: snap, tagVM: tagVM) {
                    saveAndScroll()
                }
            } else {
                saveAndScroll()
            }
        }
        
        tb.onAddCircleTag = { [unowned self] in
            tb.animateTagView(self.tagsFromListShare())
        }
        
        quickAddView.inputAccessoryView = tb
        quickAddView.present { [unowned self] in
            let offset = self.activeKeyboardFrame.size.height + self.quickAddView.ss_height
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: offset, right: 0)
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        }
        
        quickAddView.onDismiss = { [unowned self] in
            UIView.animate(withDuration: self.quickAddView.animationDuration, delay: 0.0, options: self.quickAddView.animationCurve, animations:({
                self.tableView.contentInset = .zero
                self.tableView.scrollIndicatorInsets = .zero
            }), completion: nil)
        }
    }
}

// MARK: Ex: TagsVC and TagsManager Delegate

extension Notification.Name {
    // This will inform the TagsHorizontalView that we've got a new tag, so reload it's collection view and select it.
    static let newTagCreated = Notification.Name.init("newTagCreated")
}

extension ListViewController: SSTagsManagerViewControllerDelegate {
    func newTagWasCreated(_ newTag: SSTag) {
        NotificationCenter.default.post(name: .newTagCreated, object: newTag)
    }
    
    func tagEditorWillDismiss() {
        1.0.secondDelayThen { [weak self] in
            self?.quickAddView.isShowingTags = false
        }
    }
}

extension ListViewController : SSTagsViewControllerDelegate {
    func onTagSelectionChanged(_ tag: SSTagSelectionViewModel?, controller: SSTagsViewController) {
        // do.nothing()
    }
    
    func tagsControllerWillDismiss(_ selectedTag: SSTagSelectionViewModel?) {
        guard let tagSelection = selectedTag else { return }
        guard let _ = self.list else { return }

        if tableView.isEditing {
            let items:[SSListItem] = self.listItemsForSelectedRows()
            attach(tag: tagSelection, to: items) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(SSUIKitTableViewBatchAnimationDuration)) {
                    self.setEditing(false, animated: true)
                }
            }
        } else {
            // From context menu on an item or elsewhere
            if let itemToEdit = listItemToEdit {
                attach(tag: tagSelection, to: [itemToEdit]) {
                    
                }
            }
        }
    }
    
    func tagsFromListShare() -> [SSListTag] {
        guard let currentList = list, !currentList.listIsShared() else { return [] }
        return SSDataStore.sharedInstance().queryListTagsSharedToMe(forListID: currentList.dbID) ?? []
    }
}

// MARK: Ex: CRUD Helpers

extension ListViewController {
    func listActivityFor(_ listItem:SSListItem) -> NSUserActivity {
        let activity = NSUserActivity(activityType: ss_ListActivityOpenWindowType)
        activity.title = ss_ListActivityOpenWindowTypeTitle
        activity.userInfo = [ss_ListItemActivityOpenWindowTypeListUserInfoKey:listItem.dbID]
        return activity
    }
    
    func updateListUserActivity() {
        guard let newList = list else { return }
        let listActivity = NSUserActivity(activityType: ss_ListUserActivityType)
        listActivity.isEligibleForSearch = true
        listActivity.isEligibleForPrediction = true
        listActivity.suggestedInvocationPhrase = "Open \(newList.name)"
        listActivity.userInfo = [IncomingShortcutItem.UserInfoListIDKey:newList.dbID]
        listActivity.persistentIdentifier = newList.dbID
        
        let localizedText = ss_Localized("ctx.asqa.openList")
        let localized = String.localizedStringWithFormat(localizedText, newList.name)
        listActivity.title = localized
        
        self.userActivity = listActivity
    }
    
    func deleteListContents() {
        guard let currentList = list else { return }
        var snap = dataSource.snapshot()
        let allItems = snap.itemIdentifiers
        snap.deleteAllItems()
        dataSource.ss_apply(snap)
        dataSource.store.delete(listItems: allItems, inList: currentList)
    }
    
    func delete(items itemsToDelete:[SSListItem]) {
        guard let currentList = list else { return }
        var snap = self.dataSource.snapshot()
        snap.deleteItems(itemsToDelete)
        
        let emptySections = snap.sectionIdentifiers.filter { snap.numberOfItems(inSection: $0) == 0 }
        snap.deleteSections(emptySections)        
        self.dataSource.ss_apply(snap)
        self.dataSource.store.delete(listItems: itemsToDelete, inList: currentList)
    }
    
    func update(listItems items:[SSListItem]) {
        guard let currentList = list else { return }
        var snap = self.dataSource.snapshot()
        snap.reloadItems(items)
        self.dataSource.ss_apply(snap, animatingDifferences: false)
        self.dataSource.store.update(listItems: items, inList: currentList)
    }
    
    func save(item newItem:SSListItem) {
        guard let currentList = list else { return }
        var snapshot = dataSource.snapshot()
        let section = newItem.tag ?? dataSource.store.miscTag
        let sectionExists = snapshot.sectionIdentifiers.contains(section)
        
        if sectionExists {
            snapshot.appendItems([newItem], toSection: section)
        } else {
            var allItems = snapshot.itemIdentifiers
            allItems.append(newItem)
            var newSections:[SSListTag] = snapshot.sectionIdentifiers
            newSections.append(section)
            newSections.sort{ $0.orderingIndex.intValue < $1.orderingIndex.intValue }
            snapshot = dataSource.newSnapShotFrom(listTags: newSections, allItems: allItems)
        }
        
        dataSource.store.save(listItem: newItem, inList: currentList)
        dataSource.ss_apply(snapshot)
    }
    
    func toggleListCheckboxesShowing() {
        guard let currentList = list else { return }
        currentList.isShowingCheckboxes.toggle()
        if !currentList.isShowingCheckboxes {
            currentList.totalDisplayType = ListTotalDisplayType.all
        }

        headerView.updateSize(with: self.tableView)
        dataSource.store.update(list: currentList) {
            // No diff in the datasource, so force cells to redraw to show the checkbox or hide it
            let note = Notification.Name(SS_REQUEST_RELOAD_LIST)
            NotificationCenter.default.post(name: note, object: nil)
        }
    }
    
    func attachNewListCurrency(_ currencyID:String) {
        guard let currentList = list else { return }
        currentList.currencyIdentifier = currencyID
        dataSource.store.update(list: currentList) { [weak self] in
            guard let ds = self?.dataSource else { return }
            var snap = ds.snapshot()
            snap.reloadItems(snap.itemIdentifiers)
            ds.apply(snap)
        }
    }
    
    func attach(tag tagSelection:SSTagSelectionViewModel, to items:[SSListItem], completion:@escaping (() -> ())) {
        guard let currentList = list else { return }
        
        let snap = dataSource.snapshot()
        let completionCount = items.count
        var currentCount = 0
        items.forEach { [unowned self] listItem in
            listItem.deleteTag()
            self.dataSource.store.attachTagTo(listItem: listItem, list: currentList, snap: snap, tagVM: tagSelection) {
                currentCount += 1
                if currentCount == completionCount {
                    var snapshot = self.dataSource.snapshot()
                    let allItems = snapshot.itemIdentifiers
                    let tagSelection = listItem.tag ?? self.dataSource.store.miscTag
                    var newSections:[SSListTag] = snapshot.sectionIdentifiers
                    if (!newSections.contains(tagSelection)) {
                        newSections.append(tagSelection)
                        newSections.sort{ $0.orderingIndex.intValue < $1.orderingIndex.intValue }
                    }
                    snapshot.reloadItems(items)
                    snapshot = self.dataSource.newSnapShotFrom(listTags: newSections, allItems: allItems)
                    self.dataSource.ss_apply(snapshot)
                    self.dataSource.store.update(listItems: items, inList: currentList)
                    completion()
                }
            }
        }
    }
    
    func listItemsForSelectedRows() -> [SSListItem] {
        guard let idps = self.tableView.indexPathsForSelectedRows else { return [] }
        guard let _ = self.list else { return [] }
        var items:[SSListItem] = []
        idps.forEach { idp in
            let item = self.dataSource.itemIdentifier(for: idp)
            if item != nil { items.append(item!) }
        }
        return items
    }
    
    func scrollTo(item listItem:SSListItem) {
        guard let idp = dataSource.indexPath(for: listItem) else { return }
        tableView.scrollToRow(at: idp, at: .bottom, animated: true)
    }
    
    func presentNameOrTitleEdit(list:SSList?, listItem:SSListItem?) {
        var navVC:SSNavigationController = SSNavigationController()
        
        if let listToRename = list {
            let controller = SSEditNameViewController(list: listToRename)
            controller.onItemRenamed = { [unowned self] name in
                self.updateNavBarTitle()
            }
            navVC = SSNavigationController(rootViewController: controller)
        } else if let listItemToRename = listItem {
            let controller = SSEditNameViewController(listItem: listItemToRename)
            controller.onItemRenamed = { [unowned self] name in
                listItemToRename.title = name ?? ss_Localized("quickAdd.defaultItem")
                self.update(listItems: [listItemToRename])
            }
            navVC = SSNavigationController(rootViewController: controller)
        }
        
        if SSCitizenship.allowCustomPresentation() {
            navVC.view.backgroundColor = UIColor.clear
            navigationController?.definesPresentationContext = true
            navVC.modalPresentationStyle = .custom
            navVC.transitioningDelegate = modalAnimator
        }
        
        self.navigationController?.present(navVC, animated: true)
    }
    
    func updateNavBarTitle() {
        guard let newList = list else { return }
        title = newList.name
        
        if let customTapLabel = self.navigationItem.titleView as? SSLabel {
            customTapLabel.text = title
        }
    }
    
    func reloadEntireUI() {
        guard let currentList = list else { return }
        self.updateNavBarTitle()
        self.headerView.updateUI(for: currentList)
        self.headerView.updateSize(with: self.tableView)
        var snap = self.dataSource.snapshot()
        snap.reloadItems(snap.itemIdentifiers)
        self.updateFooters(with: snap, footersToReload: snap.sectionIdentifiers)
        self.dataSource.apply(snap)
    }
}

// MARK: List Settings Delegate

extension ListViewController : SSListSettingsViewControllerDelegate {
    
    func ss_userRequestedShareSheet() {
        showActivityController(with: exporter)
    }
    
    func ss_userRequestedStartCollaboration() {
        presentCloudKitShareController()
    }
    
    func ss_userRequestedRemoveAllItems(_ copiedList: SSList) {
        deleteListContents()
    }
    
    func ss_userRequestedListRename(_ newName: String) {
        self.updateNavBarTitle()
    }
    
    func ss_userRequestedCheckboxToggle(_ copiedList: SSList) {
        toggleListCheckboxesShowing()
    }
    
    func ss_userChangedCurrency(_ currencyID: String) {
        attachNewListCurrency(currencyID)
    }
    
    func ss_tableViewForImageShareSnapshot() -> UITableView {
        return tableView
    }
}

// MARK: Ex: Combine

extension ListViewController {
    func createSubscriptions() {
        guard subscriptions.isEmpty else { return }
        let nc = NotificationCenter.default
        
        let listTotalToggle = nc.publisher(for: Notification.Name(SS_SHOW_LIST_TOTAL_TOGGLED))
        .compactMap{ $0.object as? NSNumber }
        .sink { [unowned self] value in
            guard let currentList = self.list else { return }
            self.headerView.updateSize(with: self.tableView)
            self.headerView.updateUI(for: currentList)
            self.tableView.reloadData()
        }
        
        let requestEntireReload = nc.publisher(for: Notification.Name(SS_REQUEST_RELOAD_LIST))
        .compactMap { $0.object as? String}
        .sink { [weak self] listID in
            guard let self = self, self.list?.dbID == listID else { return }
            self.reloadEntireUI()
        }
        
        let incomingSync = nc.publisher(for: Notification.Name(SS_NOTE_DATA_CHANGED))
        .sink { [unowned self] value in
            guard let currentList = self.list else { return }
            self.dataSource.store.listExists(currentList.dbID) { exists in
                guard exists else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.dataSource.applyFreshSnapShot(withAnimation: true) { [weak self] list in
                        guard let weakSelf = self else { return }
                        let checkboxStateChanged = currentList.isShowingCheckboxes != list.isShowingCheckboxes
                        let changedCurrency = currentList.currencyIdentifier != list.currencyIdentifier
                        weakSelf.list = list
                        weakSelf.updateNavBarTitle()
                        
                        if checkboxStateChanged || changedCurrency {
                            weakSelf.reloadEntireUI()
                        }
                    }
                }
            }
        }
        
        let listCRUD = nc.publisher(for: .listCRUD)
        .compactMap { $0.object as? ListCRUDPayload }
        .sink { [weak self] payload in
            guard let self = self else { return }
            guard let ds = self.dataSource, let currentList = self.list else { return }
            guard let list = payload.lists.first else { return }
            guard list.dbID == currentList.dbID else { return }
            self.list = list
            let snap = ds.snapshot()
            let snapRef = snap as NSDiffableDataSourceSnapshotReference
            currentList.datasourceAdapter.update(from: snapRef)
            self.toggleToolBar(with: self.toolBar)
            self.updateNavBarTitle()
            if ss_defaults().bool(forKey: Show_List_Total) {
                self.headerView.updateUI(for: list)
            }
            self.updateFooters(with: snap, footersToReload: snap.sectionIdentifiers)
        }
        
        nc.publisher(for: .externalListCRUD)
        .compactMap { $0.object as? ExternalListCRUDPayload }
        .sink { [weak self] payload in
            guard let self = self else { return }
            guard let currentList = self.list else { return }
            guard payload.list.dbID == currentList.dbID, payload.listDeleted, let splitVC = self.splitViewController else { return }
            
            func dismiss() {
                if splitVC.isCollapsed {
                    splitVC.ss_masterNavController().popViewController(animated: true)
                } else {
                    self.toggleUI(for: nil)
                }
            }
            
            // We can't restore things that were not ours to begin with.
            // Or, if it's the same window we deleted from, nothing left to do.
            if payload.list.listIsSharedWithMe() || payload.windowSceneID == self.windowSceneID {
                dismiss()
                return
            }
            
            let acRestore = UIAlertAction(title: ss_Localized("list.vc.restore"), style: .default) { _ in
                self.dataSource.store.restore(list: currentList) {
                    
                }
            }
            let acLeaveDeleted = UIAlertAction(title: ss_Localized("list.vc.leaveDeleted"), style: .destructive) { _ in
                dismiss()
            }
            
            self.showAlert(withTitle: ss_Localized("list.vc.isDeleted"), message: ss_Localized("list.vc.isDeletedInfo"), actions: [acRestore, acLeaveDeleted])
        }.store(in: &subscriptions)
        
        nc.publisher(for: .inlineTagViewAddTapped)
        .sink { [weak self] _ in
            guard let self = self else { return }
            let tagsVC = SSTagsManagerViewController(tag: nil, delegate: self)
            self.quickAddView.isShowingTags = true
            SSPopupModalPresentationController.adaptivePresent(from: self, presented: tagsVC)
        }.store(in: &subscriptions)
        
        subscriptions.append(contentsOf: [listTotalToggle, incomingSync, requestEntireReload, listCRUD])
    }
    
    func unsubscribeSubscriptions() {
        subscriptions.forEach { sub in
            sub.cancel()
        }
        subscriptions.removeAll()
    }
}

// MARK: Adaptive Presentation Controller

extension ListViewController : UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        guard let itemNavVC = presentationController.presentedViewController as? SSModalCardNavigationController,
            let itemVC = itemNavVC.viewControllers.first as? SSListItemViewController else { return }
        onEditsCommitted(itemVC.editingItem())
        NotificationCenter.default.removeObserver(itemVC)
    }
}

// MARK: Nudges
extension ListViewController {
    func nudgeOver(_ nudge:Nudge) {
        guard !quickAddView.isShowing else { return }
        if nudge == .discoveredContextMenus {
            if !Nudge.hasNudged(about: .discoveredContextMenus) {
                if let ds = dataSource {
                    // Ensure they've got some stuff in here first
                    let snap = ds.snapshot()
                    guard snap.itemIdentifiers.count >= 3 else { return }
                    1.0.secondDelayThen { [weak self] in
                        guard let self = self else { return }
                        Nudge.nudgeAbout(.discoveredContextMenus, in: self)
                    }
                }
            }
        }
    }
}
