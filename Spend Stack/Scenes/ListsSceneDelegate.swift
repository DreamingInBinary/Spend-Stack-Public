//
//  ListsSceneDelegate.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 7/25/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

class ListsSceneDelegate: UIResponder, UIWindowSceneDelegate {
    // MARK: Public Properties
    var window: UIWindow?
    var quickActionHandler = QuickActionShortcutHandler()
    
    // MARK: Private Properties
    private let store = DataStore()
    private lazy var hasSeenFirstRunNotice: Bool = {
        let defaults = ss_defaults()
        return defaults.bool(forKey: SS_HAS_SEEN_FIRST_RUN)
    }()
    
    // MARK: Scene Delegate
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .black
        quickActionHandler.action = connectionOptions.shortcutItem
        
        if let ckShare = connectionOptions.cloudKitShareMetadata {
            setupRootViewController()
            self.windowScene(windowScene, userDidAcceptCloudKitShareWith: ckShare)
        } else if let userActivity = connectionOptions.userActivities.first {
            
            // Open list or a list item
            if let listDBID = userActivity.userInfo?[ss_ListActivityOpenWindowTypeListUserInfoKey] {
                let listID = listDBID as? String ?? ""
                setupRootViewControllerWithListID(listID, windowScene: windowScene)
            } else if let listItemDBID = userActivity.userInfo?[ss_ListItemActivityOpenWindowTypeListUserInfoKey] {
                let listItemID = listItemDBID as? String ?? ""
                setupRootViewControllerWithListItemID(listItemID, windowScene: windowScene)
            } else {
                // Widget fired us up
                setupRootViewController()
            }
       // } else if let restoration = session.stateRestorationActivity {
            // Uncomment this to implement robust state restoration
        } else {
            setupRootViewController()
            windowScene.title = ss_Localized("general.lists")
        }
        
        // Cold boot from a quick action
        if let _ = quickActionHandler.action {
            quickActionHandler.processQuickAction()
        }
        
        // Cold boot from a URL Context
        if let _ = connectionOptions.urlContexts.first {
            self.scene(windowScene, openURLContexts: connectionOptions.urlContexts)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }
    
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        if let splitVC = windowScene.windows.first?.rootViewController as? UISplitViewController {
            if splitVC.isCollapsed {
                splitVC.ss_masterNavController().popViewController(animated: true)
            }
        }
        
