//
//  SSListItemBasicTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/13/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSListItemCheckBox.h"
@class TaxUtility;

static NSString * _Nonnull const SS_LIST_ITEM_BASIC_CELL_ID = @"SSListItemBasicTableViewCell";
static NSString * _Nonnull const SS_PARENT_TABLE_VIEW_IS_EDIT_MODE_CHANGED = @"SSParentTableViewEditModeChanged";

@interface SSListItemBasicTableViewCell : UITableViewCell

@property (strong, nonatomic, readonly, nonnull) UIView *tagView;
@property (strong, nonatomic, readonly, nonnull) SSListItemCheckBox *checkBoxView;
@property (strong, nonatomic, readonly, nonnull) SSLabel *listItemNameLabel;
@property (strong, nonatomic, readonly, nonnull) SSLabel *listItemTotalPriceLabel;
@property (strong, nonatomic, readonly, nonnull) UIView *dividerView;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;
@property (copy) void (^ _Nullable onCheckToggled)(NSString * _Nonnull listItemID, BOOL isChecked);

- (void)setConstraints;
- (void)setData:(SSListItem * _Nonnull)item taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo withList:(SSList * _Nonnull)list;
- (void)reloadTagViewWithTag:(SSListTag * _Nullable)tag;
- (UIDragPreview * _Nonnull)dragPreviewRepresentation;

@end
