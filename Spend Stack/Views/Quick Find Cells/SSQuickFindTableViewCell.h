//
//  SSQuickFindTableViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/5/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSQuickFindResult;

static NSString * _Nonnull const SS_QUICK_FIND_CELL_ID = @"SSQuickFindTableViewCell";

@interface SSQuickFindTableViewCell : UITableViewCell

- (void)setData:(SSQuickFindResult * _Nonnull)result;

@end