        // If they aren't signed into iCloud, Apple will show an error for us
        SSDataStore.sharedInstance().ckManager.acceptShareMetaData(cloudKitShareMetadata) { error in
            print("Spend Stack - Accepted share with error: \(String.init(describing: error)) and metadata: \(cloudKitShareMetadata)")
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        quickActionHandler.action = shortcutItem
        quickActionHandler.processQuickAction()
        completionHandler(true)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        createRootIfNeeded()
        
        if userActivity.activityType == ss_ListUserActivityType, let listDBID = userActivity.userInfo?[IncomingShortcutItem.UserInfoListIDKey] as? String {
            store.fetch(list: listDBID) { list in
                guard let fetchedList = list else { return }
                NotificationCenter.default.post(name: .openListFromWidgetTap, object: fetchedList.dbID)
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let firstContext = URLContexts.first else { return }
        let sharedConstants = SharedConstants()
        let type = URLType.urlTypeFromURL(firstContext.url)
        
        switch type {
        case .openItem:
            if let itemID = sharedConstants.openItemIDFromURLRequest(firstContext.url) {
                // Open list item
                guard let rootVC = window?.rootViewController as? UISplitViewController else {
                    createRootIfNeeded()
                    return
                }
                let listsVC = rootVC.ss_masterViewController()
                listsVC.open(listItem: itemID)
            } else {
                createRootIfNeeded()
            }
        case .openList:
            if let listID = sharedConstants.openListIDFromURLRequest(firstContext.url) {
                // Open list
                store.fetch(list: listID) { list in
                    guard let fetchedList = list else { return }
                    NotificationCenter.default.post(name: .openListFromWidgetTap, object: fetchedList.dbID)
                }
            } else {
                createRootIfNeeded()
            }
        default:
            createRootIfNeeded()
        }
    }
    
    private func createRootIfNeeded() {
        if window?.rootViewController == nil {
            setupRootViewController()
        }
    }
    
    // MARK: Private Functions
    private func setupRootViewController() {
//        var killDateComps = DateComponents()
//        killDateComps.day = 20
//        killDateComps.month = 09
//        killDateComps.year = 2020
//        if let killDate = Calendar.current.date(from: killDateComps) {
//            let hitOrBeyondKillDate = Date().compare(killDate) != ComparisonResult.orderedAscending
//
//            if hitOrBeyondKillDate {
//                window?.rootViewController = SSBetaExpiredViewController()
//                window?.makeKeyAndVisible()
//                return
//            }
//        }
        
        let listsVC = ListsViewController()
        let listsNav = SSNavigationController(forDynamicStlyingWithRootViewController: listsVC)
        let listNav = SSNavigationController(rootViewController: ListViewController(with: nil))
        
        let splitVC = UISplitViewController()
        splitVC.viewControllers = [listsNav, listNav]
        splitVC.delegate = self
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.view.alpha = hasSeenFirstRunNotice ? 1.0 : 0.0
        
        window?.rootViewController = splitVC
        window?.makeKeyAndVisible()
        window?.tintColor = .ssPrimary()
        window?.backgroundColor = .black
        
        if !hasSeenFirstRunNotice {
            let firstRunVC = SSFirstRunViewController()
            splitVC.present(firstRunVC, animated: false)
        }
    }
    
    func setupRootViewControllerWithListID(_ listID: String, windowScene: UIWindowScene) {
        store.fetch(list: listID) { list in
            let listNav = SSNavigationController(rootViewController: ListViewController(with: list))
            
            window?.rootViewController = listNav
            window?.makeKeyAndVisible()
            window?.tintColor = .ssPrimary()
            window?.backgroundColor = .black
            
            windowScene.title = list?.name ?? ""
        }
    }
    
    func setupRootViewControllerWithListItemID(_ listItemID: String, windowScene: UIWindowScene) {
        store.fetch(listItem: listItemID) { listItem in
            // If the listItem is nil, we need to crash.
            let listItemVC = SSListItemViewController(listItem: listItem!, delegate: self)
            let listItemNav = SSModalCardNavigationController(rootViewController: listItemVC)

            window?.rootViewController = listItemNav
            window?.makeKeyAndVisible()
            window?.tintColor = .ssPrimary()
            window?.backgroundColor = .black

            windowScene.title = listItem?.title ?? ""
        }
    }
}

extension ListsSceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        var isListNavWithNoList = false
        var isListVCWithNoList = false
        
        if let navVC = secondaryViewController as? UINavigationController,
           let topListController = navVC.topViewController as? ListViewController {
            isListNavWithNoList = topListController.list == nil
        }
        
        if let listVC = secondaryViewController as? ListViewController {
            isListVCWithNoList = listVC.list == nil
        }
        
        // If true, secondary controller will be discarded.
        return (isListNavWithNoList || isListVCWithNoList) ? true : false 
    }
}

extension ListsSceneDelegate: SSListItemViewControllerDelegate {
    func onEditsCommitted(_ editedListItem: SSListItem) {
        store.update(listItems: [editedListItem], inList: nil) {
            DispatchQueue.main.async { [weak self] in 
                self?.store.fetch(list: editedListItem.fkListID) { list in
                    guard let fetchedList = list else { return }
                    let payload = ExternalListCRUDPayload(list: fetchedList)
                    payload.send()
                }
            }
        }
    }
    
    func requestDelete(_ itemToDelete: SSListItem) -> Bool {
        store.delete(listItems: [itemToDelete], inList: nil) {
            DispatchQueue.main.async { [weak self] in
                self?.store.fetch(list: itemToDelete.fkListID) { list in
                    guard let fetchedList = list else { return }
                    let payload = ExternalListCRUDPayload(list: fetchedList)
                    payload.send()
                }
            }
        }
        
        return true
    }
    
    func shouldReflectSingleWindowUI() -> Bool {
        return true
    }
    
    func requestCloseSceneSession(forListItemController sceneSession: UISceneSession?) {
        guard let session = sceneSession else { return }
        UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
    }
}
