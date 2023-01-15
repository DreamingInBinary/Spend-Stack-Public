//
//  IconTableViewCell.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 5/12/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit

class IconTableViewCell: UITableViewCell {
    
    // MARK: Public Properties
    
    static let CELL_ID = "SSIconTableViewCell_CellID"
    let leadingImageView = UIImageView(frame: .zero)
    let mainLabel = SSLabel(textStyle: .subheadline)
    let tappableDetailLabel = SSLabel(textStyle: .caption1)
    let trailingCheckmarkImageView = UIImageView(frame: .zero)
    
    //MARK: Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        leadingImageView.clipsToBounds = true
        leadingImageView.accessibilityTraits = .button
        leadingImageView.layer.cornerCurve = .continuous
        leadingImageView.layer.cornerRadius = SSSpacingMargin
        leadingImageView.isUserInteractionEnabled = true
        
        trailingCheckmarkImageView.tintColor = UIColor.ssPrimary()
        trailingCheckmarkImageView.clipsToBounds = true
        trailingCheckmarkImageView.layer.cornerRadius = 12
        trailingCheckmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        
        mainLabel.textColor = UIColor.ssMainFont()
        mainLabel.configureFontWeight(.bold)
        
        tappableDetailLabel.textColor = UIColor.ssPrimary()
        tappableDetailLabel.accessibilityTraits = .button
        tappableDetailLabel.configureFontWeight(.medium)
        tappableDetailLabel.isUserInteractionEnabled = true
        tappableDetailLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        // Gestures for images
        let tapHDPreview = UITapGestureRecognizer(target: self, action: #selector(openHDPreview))
        leadingImageView.addGestureRecognizer(tapHDPreview)
        
        let tapTwitter = UITapGestureRecognizer(target: self, action: #selector(openTwitterHandleForAuthor))
        tappableDetailLabel.addGestureRecognizer(tapTwitter)
        
        leadingImageView.addPointerInteraction(with: self)
        tappableDetailLabel.addPointerInteraction(with: self)
        
        contentView.addSubviews([leadingImageView, mainLabel, tappableDetailLabel, trailingCheckmarkImageView])
        
        applyConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(applyConstraints), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Table View Cell API
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: Constraints
    
    @objc private func applyConstraints() {

        leadingImageView.snp.remakeConstraints { make in
            make.height.width.equalTo(44)
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.centerY.equalTo(contentView.snp.centerY)
        }
        
        mainLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin)
            make.leading.equalTo(leadingImageView.snp.trailing).offset(14)
            make.trailing.equalTo(trailingCheckmarkImageView.snp.leading).offset(SSRightElementMargin)
            make.bottom.equalTo(tappableDetailLabel.snp.top).offset(SSBottomElementMargin)
        }
        
        tappableDetailLabel.snp.remakeConstraints { make in
            make.leading.equalTo(mainLabel)
            make.bottom.equalTo(contentView.snp.bottom).offset(SSBottomBigElementMargin)
        }
        
        trailingCheckmarkImageView.snp.remakeConstraints { make in
            make.height.width.equalTo(24)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.centerY.equalTo(contentView.snp.centerY)
        }
    }
    
    // MARK: Pointer
    
    override func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let interactionView = interaction.view else { return nil }
        
        if let lbl = interactionView as? SSLabel {
            let params = lbl.paremetersHuggingText()
            let textRect = CGRect(x: -6, y: -6, width: params.visiblePath?.bounds.size.width ?? 0, height: params.visiblePath?.bounds.size.height ?? 0)
            params.visiblePath = UIBezierPath(roundedRect: textRect, cornerRadius: SSSpacingMargin)
            let preview = UITargetedPreview(view: lbl, parameters: params)
            let hover = UIPointerEffect.hover(preview, prefersScaledContent: true)
            return UIPointerStyle(effect: hover, shape: nil)
        }
        
        if let img = interactionView as? UIImageView {
            let lift = UIPointerEffect.lift(UITargetedPreview(view: img))
            return UIPointerStyle(effect: lift, shape: nil)
        }
        
        return nil
    }

    // MARK: Private Functions
    
    @objc func openHDPreview() {
        guard let iconVC = self.closestViewController() as? ChangeIconViewController else { return }
        iconVC.presentingHDImageView = leadingImageView
        iconVC.presentHDPreview()
    }
    
    @objc func openTwitterHandleForAuthor() {
        let twitterHandle:String = tappableDetailLabel.text ?? ""
        UIFeedbackGenerator.playFeedback(of: .styleLight)
        tappableDetailLabel.onAnimationFinished = {
            TwitterLinkOpener.openTwitterHandle(twitterHandle)
        }
        tappableDetailLabel.dimInFromTapAnimation(withHighlight: SSSpacingBigMargin)
    }
    
    // MARK: Public Functions
    
    func setData(_ iconName:String, iconDesigner:String, appIconImage:UIImage, checked:Bool = false) {
        mainLabel.text = iconName
        tappableDetailLabel.text = iconDesigner
        leadingImageView.image = appIconImage
        trailingCheckmarkImageView.isHidden = !checked
    }
}

