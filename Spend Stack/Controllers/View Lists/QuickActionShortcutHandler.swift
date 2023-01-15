//
//  QuickActionShortcutHandler.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 7/24/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import Combine

public extension Notification.Name {
    static let handleShortcutAction = Notification.Name.init("handleShortcutAction")
}

typealias QuickActionUserInfo = [String : NSSecureCoding]?
// These match the info.plist shortcut item types
let QuickActionTypeCreate = "CreateAction"
let QuickActionTypeSearch = "SearchAction"
let QuickActionTypeExport = "ExportAction"
let QuickActionTypeOpenList = "OpenList"

enum IncomingShortcutItem {
    case CreateAction(String, QuickActionUserInfo)
    case SearchAction(String, QuickActionUserInfo)
    case ExportAction(String, QuickActionUserInfo)
    case OpenList(String, QuickActionUserInfo)
    
    static let UserInfoListIDKey: String = "UserInfoListIDKey"
    
    init?(shortCutType: String, info: QuickActionUserInfo) {
        switch shortCutType {
        case QuickActionTypeCreate:
            self = IncomingShortcutItem.CreateAction(shortCutType, info)
        case QuickActionTypeSearch:
            self = IncomingShortcutItem.SearchAction(shortCutType, info)
        case QuickActionTypeExport:
            self = IncomingShortcutItem.ExportAction(shortCutType, info)
        case QuickActionTypeOpenList:
            self = IncomingShortcutItem.OpenList(shortCutType, info)
        default:
            return nil
        }
    }
}

struct QuickActionShortcutHandler {

    // MARK: Public properties
    var action: UIApplicationShortcutItem?
    
    // MARK: Private roperties
    private var hasSeenFirstRun: Bool = {
        return ss_defaults().bool(forKey: SS_HAS_SEEN_FIRST_RUN)
    }()

    // MARK: Public Functions
    mutating func processQuickAction() {
        guard let quickAction = action, let shortCutAction = IncomingShortcutItem(shortCutType: quickAction.type, info: quickAction.userInfo), hasSeenFirstRun else {
            return
        }
        
        let nc = NotificationCenter.default
        
        // Let other views close
        nc.post(name: NSNotification.Name(SS_HANDLING_QUICK_ACTION), object: nil)
        
        //Now we've got a valid shortcut, handle it.
        nc.post(name: .handleShortcutAction, object: shortCutAction)
    
        action = nil
    }
    
    func createDynamicQuickActionForList(_ list:SSList) -> UIApplicationShortcutItem {
        let localizedText = ss_Localized("ctx.asqa.openList")
        let localized = String.localizedStringWithFormat(localizedText, list.name)
        let userInfo: QuickActionUserInfo = [IncomingShortcutItem.UserInfoListIDKey: list.dbID as NSString]
        let icon = UIApplicationShortcutIcon(systemImageName: "doc.text")
        let shortcutQuickAction = UIApplicationShortcutItem(type: QuickActionTypeOpenList, localizedTitle: localized, localizedSubtitle: nil, icon: icon, userInfo: userInfo)
        return shortcutQuickAction
    }
    
    func addDynamicQuickActionForList(_ list:SSList) {
        let shortcutAction = createDynamicQuickActionForList(list)
        UIApplication.shared.shortcutItems = [shortcutAction]
    }
}
