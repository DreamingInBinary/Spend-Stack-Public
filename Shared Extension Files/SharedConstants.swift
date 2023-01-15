//
//  SharedConstants.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/20/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import SwiftUI

let primaryFont = Color("PrimaryFont")
let secondaryFont = Color("SecondaryFont")
let tertiaryFont = Color("TertiaryFont")

extension Notification.Name {
    static let openListFromWidgetTap = Notification.Name.init("listWidgetTapped")
}

enum URLType {
    case openItem, openList, unknown
    
    static func urlTypeFromURL(_ url:URL) -> URLType {
        if url.absoluteString.contains(SharedConstants.openItemURL) {
            return .openItem
        } else if url.absoluteString.contains(SharedConstants.openListURL) {
            return .openList
        } else {
            return .unknown
        }
    }
}

struct SharedConstants {
    static let openItemURL = "spendstack://openItem:"
    static let openListURL = "spendstack://openList:"
    static let appGroupID = "group.dib.ss"

    // MARK: Functions
    func sharedDefaults() -> UserDefaults {
        return UserDefaults(suiteName: SharedConstants.appGroupID)!
    }
    
    func openItemIDFromURLRequest(_ itemURL: URL) -> String? {
        let urlString = itemURL.absoluteString
        guard !urlString.contains("empty") else { return nil }
        return urlString.deletingPrefix(SharedConstants.openItemURL)
    }
    
    func openListIDFromURLRequest(_ itemURL: URL) -> String? {
        let urlString = itemURL.absoluteString
        guard !urlString.contains("empty") else { return nil }
        return urlString.deletingPrefix(SharedConstants.openListURL)
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
