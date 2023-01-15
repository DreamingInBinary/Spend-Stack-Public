//
//  SSListCollectionViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/9/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(14.0))
@interface SSListCollectionViewCell : UICollectionViewListCell

- (void)setData:(SSList * _Nonnull)data;
- (UIDragPreview * _Nonnull)dragPreviewRepresentation;
- (void)updateColors:(BOOL)compact;

@end

NS_ASSUME_NONNULL_END
