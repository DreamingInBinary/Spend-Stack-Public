//
//  BasicTableViewCell.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 3/12/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

class BasicTableViewCell: UITableViewCell {

    // MARK: Public Properties
    
    static let CELL_ID = "SSBasicTableViewCell_CellID"
    var hideDivider:Bool = true {
        didSet {
            dividerView.isHidden = hideDivider
        }
    }
    
    // MARK: Private Properties
    
    private let mainLabel = SSLabel(textStyle: .headline)
    private let trailingLabel = SSLabel(textStyle: .subheadline)
    private let dividerView = UIView(frame: .zero)
    
    //MARK: Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        mainLabel.textColor = UIColor.ssMainFont()
        mainLabel.configureFontWeight(.bold)
        trailingLabel.textColor = UIColor.ssSecondary()
        trailingLabel.configureFontWeight(.bold)
        dividerView.backgroundColor = UIColor.ssMuted()
        
        contentView.addSubviews([mainLabel, trailingLabel, dividerView])
        selectedBackgroundView = ssSelectionView()
        
        applyConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(applyConstraints), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard isEditing == false else { return }
        selectedBackgroundView?.layer.cornerRadius = SSSpacingMargin
        selectedBackgroundView?.frame = contentView.frame.insetBy(dx: 6, dy: 6)
    }
    
    // MARK: Table View API
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: Constraints
    
    @objc private func applyConstraints() {
        let bigFonts = SSCitizenship.accessibilityFontsEnabled()
        let isRegularHSize = contentView.traitCollection.horizontalSizeClass == .regular
        
        if bigFonts {
            trailingLabel.textAlignment = .natural
            
            mainLabel.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin)
                make.leading.equalTo(dividerView.snp.leading)
                make.trailingMargin.equalTo(contentView.snp.trailingMargin)
            }
            
            trailingLabel.snp.remakeConstraints { make in
                make.top.equalTo(mainLabel.snp.bottom).offset(SSTopBigElementMargin)
                make.leading.equalTo(dividerView.snp.leading)
                make.trailingMargin.equalTo(contentView.snp.trailingMargin)
                make.bottom.equalTo(dividerView.snp.top).offset(SSBottomBigElementMargin)
            }
        } else {
            trailingLabel.textAlignment = .right
            
            mainLabel.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin)
                make.leading.equalTo(isRegularHSize ? dividerView.snp.leading : contentView.snp.leadingMargin)
                make.bottom.equalTo(dividerView.snp.top).offset(SSBottomBigElementMargin)
                make.width.equalTo(contentView.snp.width).multipliedBy(0.75)
            }
            
            trailingLabel.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin)
                make.trailing.equalTo(isRegularHSize ? dividerView.snp.trailing : contentView.snp.trailingMargin)
                make.bottom.equalTo(dividerView.snp.top).offset(SSBottomBigElementMargin)
                make.width.equalTo(contentView.snp.width).multipliedBy(0.15)
            }
        }
        
        dividerView.snp.remakeConstraints { make in
            make.height.equalTo(0.5)
            make.centerX.equalTo(contentView.snp.centerX)
            make.bottom.equalTo(contentView.snp.bottom)
            if isRegularHSize {
                make.width.equalTo(contentView.readableContentGuide.snp.width)
            } else {
                make.width.equalTo(contentView.snp.width)
            }
        }
    }
    
    // MARK: Public Functions
    
    func setLeadingText(_ text:String?, trailingText:String?) {
        mainLabel.text = text
        trailingLabel.text = trailingText
    }
}
