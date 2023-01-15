//
//  ListDataSource.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/13/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit
import Combine
import SnapKit

public typealias ListDiff = NSDiffableDataSourceSnapshot<SSListTag, SSListItem>

private extension Notification.Name {
    static let snapshotApplied = Notification.Name.init("listSnapshotApplied")
}

public extension Notification.Name {
    // For CRUD for this list that occurred in another list or window (i.e. move, copy or single item in a window)
    static let externalListCRUD = Notification.Name.init("externalListCRUD")
}

struct ExternalListCRUDPayload {
    var list: SSList
    var listDeleted: Bool = false
    var windowSceneID: String?
    
    func send() {
        NotificationCenter.default.post(name: .externalListCRUD, object: self)
    }
}

struct SnapshotPayload {
    var origin:String
    var snapshot:ListDiff
    var listID:String
    
    func send() {
        NotificationCenter.default.post(name: .snapshotApplied, object: self)
    }
}

class ListDataSource: UITableViewDiffableDataSource<SSListTag, SSListItem> {
    // MARK: Public Properties
    
    var list:SSList!
    weak var tableView:UITableView?
    var emptyView:UIView?
    var emptyViewConstraints:((_ make: ConstraintMaker) -> Void)?
    var listHasTaggedItems:Bool {
        let snapshot = self.snapshot()
        return !(snapshot.sectionIdentifiers.first == self.store.miscTag && snapshot.sectionIdentifiers.count == 1)
    }
    let store:DataStore = DataStore()
    
    // MARK: Private properties
    
    private var subscriptions:[AnyCancellable] = []
    private var id = UUID().uuidString
    
