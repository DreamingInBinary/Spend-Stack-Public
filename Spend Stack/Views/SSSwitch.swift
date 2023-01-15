//
//  SSSwitch.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/3/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

@available(iOS 14, *)
@objc class SSSwitch: UISwitch {
    // MARK: Public properties
    @objc var menu: UIMenu?
    
    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        onTintColor = .ssPrimary()
        isContextMenuInteractionEnabled = true
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Context menu
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_: [UIMenuElement]) -> UIMenu? in
            return self.menu
        }
    }
}
