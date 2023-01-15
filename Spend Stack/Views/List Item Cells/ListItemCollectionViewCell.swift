//
//  ListItemCollectionViewCell.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 1/6/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import SnapKit

class ListItemCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "SSListItemCollectionViewCell"
    
    private let tagView = UIView(frame: .zero)
    private let checkBoxView = SSListItemCheckBox(frame: .zero)
    private let listItemNameLabel = SSLabel(textStyle: .body)
    private let listItemTotalPriceLabel = SSLabel(textStyle: .body)
    private let dividerView = UIView(frame: .zero)

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBackgroundView?.layer.cornerRadius = SSSpacingMargin
        selectedBackgroundView?.frame = contentView.frame.insetBy(dx: 6, dy: 6)
    }
    
    // MARK: Setup and Constraints
    private func configure() {
        contentView.addSubviews([tagView, checkBoxView, listItemNameLabel, listItemTotalPriceLabel, dividerView])
        
        listItemNameLabel.numberOfLines = 4
        dividerView.backgroundColor = UIColor.ssMuted()
        selectedBackgroundView = UIView(frame: contentView.bounds)
        selectedBackgroundView?.backgroundColor = UIColor.ssSelectedBackground()
        setConstraints()
    }
    
    private func setConstraints() {
        let regularTraitCollection = traitCollection.horizontalSizeClass == .regular
        let accessibilityFontsOn = SSCitizenship.accessibilityFontsEnabled()
        listItemTotalPriceLabel.textAlignment = accessibilityFontsOn ? NSTextAlignment.natural : NSTextAlignment.right
        
        if accessibilityFontsOn {
            
        } else {
            tagView.snp.remakeConstraints { make in
                if UIDevice.current.userInterfaceIdiom == .pad {
                    make.right.equalTo(contentView.snp.leftMargin).offset(10+SSRightJumboElementMargin)
                    make.height.equalTo(10)
                    if (tagView.layer.cornerRadius != 5) { tagView.layer.cornerRadius = 5 }
                } else {
                    make.left.equalTo(contentView.snp.left).offset(-5)
                    make.height.equalTo(38)
                    if (tagView.layer.cornerRadius != 4) { tagView.layer.cornerRadius = 4 }
                }
                
                make.centerY.equalTo(contentView.snp.centerY)
                make.width.equalTo(10)
            }
            
            checkBoxView.snp.remakeConstraints { make in
                make.leading.equalTo(contentView.snp.leadingMargin).offset(SSRightBigElementMargin);
                make.centerY.equalTo(contentView.snp.centerY);
                make.height.equalTo(contentView.snp.height);
                make.width.greaterThanOrEqualTo(72);
            }
            
            listItemNameLabel.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin);
                make.left.equalTo(checkBoxView.checkbox.snp.right).offset(SSLeftElementMargin);
                make.bottom.equalTo(dividerView.snp.top).offset(SSBottomBigElementMargin);
                make.width.lessThanOrEqualTo(dividerView.snp.width).multipliedBy(0.60);
            }
            
            listItemTotalPriceLabel.snp.remakeConstraints { make in
                make.top.equalTo(contentView.snp.top).offset(SSTopBigElementMargin);
                make.bottom.equalTo(dividerView.snp.top).offset(SSBottomBigElementMargin);
                make.width.lessThanOrEqualTo(dividerView.snp.width).multipliedBy(0.38).priority(.high)
                make.trailing.equalTo(contentView.snp.trailingMargin);
            }
        }
        
        let dividerHeight = UICollectionViewCell.preferredDividerHeight()
        if regularTraitCollection {
            dividerView.snp.remakeConstraints { make in
                make.height.equalTo(dividerHeight);
                make.left.equalTo(contentView.readableContentGuide.snp.left);
                make.right.equalTo(contentView.readableContentGuide.snp.right);
                make.bottom.equalTo(contentView.snp.bottom);
            }
        } else {
            dividerView.snp.remakeConstraints { make in
                make.height.equalTo(dividerHeight);
                make.left.equalTo(contentView.safeAreaLayoutGuide.snp.left);
                make.right.equalTo(contentView.safeAreaLayoutGuide.snp.right);
                make.bottom.equalTo(contentView.snp.bottom);
            }
        }
        
        /*
         BOOL isRegularEnv = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
         BOOL shouldConsiderRegularEnvForTag = NO;
         UISplitViewController *rootSplitVC = (UISplitViewController *)self.window.rootViewController;
         __kindof UIViewController *baseDetailView = nil;
         
         if ([rootSplitVC isKindOfClass:[UISplitViewController class]])
         {
             baseDetailView = [rootSplitVC ss_detailViewController];
         }
         
         if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
         {
             // Work around size class limitations on iPad :-/
             shouldConsiderRegularEnvForTag = [baseDetailView shouldConsideriPadFrameRegular];
         }
         else if (baseDetailView)
         {
             shouldConsiderRegularEnvForTag = [baseDetailView shouldConsideriPhoneFrameRegular];
         }
         
         // Set alignments based off of text size
         self.listItemTotalPriceLabel.textAlignment = [SSCitizenship accessibilityFontsEnabled] ? NSTextAlignmentNatural : NSTextAlignmentRight;
         
         if ([SSCitizenship accessibilityFontsEnabled])
         {
             if (self.tagView.layer.cornerRadius != 19.0f) self.tagView.layer.cornerRadius = 19.0f;
             
             [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.left.equalTo(self.contentView.mas_leftMargin);
                 make.top.equalTo(self.contentView.mas_topMargin).with.offset(SSTopElementMargin);
                 make.width.equalTo(@38);
                 make.height.equalTo(@38);
             }];
             
             [self.checkBoxView mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.leading.equalTo(self.contentView.mas_leadingMargin).with.offset(SSRightBigElementMargin);;
                 if (self.tagView.isHidden)
                 {
                     make.top.equalTo(self.contentView.mas_topMargin);
                 }
                 else
                 {
                     make.top.equalTo(self.tagView.mas_bottom).with.offset(SSTopElementMargin);
                 }
                 
                 make.height.and.width.equalTo(@88);
             }];
             
             [self toggleCheckboxConstraints:self.checkBoxView.isChecked];
             
             [self.listItemNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.top.equalTo(self.checkBoxView.checkbox.mas_bottom).with.offset(SSTopElementMargin);
                 make.left.equalTo(self.tagView.mas_left);
                 make.right.equalTo(self.contentView.mas_rightMargin);
             }];
             
             [self.listItemTotalPriceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.top.equalTo(self.listItemNameLabel.mas_bottom).with.offset(SSTopElementMargin);
                 make.left.equalTo(self.tagView.mas_left);
                 make.right.equalTo(self.contentView.mas_rightMargin);
                 make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
             }];
         }
         else
         {
             [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
                 if (shouldConsiderRegularEnvForTag)
                 {
                     make.right.equalTo(self.contentView.mas_leftMargin).with.offset(+(10 + SSRightJumboElementMargin));
                     make.height.equalTo(@10);
                     if (self.tagView.layer.cornerRadius != 5.0f) self.tagView.layer.cornerRadius = 5.0f;
                 }
                 else
                 {
                     make.left.equalTo(self.contentView.mas_left).with.offset(-5);
                     make.height.equalTo(@38);
                     if (self.tagView.layer.cornerRadius != 4.0f) self.tagView.layer.cornerRadius = 4.0f;
                 }
                 
                 make.centerY.equalTo(self.contentView.mas_centerY);
                 make.width.equalTo(@10);
             }];
             
             [self.checkBoxView mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.leading.equalTo(self.contentView.mas_leadingMargin).with.offset(SSRightBigElementMargin);
                 make.centerY.equalTo(self.contentView.mas_centerY);
                 make.height.equalTo(self.contentView.mas_height);
                 make.width.greaterThanOrEqualTo(@72);
             }];
             
             [self.listItemNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
                 make.left.equalTo(self.checkBoxView.checkbox.mas_right).with.offset(SSLeftElementMargin);
                 make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
                 make.width.lessThanOrEqualTo(self.dividerView.mas_width).multipliedBy(.60f);
             }];
             
             [self.listItemTotalPriceLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                 make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
                 make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
                 make.width.lessThanOrEqualTo(self.dividerView.mas_width).multipliedBy(.38f).with.priorityHigh();
                 make.trailing.equalTo(self.contentView.mas_trailingMargin);
             }];
         }
         
         if (isRegularEnv)
         {
             [self.dividerView mas_remakeConstraints:[self constraintsForReadableWidthDividerView:self.dividerView]];
         }
         else
         {
             [self.dividerView mas_remakeConstraints:[self constraintsForDividerView:self.dividerView]];
         }
         */
    }
    
    // MARK: Data Population
    func setData(with listItem:SSListItem, taxInfo:SSTaxRateInfo, list:SSList) {
//        if let listTag = listItem.tag {
//            tagView.isHidden = false
//            tagView.backgroundColor = SSTag.rawColor(fromColor: listTag.color)
//        } else {
//            tagView.isHidden = true
//            tagView.backgroundColor = contentView.backgroundColor
//        }
//        
//        listItemNameLabel.text = listItem.title
//        
//        let modifierData = listItem.modifiderDataString()
//        if modifierData.count > 0 {
//            let listItemNameText = "\(listItem.title) \(modifierData)"
//            let attributes: [NSAttributedString.Key: Any] = [
//                .font: UIFont.preferredFont(forTextStyle: .caption1),
//                .foregroundColor: UIColor.ssSecondary(),
//            ]
//            let attibutedString = NSMutableAttributedString(string: listItemNameText)
//            let modifierRange = NSRange(listItemNameText.range(of: modifierData)!, in:listItemNameText)
//            attibutedString.setAttributes(attributes, range: modifierRange)
//            listItemNameLabel.attributedText = attibutedString
//        }
        
        //let amount = ""//listItem.calcTaxedAmount(taxInfo).stringValue
        //listItemTotalPriceLabel.text = TaxUtility.sharedInstance().guranteedCurrencyString(amount)
        
        checkBoxView.isCheckHandlerEnabled = list.isShowingCheckboxes
        /*

         
         self.checkBoxView.checkHandlerEnabled = list.showingCheckboxes;
         [self toggleCheckboxConstraints:list.showingCheckboxes];
         
         if (list.showingCheckboxes)
         {
             __weak typeof(self) weakSelf = self;
             self.checkBoxView.onCheck = ^(BOOL isChecked) {
                 [weakSelf toggleCheckedForItem:item taxInfo:taxInfo list:list isChecked:isChecked];
             };
             [self.checkBoxView toggleChecked:item.checkedOff];
         }
         */
    }
}
