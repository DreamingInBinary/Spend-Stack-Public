//
//  SSContextButton.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/5/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

@objc class SSContextButton: UIControl {
    // MARK: Properties
    @objc var items: [UIAction] = [] {
        didSet {
            if #available(iOS 14.0, *) {
                if items.isEmpty {
                    self.showsMenuAsPrimaryAction = false
                    self.contextMenuInteraction?.dismissMenu()
                    self.isContextMenuInteractionEnabled = false
                } else {
                    self.showsMenuAsPrimaryAction = true
                    self.updateMenuIfVisible()
                    self.isContextMenuInteractionEnabled = true
                }
            }
        }
    }
    
    var selectedIndex: Int = -1 {
        didSet {
            self.updateMenuIfVisible()
        }
    }
    
    var showSelectedItem: Bool = true {
        didSet {
            self.updateMenuIfVisible()
        }
    }
    
    @objc var buttonText: String? {
        didSet {
            titleLabel.text = buttonText
            accessibilityLabel = buttonText
        }
    }
    
    @objc var buttonColor: UIColor? {
        didSet {
            titleLabel.textColor = buttonColor
        }
    }
    
    @objc var buttonFont: UIFont? {
        get {
            return titleLabel.font
        }
    }
    
    @objc var menuTitle: String?
    
    @objc var onTap: (() -> ())?
    
    private lazy var titleLabel: SSLabel = {
        let label = SSLabel(textStyle: .caption1)
        label.textColor = .ssPrimary()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.configureFontWeight(.light)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.heightAnchor.constraint(greaterThanOrEqualTo: label.heightAnchor),
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: 10.0)
        ])
        return label
    }()
    
    private lazy var dimBackground: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.frame = titleLabel.bounds
        view.backgroundColor = .ssTextPlaceholder()
        self.insertSubview(view, at: 0)
        view.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        return view
    }()
    
    private var primaryActionID = "com.dib.customContextMenu.primarAction"
    
    // MARK: Initializers
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 14.0, *) {
            self.showsMenuAsPrimaryAction = true
        }
        accessibilityTraits = .button
        configureBackground(highlighted: false)
    }

    convenience init(frame: CGRect, primaryAction: UIAction?) {
        self.init(frame: frame)
        if let primaryAction = primaryAction {
            if #available(iOS 14.0, *) {
                setPrimaryAction(primaryAction)
            }
        }
    }
    
    @objc convenience init(frame: CGRect, handler:@escaping (() -> ())) {
        self.init(frame: frame)
        onTap = handler
        addTarget(self, action: #selector(performOnTap), for: .touchUpInside)
    }
    
    // MARK: API
    @objc func performOnTap() {
        if let tap = onTap {
            tap()
        }
    }
    
    @available(iOS 14.0, *)
    @objc func setPrimaryAction(_ action:UIAction) {
        self.addAction(action, for: .touchUpInside)
        
        if !action.title.isEmpty {
            self.buttonText = action.title
        }
    }
    
    func configureBackground(highlighted: Bool) {
        titleLabel.transform = highlighted ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
        titleLabel.textColor = highlighted ? .secondaryLabel : buttonColor
        titleLabel.configureFontWeight(highlighted ? .semibold : .light)
        dimBackground.alpha = highlighted ? 0.3 : 0.0
        dimBackground.layer.cornerRadius = highlighted ? dimBackground.boundsHeight/2.0 : 4.0
        dimBackground.transform = highlighted ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
    }
    
    func updateMenuIfVisible() {
        if #available(iOS 14.0, *) {
            self.contextMenuInteraction?.updateVisibleMenu { [unowned self] _ in
                return self.menu
            }
        }
    }
    
    @available(iOS 14.0, *)
    func proxyAction(_ action: UIAction, selected: Bool) -> UIAction {
        let proxy = UIAction(title: action.title,
                             image: action.image,
                             discoverabilityTitle: action.discoverabilityTitle,
                             attributes: action.attributes,
                             state: selected ? .on : .off) { proxy in
            guard let control = proxy.sender as? SSContextButton else { return }
            control.selectedIndex = control.items.firstIndex(of: action) ?? -1
            control.sendAction(action)
            control.sendActions(for: .primaryActionTriggered)
        }
        return proxy
    }
    
    @available(iOS 14.0, *)
    var menu: UIMenu {
        let selectedAction: UIAction?
        if showSelectedItem && selectedIndex >= 0 && selectedIndex < items.count {
            selectedAction = items[selectedIndex]
        } else {
            selectedAction = nil
        }
        return UIMenu(title: menuTitle ?? "", children: items.map {
            return proxyAction($0, selected: $0 == selectedAction)
        })
    }
}

// MARK: Context Interaction Delegate
@available(iOS 14.0, *)
extension SSContextButton {
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [unowned self] _ -> UIMenu? in
            self.menu
        }
    }
    
    func previewForMenuPresentation() -> UITargetedPreview {
        let previewTarget = UIPreviewTarget(container: titleLabel, center: titleLabel.center)
        let previewParameters = UIPreviewParameters()
        return UITargetedPreview(view: UIView(frame: titleLabel.frame), parameters: previewParameters, target: previewTarget)
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         previewForHighlightingMenuWithConfiguration config: UIContextMenuConfiguration) -> UITargetedPreview? {
        return previewForMenuPresentation()
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         previewForDismissingMenuWithConfiguration config: UIContextMenuConfiguration) -> UITargetedPreview? {
        return previewForMenuPresentation()
    }
    
    func animateBackgroundHighlight(_ animator: UIContextMenuInteractionAnimating?, highlighted: Bool) {
        if let animator = animator {
            animator.addAnimations {
                self.configureBackground(highlighted: highlighted)
            }
        } else {
            configureBackground(highlighted: highlighted)
        }
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         willDisplayMenuFor config: UIContextMenuConfiguration,
                                         animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: config, animator: animator)
        UIFeedbackGenerator.playFeedback(of: .styleLight)
        animateBackgroundHighlight(animator, highlighted: true)
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         willEndFor config: UIContextMenuConfiguration,
                                         animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willEndFor: config, animator: animator)
        animateBackgroundHighlight(animator, highlighted: false)
    }
}
