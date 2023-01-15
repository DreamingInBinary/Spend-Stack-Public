//
//  UICollectionView+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/14/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (Utils)

- (NSArray <NSIndexPath *> * _Nonnull)indexPathsForElementsInRect:(CGRect)rect;

@end
