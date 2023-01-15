//
//  ListsCollectionViewDataSource.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/29/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit
import Combine
import SnapKit

public enum ListsSection {
    case main
}

public enum ListSortOption {
    case alphabetically, newest, oldest
}

public enum EmptyDataMessage {
    case pickingLists, viewingLists
    
    func message() -> String {
        switch self {
        case .pickingLists:
            return ss_Localized("selectLists.empty")
        case .viewingLists:
            return ss_Localized("emptyView.create")
        }
    }
}

extension Notification.Name {
    static let newListsSnapshotAvailable = Notification.Name.init("newListsSnapshotAvailable")
}

public typealias ListsDiff = NSDiffableDataSourceSnapshot<ListsSection, SSList>

struct ListsSnapshotPayload {
    var sourceIdentifier: String
    var snapshot: ListsDiff
    var animatingDifferences: Bool = false
    var completion:(()->())?
    
    func send() -> Void {
        NotificationCenter.default.post(name: .newListsSnapshotAvailable, object: self)
    }
}

// Handles updating a view with lists. Note that if you call into the data store,
// In most cases that will post .listCRUD which this listens for. It then refreshes
// The list, and posts its own notification to apply the snapshot. So make sure you
// Dont send a ListsSnapshotPayload unless you need it.
class ListsCollectionViewDataSource: UICollectionViewDiffableDataSource<ListsSection, SSList> {
    let store:DataStore = DataStore()
    var list: SSList!
    weak var collectionView: UICollectionView?
    var excludeLists: [String]?
    var dataMessagePreference: EmptyDataMessage = .viewingLists
    var emptyState: SSEmptyStateView?
    let sourceIdentifier = UUID().uuidString
    
    // MARK: Private properties
    
    private var subscriptions: [AnyCancellable] = []
    private var id = UUID().uuidString
    private var lists: [SSList] = []
    
    // MARK: Initializer
    
    override init(collectionView: UICollectionView, cellProvider: @escaping UICollectionViewDiffableDataSource<ListsSection, SSList>.CellProvider) {
        super.init(collectionView: collectionView, cellProvider: cellProvider)
        self.collectionView = collectionView
        
        // Snapshot application
        let nc = NotificationCenter.default
        nc.publisher(for: .newListsSnapshotAvailable)
        .compactMap { $0.object as? ListsSnapshotPayload }
        .receive(on: RunLoop.main)
        .sink { [weak self] payload in
            guard let self = self else { return }
            self.apply(payload.snapshot, animatingDifferences: payload.animatingDifferences) { [weak self] in
                guard let self = self else { return }
                guard payload.sourceIdentifier == self.sourceIdentifier else { return }
                
                // Empty view
                if payload.snapshot.itemIdentifiers.isEmpty && self.collectionView != nil {
                    self.emptyState = SSEmptyStateView(stateText: self.dataMessagePreference.message(), performAnimaton: true)
                    self.collectionView!.superview!.addSubview(self.emptyState!)
                    self.emptyState!.snp.makeConstraints { make in
                        make.edges.equalTo(self.collectionView!)
                    }
                } else {
                    if let emptyView = self.emptyState, emptyView.superview != nil {
                        emptyView.removeFromSuperview()
                    }
                }
                
                // Completion
                if let handler = payload.completion {
                    handler()
                }
            }
        }.store(in: &subscriptions)
        
        // List edits
        nc.publisher(for: .listCRUD)
        .compactMap { $0.object as? ListCRUDPayload }
        .receive(on: RunLoop.main)
        .sink { [weak self] payload in
            guard let self = self else { return }
            
            func createSnapshot(with lists: [SSList]?) {
                guard let updatedLists = lists else { return }
                var snap = self.snapshot()

                updatedLists.forEach { list in
                    // reloadItem might now work here, I assume due to identity vs equality?
                    // So, I just swap out the list at the right index and apply the diff.
                    if snap.itemIdentifiers.contains(list) {
                        snap.reloadItems([list])
                    } else if let replaceIDX = snap.itemIdentifiers.firstIndex(where: { $0.dbID == list.dbID }) {
                        snap.insertItems([list], afterItem: snap.itemIdentifiers[replaceIDX])
                        snap.deleteItems([snap.itemIdentifiers[replaceIDX]])
                    } else {
                        // New ones
                        let listIndex = list.orderingIndex.intValue
                        if snap.itemIdentifiers.isEmpty {
                            snap.appendItems([list])
                        } else if listIndex == 0 {
                            snap.insertItems([list], beforeItem: snap.itemIdentifiers.first!)
                        } else {
                            snap.insertItems([list], afterItem: snap.itemIdentifiers[listIndex - 1])
                        }
                    }
                }

                let payload = ListsSnapshotPayload(sourceIdentifier: self.sourceIdentifier, snapshot: snap, animatingDifferences: true)
                payload.send()
            }
            
            if payload.listsHaveBeenUpdated {
                // Just apply the snapshot
                createSnapshot(with: payload.lists)
            } else {
                // Get them from the DB
                self.store.fetch(lists: payload.lists.map(\.dbID)) { lists in
                    createSnapshot(with: lists)
                }
            }
        }.store(in: &subscriptions)
        
        // Whole number toggle
        let wholeNumToggle = Notification.Name.init(SS_WHOLE_NUMBERS_TOGGLED)
        nc.publisher(for: wholeNumToggle)
        .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            // Here the data didn't actually change, just the way its shown. So reload.
            let selectedIDP = self.collectionView?.indexPathsForSelectedItems?.first
            self.collectionView?.reloadData()
            if let idp = selectedIDP {
                self.collectionView?.selectItem(at: idp, animated: false, scrollPosition: .centeredVertically)
            }
        }.store(in: &subscriptions)
        
