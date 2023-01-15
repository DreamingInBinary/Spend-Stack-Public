//
//  SSListTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 8/6/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const _Nonnull VIEW_LISTS_VC_CELL_ID = @"listCell";

@interface SSListTableViewCell : UITableViewCell

- (void)setData:(SSList * _Nonnull)data;
- (UIDragPreview * _Nonnull)dragPreviewRepresentation;
- (void)updateColors:(BOOL)compact;

@end
