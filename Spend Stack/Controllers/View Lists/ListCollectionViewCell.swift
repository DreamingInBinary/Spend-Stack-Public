//
//  ListCollectionViewCell.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 7/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

// A few reasons why I can't use this yet:
// I can't get a trailing label centered.
// Bugs: If the trailing label is big, it just hides.

// Declare a custom key for a custom `list` property.
@available(iOS 14.0, *)
fileprivate extension UIConfigurationStateCustomKey {
    static let list = UIConfigurationStateCustomKey("com.dreamingInBinary.listCell.item")
}

// Declare an extension on the cell state struct to provide a typed property for this custom state.
@available(iOS 14.0, *)
private extension UICellConfigurationState {
    var list: SSList? {
        set { self[.list] = newValue }
        get { return self[.list] as? SSList }
    }
}

@available(iOS 14.0, *)
private class ListItemCell: UICollectionViewListCell {
    private var list: SSList? = nil
    
    func updateWithList(_ newList: SSList) {
        guard list != newList else { return }
        list = newList
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.list = self.list
        return state
    }
}

@available(iOS 14.0, *)
private class ListCell: ListItemCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    private let countLabel: SSLabel = {
        let lbl = SSLabel(textStyle: .body)
        lbl.textColor = .ssSecondary()
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        return lbl
    }()
    
    private let detailImagesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = SSSpacingMargin
        
        let symbolConfig = UIImage.SymbolConfiguration(weight: .light)
        let lockImg = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig)
        let shareImg = UIImage(systemName: "person.2.fill", withConfiguration: symbolConfig)
        let spacerImg = UIImage(systemName: "trash")
        
        [lockImg, shareImg, spacerImg].forEach {
            let imgVw = UIImageView(image: $0)
            imgVw.contentMode = .scaleAspectFit
            imgVw.tintColor = .ssSecondary()
            
            if($0 == spacerImg) {
                imgVw.setContentHuggingPriority(.defaultLow, for: .horizontal)
                imgVw.alpha = 0
                imgVw.isAccessibilityElement = false
            } else {
                imgVw.setContentHuggingPriority(.required, for: .horizontal)
            }
            
            stack.addArrangedSubview(imgVw)
        }
        
        return stack
    }()
    
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ssMuted()
        view.isAccessibilityElement = false
        return view
    }()

    private var hasCreatedConstraints: Bool = false
    
    private func setupViewsIfNeeded() {
        // We only need to do anything if we haven't already setup the views and created constraints.
        guard hasCreatedConstraints == false else { return }
        
        contentView.addSubview(listContentView)
        contentView.addSubview(detailImagesStack)
        contentView.addSubview(countLabel)
        contentView.addSubview(dividerView)
        
        listContentView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(SSTopElementMargin)
            make.bottom.equalTo(countLabel.snp.top)
            make.leading.equalTo(contentView.snp.leading)
            make.trailing.equalTo(contentView.snp.trailing)
        }
        
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.bottom.equalTo(dividerView.snp.top).offset(SSBottomBigElementMargin)
            make.height.equalTo(countLabel.snp.height)
        }
        
        detailImagesStack.snp.makeConstraints { make in
            make.leading.equalTo(countLabel.snp.trailing).offset(SSLeftElementMargin)
            make.trailing.equalTo(listContentView.snp.trailing)
            make.bottom.equalTo(countLabel.snp.bottom)
        }
        
        dividerView.snp.makeConstraints { make in
            make.bottom.equalTo(contentView.snp.bottom)
            make.left.equalTo(contentView.snp.left)
            make.right.equalTo(contentView.snp.right)
            make.height.equalTo(Int.dividerHeight())
        }
        
        selectedBackgroundView = self.ssSelectionView()
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        guard let list = state.list else { return }
        
        // Configure the list content configuration and apply that to the list content view.
        var content = defaultListContentConfiguration().updated(for: state)
        content.text = list.name
        content.secondaryText = "$124,124,230.23"
        
        let title2Font = UIFont.preferredFont(forTextStyle: .title3)
        let title2Size = title2Font.pointSize
        
        content.textProperties.color = .ssMainFont()
        content.textProperties.font = UIFont.systemFont(ofSize: title2Size, weight: .bold)
        
        content.secondaryTextProperties.color = .ssMainFont()
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: title2Size, weight: .bold)

        listContentView.configuration = content
        
        // Custom views
        switch list.itemCount {
        case 0:
            countLabel.text = ss_Localized("listItem.cell.zero")
        case 1:
            countLabel.text = ss_Localized("listItem.cell.one")
        default:
            let localizedCount = ss_Localized("listItem.cell.plural")
            countLabel.text = String.localizedStringWithFormat(localizedCount, list.itemCount)
        }
        
        detailImagesStack.arrangedSubviews.first?.isHidden = !list.isLocked
        detailImagesStack.arrangedSubviews[1].isHidden = list.objCKRecord.share == nil
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBackgroundView?.frame = contentView.frame.insetBy(dx: 6, dy: 6)
        selectedBackgroundView?.layer.cornerRadius = SSSpacingMargin
    }
}