    // MARK: Initializer
    
    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<SSListTag, SSListItem>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        self.tableView = tableView
        defaultRowAnimation = .right
        createSubscriptions()
    }
    
    deinit {
        emptyView?.removeFromSuperview()
        subscriptions.forEach { $0.cancel() }
        store.closeDB()
    }
    
    // MARK: Subscriptions
    
    func createSubscriptions() {
        let nc = NotificationCenter.default
        
        nc.publisher(for: Notification.Name(SS_SHOW_TAG_FOOTER_TOGGLED))
        .merge(with: nc.publisher(for: Notification.Name(SS_WHOLE_NUMBERS_TOGGLED)))
        .merge(with: nc.publisher(for: Notification.Name(SS_REQUEST_RELOAD_LIST)))
        .sink { [weak self] value in
            guard let weakSelf = self else { return }
            // We need to force the cells to redraw. Not ideal, but there is no
            // Diff in the model in these situations.
            weakSelf.tableView?.reloadData()
        }.store(in: &subscriptions)

        nc.publisher(for: .listCRUD)
        .compactMap { $0.object as? ListCRUDPayload }
        .sink { [weak self] payload in
            guard let weakSelf = self else { return }
            guard let currentList = weakSelf.list else { return }
            guard let list = payload.lists.first else { return }
            guard list.dbID == currentList.dbID else { return }
            weakSelf.showEmptyViewIfNeeded()
        }.store(in: &subscriptions)
        
        nc.publisher(for: Notification.Name(SS_TAG_CRUD_FROM_TAG_MANAGER_CONTROLLER))
        .compactMap { $0.object as? SSTag}
        .filter ({ [weak self] tag in
            guard let weakSelf = self else { return false }
            let tagIDs = weakSelf.snapshot().sectionIdentifiers.map{ return $0.fkTagID }
            return tagIDs.contains(tag.dbID)
        })
        .receive(on: RunLoop.main)
        .sink { [weak self] tag in
            guard let weakSelf = self else { return }
            weakSelf.applyFreshSnapShot(withAnimation: true, postChange: false) { list in
                guard let currentList = weakSelf.list else { return }
                let snapRef = weakSelf.snapshot() as NSDiffableDataSourceSnapshotReference
                currentList.datasourceAdapter.update(from: snapRef)
            }
        }.store(in: &subscriptions)

        if UIDevice.current.userInterfaceIdiom == .pad {
            nc.publisher(for: .snapshotApplied)
            .compactMap { $0.object as? SnapshotPayload }
            .filter { [weak self] in
                guard let weakSelf = self else { return false }
                return $0.origin != weakSelf.id
             }
            .sink { [weak self] payload in
                guard let weakSelf = self else { return }
                guard let currentList = weakSelf.list else { return }
                guard payload.listID == currentList.dbID else { return }
                currentList.datasourceAdapter.update(from: payload.snapshot as NSDiffableDataSourceSnapshotReference)
                weakSelf.apply(payload.snapshot, animatingDifferences: true)
            }.store(in: &subscriptions)
            
            nc.publisher(for: .externalListCRUD)
            .compactMap { $0.object as? ExternalListCRUDPayload }
            .sink { [weak self] payload in
                guard let weakSelf = self else { return }
                guard let currentList = weakSelf.list else { return }
                guard payload.list.dbID == currentList.dbID, !payload.listDeleted else { return }
                let snap = weakSelf.newSnapShotFrom(listTags: payload.list.datasourceAdapter.sortedTags, allItems: payload.list.datasourceAdapter.allItems)
                currentList.datasourceAdapter.update(from: snap as NSDiffableDataSourceSnapshotReference)
                weakSelf.apply(snap, animatingDifferences: true) {
                    weakSelf.showEmptyViewIfNeeded()
                }
            }.store(in: &subscriptions)
        }
    }
    
    // MARK: Reordering support
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // TODO: Check for sort method
        tagSort_tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
    
    // MARK: Editing support

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // TODO: Check for sort method
        tagSort_tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    }
    
    // MARK: Snapshot
    
    // Returns a fresh snap shot based off of the data passed into it.
    func newSnapShotFrom(listTags allTags:[SSListTag], allItems:[SSListItem]) -> ListDiff {
        // TODO: Check for sort method
        tagSort_newSnapShotFrom(listTags: allTags, allItems: allItems)
    }

    // Returns a fresh snap shot by querying the list within the database.
    func applyFreshSnapShot(withAnimation animation:Bool, postChange:Bool = true, completion:((SSList) -> ())? = nil) {
        // TODO: Check for sort method
        tagSort_applyFreshSnapShot(withAnimation: animation, postChange: postChange, completion: completion)
    }
    
    // Applies the snapshot to the diffable datasource while also posting a notification and showing
    // An empty view if it's needed.
    func ss_apply(_ snapshot: NSDiffableDataSourceSnapshot<SSListTag, SSListItem>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        // TODO: Check for sort method
        tagSort_ssApply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
    }
    
    // MARK: Empty View
    
    func showEmptyViewIfNeeded(delay:Bool = true) {
        guard let ev = emptyView, let tv = tableView else { return }
        let shouldShow = snapshot().itemIdentifiers.isEmpty && ev.superview == nil
        
        if shouldShow {
            func showEmptyView() {
                guard let vc = tv.closestViewController() else { return }
                vc.view.addSubview(ev)
                ev.isUserInteractionEnabled = false
                if let constraints = self.emptyViewConstraints {
                    ev.snp.remakeConstraints { make in
                        constraints(make)
                    }
                }
                
                if let emptyView = ev as? SSEmptyStateView {
                    emptyView.performAnimation()
                }
            }
            
            if delay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showEmptyView()
                }
            } else {
                showEmptyView()
            }
            
        } else {
            ev.removeFromSuperview()
        }
    }
}

// MARK: Tag Sort

extension ListDataSource {
    func tagSort_tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let fromListItem = itemIdentifier(for: sourceIndexPath) else { return }
        guard sourceIndexPath != destinationIndexPath else { return }
        let toListItem = itemIdentifier(for: destinationIndexPath)
        var destinationTag:SSListTag?
        
        var snapshot = self.snapshot()
        
