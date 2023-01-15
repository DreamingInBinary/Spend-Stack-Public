//
//  SSListItemDetailSectionHeaderView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * _Nonnull const SS_ITEM_ENTRY_SECTION_HEADER_ID = @"SSItemEntrySectionHeader";

typedef NS_ENUM(NSUInteger, SSListItemDetailSectionHeaderViewTapScenario) {
    SSListItemDetailSectionHeaderViewTapScenarioUnset,
    SSListItemDetailSectionHeaderViewTapScenarioToggleDiscount,
    SSListItemDetailSectionHeaderViewTapScenarioToggleMedia,
    SSListItemDetailSectionHeaderViewTapScenarioToggleMediaLink
};

@protocol SSListItemDetailSectionHeaderViewDelegate <NSObject>

// In some situations, like when toggling media attachments, we want to change
// The header text without the jank of reloading the whole section. That's what
// This delegate is intended for.
- (NSString * _Nonnull)buttonText;
- (UIColor * _Nonnull)buttonTextColor;
- (SSListItemDetailSectionHeaderViewTapScenario)tapScenario;

@end
 
@interface SSListItemDetailSectionHeaderView : UITableViewHeaderFooterView

@property (weak, nonatomic, nullable) id<SSListItemDetailSectionHeaderViewDelegate> delegate;
@property (strong, nonatomic, nullable) NSString *titleString;
@property (strong, nonatomic, nullable) NSString *buttonString;
@property (strong, nonatomic, nullable) UIColor *buttonTextColor;
@property (nonatomic) SSListItemDetailSectionHeaderViewTapScenario tapScenario;

- (CGFloat)estimatedHeightForHeaderInView:(UIView * _Nullable)view;

@end
