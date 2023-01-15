//
//  SSListItemPriceDataTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/19/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"

static NSString * _Nonnull const SS_ITEM_PRICE_DATA_CELL_ID = @"SSItemPriceDataCell";

typedef NS_ENUM(NSInteger, SSListItemPriceDataDisplayType)
{
    SSListItemPriceDataDisplayTypeBaseAmount,
    SSListItemPriceDataDisplayTypeSubtotalAmount,
    SSListItemPriceDataDisplayTypeTaxAmount,
    SSListItemPriceDataDisplayTypeTotalAmount,
    SSListItemPriceDataDisplayTypeWeight,
    SSListItemPriceDataDisplayTypeDiscount,
    SSListItemPriceDataDisplayTypeRecurring,
    SSListItemPriceDataDisplayTypeUnknown
};

@interface SSListItemPriceDataTableViewCell : SSBaseListItemEditingTableViewCell

@property (nonatomic) SSListItemPriceDataDisplayType type;
@property (nonatomic) BOOL textViewIsFirstResponder;

- (void)makePriceEntryTextViewFirstResponder;
- (void)presentCycleEditor;

@end