        if let destinationListItem = toListItem {
            if let sourceIndex = snapshot.indexOfItem(fromListItem),
               let destinationIndex = snapshot.indexOfItem(destinationListItem) {
                
                let isAfter = destinationIndex > sourceIndex &&
                    snapshot.sectionIdentifier(containingItem: fromListItem) ==
                    snapshot.sectionIdentifier(containingItem: destinationListItem)
                
                snapshot.deleteItems([fromListItem])
                if isAfter {
                    snapshot.insertItems([fromListItem], afterItem: destinationListItem)
                } else {
                    snapshot.insertItems([fromListItem], beforeItem: destinationListItem)
                }

                destinationTag = snapshot.sectionIdentifier(containingItem: fromListItem)
            }
        } else {
            let destinationSectionIdentifier = snapshot.sectionIdentifiers[destinationIndexPath.section]
            snapshot.deleteItems([fromListItem])
            snapshot.appendItems([fromListItem], toSection: destinationSectionIdentifier)
            
            destinationTag = snapshot.sectionIdentifiers[destinationIndexPath.section]
        }
        
        ss_apply(snapshot, animatingDifferences: false)
        
        // Update swap in DB
        if let tag = destinationTag, tag != fromListItem.tag {
            fromListItem.onListTagSet = { [weak self] tag in
                guard let currentList = self?.list else { return }
                self?.store.update(listItems: [fromListItem], inList: currentList)
            }
            fromListItem.addTag(tag, with: list)
        }
    }
    
    func tagSort_tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let identifierToDelete = itemIdentifier(for: indexPath) {
                var snapshot = self.snapshot()
                
                let sectionIdentifier = snapshot.sectionIdentifiers[indexPath.section]
                snapshot.deleteItems([identifierToDelete])
                
                if snapshot.itemIdentifiers(inSection: sectionIdentifier).isEmpty {
                    snapshot.deleteSections([sectionIdentifier])
                }
                
                ss_apply(snapshot)
                store.delete(listItems: [identifierToDelete], inList: list)
            }
        }
    }
    
    func tagSort_newSnapShotFrom(listTags allTags:[SSListTag], allItems:[SSListItem]) -> ListDiff {
        var snapshot = ListDiff()
        
        allTags.forEach { listTag in
            var tagItems:[SSListItem]
            if listTag == self.store.miscTag {
                tagItems = allItems.filter { $0.tag == nil }
            } else {
                tagItems = allItems.filter { $0.tag == listTag }
            }
            tagItems.sort{ $0.orderingIndex.intValue < $1.orderingIndex.intValue }

            if tagItems.isEmpty {
                snapshot.deleteSections([listTag])
            } else {
                snapshot.appendSections([listTag])
                snapshot.appendItems(tagItems, toSection: listTag)
            }
        }
        
        return snapshot
    }
    
    func tagSort_applyFreshSnapShot(withAnimation animation:Bool, postChange:Bool = true, completion:((SSList) -> ())? = nil) {
        guard list != nil else { return }
        store.fetch(list: list) { [weak self] result in
            let allTags:[SSListTag] = result.allTags
            let allItems:[SSListItem] = result.allItems
            let newList:SSList = result.updatedList
            
            let snapshot = newSnapShotFrom(listTags: allTags, allItems: allItems)
            
            if postChange {
                self?.ss_apply(snapshot, animatingDifferences: animation)
            } else {
                apply(snapshot, animatingDifferences: animation)
            }
            
            self?.showEmptyViewIfNeeded()
            if let handler = completion {
                handler(newList)
            }
        }
    }
    
    func tagSort_ssApply(_ snapshot: NSDiffableDataSourceSnapshot<SSListTag, SSListItem>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        guard let currentList = list else { return }
        apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        let payload = SnapshotPayload(origin: String(id), snapshot: snapshot, listID: String(currentList.dbID))
        payload.send()
        self.showEmptyViewIfNeeded()
    }
}
