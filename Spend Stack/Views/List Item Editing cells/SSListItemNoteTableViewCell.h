//
//  SSListItemNoteTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"

static NSString * _Nonnull const SS_ITEM_NOTE_CELL_ID = @"SSItemNoteCell";

@interface SSListItemNoteTableViewCell : SSBaseListItemEditingTableViewCell

- (void)markTextViewAsFirstResponder;

@end