        // Things that require a full fetch and diff
        nc.publisher(for: Notification.Name(SS_NOTE_DATA_CHANGED))
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.applyFreshSnapshot(animating: true)
        }.store(in: &subscriptions)
    }
    
    deinit {
        subscriptions.forEach { $0.cancel() }
        store.closeDB()
    }
    
    // MARK: Private
    
    fileprivate func refreshListAndPostExternalCRUD(list:SSList) {
        // This isn't the best. The delay is because we can reernter the DB queue.
        // Then we need a hydrated list because these observers expect a fully
        // Updated one.
        0.25.secondDelayThen { [weak self] in
            guard let self = self else { return }
            self.store.fetch(list: list.dbID) { newList in
                if let updatedList = newList {
                    let externalPayload = ExternalListCRUDPayload(list: updatedList)
                    externalPayload.send()
                }
            }
        }
    }
    
    // MARK: Public Functions

    func applySortOption(_ sortOption:ListSortOption) {
        var snap = snapshot()
        var currentLists = snap.itemIdentifiers
        
        switch sortOption {
        case .alphabetically:
            currentLists.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .newest:
            currentLists.sort { $1.dateCreated < $0.dateCreated }
        case .oldest:
            currentLists.sort { $0.dateCreated < $1.dateCreated }
        }
        
        snap.deleteItems(snap.itemIdentifiers)
        snap.appendItems(currentLists, toSection: .main)
        
        // Set new list ordering.
        for (idx, list) in currentLists.enumerated() {
            list.orderingIndex = idx.toNumber()
        }
        
        // Save to the DB and server. Ignore list ordering for lists that aren't yours.
        store.update(lists: currentLists, excludingListsFromSync:currentLists.filter { $0.listIsSharedWithMe() })
        
        let payload = ListsSnapshotPayload(sourceIdentifier: sourceIdentifier, snapshot: snap, animatingDifferences: true, completion: nil)
        payload.send()
    }
    
    func saveNewOrder(from snap:ListsDiff) {
        let lists = snap.itemIdentifiers
        
        // Set new list ordering.
        for (idx, list) in lists.enumerated() {
            list.orderingIndex = idx.toNumber()
        }
        
        // Save to the DB and server. Ignore list ordering for lists that aren't yours.
        store.update(lists: lists, excludingListsFromSync:lists.filter { $0.listIsSharedWithMe() })
        
        let payload = ListsSnapshotPayload(sourceIdentifier: sourceIdentifier, snapshot: snap, animatingDifferences: true, completion: nil)
        payload.send()
    }
    
    // This will refresh ordering and take care of local, DB and server commits.
    func removeLists(lists:[SSList], completion:(()->())? = nil) {
        var snap = snapshot()
        snap.deleteItems(lists)
        store.delete(lists: lists)
        
        let payload = ListsSnapshotPayload(sourceIdentifier: sourceIdentifier, snapshot: snap, animatingDifferences: true, completion: completion)
        payload.send()
    }
    
    func removeAllItems(from list:SSList) {
        store.delete(listItems: list.datasourceAdapter.allItems, inList: list) { [weak self] in
            guard let self = self else { return }
            self.refreshListAndPostExternalCRUD(list: list)
        }
    }
    
    func update(listItems:[SSListItem], inList list:SSList) {
        store.update(listItems: listItems, inList: list) { [weak self] in
            guard let self = self else { return }
            self.refreshListAndPostExternalCRUD(list: list)
        }
    }
    
    func applyFreshSnapshot(animating:Bool, completion:(()->())? = nil) {
        store.fetchAllLists { [weak self] lists in
            guard let self = self else { return }
            self.lists = lists
            
            var items = lists
            if let exclusions = self.excludeLists {
                items = lists.filter{ !exclusions.contains($0.dbID) }
            }

            var snap = ListsDiff()
            snap.appendSections([.main])
            snap.appendItems(items)
            
            let payload = ListsSnapshotPayload(sourceIdentifier: self.sourceIdentifier, snapshot: snap, animatingDifferences: animating, completion: completion)
            payload.send()
        }
    }
}
