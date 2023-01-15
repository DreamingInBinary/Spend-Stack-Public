//
//  SwiftShim.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/20/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import Foundation
import WidgetKit

@objc class SwiftShims : NSObject {
    @objc func reloadWidgets() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        } 
    }
}
