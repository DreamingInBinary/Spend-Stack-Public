//
//  SSBaseListItemEditingTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSBaseListItemEditingTableViewCell : UITableViewCell

@property (strong, nonatomic, nonnull, readonly) UIView *dividerView;
@property (weak, nonatomic, nullable) SSListItem *listItem;
@property (weak, nonatomic, nullable) SSTaxRateInfo *taxRateInfo;
@property (strong, nonatomic, nonnull) NSString *currencyID;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;
@property (weak, nonatomic, nullable) SSList *list;

- (UITableView * _Nullable)containingTableView;
- (void)setConstraints;
- (void)setData:(SSListItem * _Nonnull)item list:(SSList * _Nonnull)list;

@end
