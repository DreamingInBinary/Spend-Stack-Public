//
//  Nudge.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 9/19/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import UIKit

enum Nudge: String  {
    case discoveredContextMenus
    
    static func hasNudged(about nudge:Nudge) -> Bool {
        let defaults = ss_defaults()
        return defaults.bool(forKey: nudge.rawValue)
    }
    
    static func nudgeAbout(_ nudge:Nudge, in controller:UIViewController) {
        let acConfirm = UIAlertAction(title: ss_Localized("general.gotIt"), style: .default) { _ in
            nudge.confirmNudge()
        }
        
        let nudgeEmController = UIAlertController(title: nudge.titleText(), message: nudge.messageText(), preferredStyle: .alert)
        nudgeEmController.addActions([acConfirm])
        controller.present(nudgeEmController, animated: true)
    }
    
    func confirmNudge() {
        let defaults = ss_defaults()
        defaults.set(true, forKey: self.rawValue)
    }
    
    func titleText() -> String {
        switch self {
        case .discoveredContextMenus:
            return ss_Localized("nudgeTitleCTXMenu")
        }
    }
    
    func messageText() -> String {
        switch self {
        case .discoveredContextMenus:
            return ss_Localized("nudgeMsgCTXMenu")
        }
    }
}
