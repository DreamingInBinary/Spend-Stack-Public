//
//  SSListItemSegmentAttachmentTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"
#import "SSListItemAddAttachmentTableViewCell.h"

static NSString * _Nonnull const SS_ITEM_ENTRY_SEGMENT_ATTACHMENT_CELL_ID = @"SSItemEntrySegmentAttachmentSegmentCell";

@interface SSListItemSegmentAttachmentTableViewCell : SSBaseListItemEditingTableViewCell

- (void)setActiveMediaSegmentAtIndex:(NSInteger)index;

@end
