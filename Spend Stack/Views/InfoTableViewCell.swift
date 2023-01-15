//
//  InfoTableViewCell.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 5/11/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

class InfoTableViewCell: UITableViewCell {

    // MARK: Public Properties
    
    static let CELL_ID = "SSInfoTableViewCell_CellID"
    let leadingImageView = UIImageView(frame: .zero)
    let mainLabel = SSLabel(textStyle: .subheadline)
    let subLabel = SSLabel(textStyle: .caption1)
    let trailingImageView = UIImageView(frame: .zero)
    
    //MARK: Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        trailingImageView.tintColor = .systemGray
        trailingImageView.isUserInteractionEnabled = true
        trailingImageView.addPointerInteraction(with: self)
        
        mainLabel.textColor = UIColor.ssMainFont()
        mainLabel.configureFontWeight(.bold)
        
        contentView.addSubviews([leadingImageView, mainLabel, subLabel, trailingImageView])
        
        applyConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(applyConstraints), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    // MARK: Table View API
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: Constraints
    
    @objc private func applyConstraints() {

        leadingImageView.snp.remakeConstraints { make in
            make.height.width.equalTo(24)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.centerY.equalTo(contentView.snp.centerY)
        }
        
        mainLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin)
            make.leading.equalTo(leadingImageView.snp.trailing).offset(SSLeftElementMargin)
            make.trailing.equalTo(trailingImageView.snp.leading).offset(SSRightElementMargin)
            make.bottom.equalTo(subLabel.snp.top).offset(SSBottomElementMargin)
        }
        
        subLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(mainLabel)
            make.bottom.equalTo(contentView.snp.bottom).offset(SSBottomBigElementMargin)
        }
        
        trailingImageView.snp.remakeConstraints { make in
            make.height.width.equalTo(24)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.centerY.equalTo(contentView.snp.centerY)
        }
    }
    
    // MARK: Pointer
    override func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let interactionView = interaction.view else { return nil }
        let lift = UIPointerEffect.lift(UITargetedPreview(view: interactionView))
        return UIPointerStyle(effect: lift, shape: nil)
    }

    
    // MARK: Public Functions
    
    func setLeadingText(_ text:String? = nil, subText:String? = nil, leadingImage:UIImage? = nil, trailingImage:UIImage? = nil) {
        mainLabel.text = text
        subLabel.text = subText
        leadingImageView.image = leadingImage
        trailingImageView.image = trailingImage
        
        if leadingImageView.image == nil {
            leadingImageView.snp.remakeConstraints { make in
                make.height.width.equalTo(0)
                make.centerY.equalTo(contentView.snp.centerY)
                make.leading.equalTo(contentView.snp.leading)
            }
            
            // Nudge over the main label
            mainLabel.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin)
                make.leading.equalTo(contentView.snp.leadingMargin)
                make.trailing.equalTo(trailingImageView.snp.leading).offset(SSRightElementMargin)
                make.bottom.equalTo(subLabel.snp.top).offset(SSBottomElementMargin)
            }
        }
    }
}
