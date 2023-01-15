//
//  SSListItemTagTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"
@class SSTagSelectionViewModel;

static NSString * _Nonnull const SS_ITEM_TAG_CELL_ID = @"SSItemTagCell";

@interface SSListItemTagTableViewCell : SSBaseListItemEditingTableViewCell

@property (nonatomic, getter=shouldUseCheckmarkForSelection) BOOL useCheckmarkForSelection;
// This cell was originally built for the list item controller, but it's since been
// Reused for the tags controller too. This method handles the tags controller.
- (void)setDataForTag:(SSTagSelectionViewModel * _Nonnull)tag;

@end
