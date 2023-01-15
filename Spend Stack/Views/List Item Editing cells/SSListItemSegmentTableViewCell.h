//
//  SSListItemSegmentTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"

static NSString * _Nonnull const SS_ITEM_ENTRY_SEGMENT_CELL_ID = @"SSItemEntrySegmentCell";

@interface SSListItemSegmentTableViewCell : SSBaseListItemEditingTableViewCell

- (void)setActivePricingSegmentAtIndex:(NSInteger)index;

@end
