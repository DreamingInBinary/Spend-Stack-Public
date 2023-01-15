//
//  UIImageView+SSUtils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (SSUtils)

+ (CGFloat)squareIconImageViewSize;
+ (UIImageView * _Nonnull)sqaureIconImageView;
- (void)addLoadingShimmer;
- (void)removeLoadingShimmer;

@end
