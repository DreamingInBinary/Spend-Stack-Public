//
//  ListCreatedPayload.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 7/17/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import Combine

public extension Notification.Name {
    static let listCreated = Notification.Name.init("listCreated")
}

public struct ListCreatedPayload {
    var animateReload: Bool = false
    var windowSceneID: String
    var selectAndOpenNewList: Bool = false
    
    func send() -> Void {
        NotificationCenter.default.post(name: .listCreated, object: self)
    }
}

@objc class ListCreatedPayloadShim: NSObject {
    @objc static func sendListCreatedPayload(animateReload:Bool, windowSceneID: String) {
        let payload = ListCreatedPayload(animateReload: animateReload, windowSceneID: windowSceneID, selectAndOpenNewList: true )
        payload.send()
    }
}
