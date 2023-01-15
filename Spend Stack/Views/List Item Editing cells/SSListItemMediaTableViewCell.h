//
//  SSListItemMediaTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/23/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"
#import "SSListItemImageView.h"
#import "SSListItemAddAttachmentTableViewCell.h"

static NSString * _Nonnull const SS_ITEM_MEDIA_CELL_ID = @"SSItemMediaCell";

@interface SSListItemMediaTableViewCell : SSBaseListItemEditingTableViewCell

@property (nonatomic, getter=isInErrorState) BOOL errorState;
@property (nonatomic) AttachmentViewMode viewMode;
@property (strong, nonatomic, readonly, nonnull) SSListItemImageView *mediaImageView;

@end
