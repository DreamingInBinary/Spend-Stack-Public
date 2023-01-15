//
//  UIView+SSShimmer.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/8/18.
//  Copyright © 2018 Buffer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SSShimmer) <CAAnimationDelegate>

@property (nonatomic) BOOL isShimmering;
@property (strong, nonatomic, readonly, nonnull) CAGradientLayer *gradient;
@property (strong, nonatomic, readonly, nonnull) CABasicAnimation *shimmerAnimation;

- (void)startShimmering;
- (void)startShimmeringWithRepitions:(NSInteger)reps;
- (void)endShimmering;

@end

NS_ASSUME_NONNULL_END
