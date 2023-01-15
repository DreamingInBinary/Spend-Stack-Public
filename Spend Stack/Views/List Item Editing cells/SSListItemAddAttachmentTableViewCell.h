//
//  SSListItemAddMediaTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseListItemEditingTableViewCell.h"

typedef NS_ENUM(NSUInteger, AttachmentViewMode) {
    AttachmentViewModeImage,
    AttachmentViewModeLink
};

static NSString * _Nonnull const SS_ITEM_ADD_MEDIA_CELL_ID = @"SSItemAddMediaCell";

@interface SSListItemAddAttachmentTableViewCell : SSBaseListItemEditingTableViewCell

@property (strong, nonatomic, nullable) UIMenu *menu API_AVAILABLE(ios(14.0));
@property (strong, nonatomic, nullable, readonly) UIButton *menuButton;
@property (nonatomic) AttachmentViewMode viewMode;

@end
