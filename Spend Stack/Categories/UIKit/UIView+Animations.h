//
//  UIView+Animations.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/18/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Animations)

@property (copy) void (^ _Nullable onAnimationFinished)(void);

- (void)bobble;
- (void)bobbleBigToSmall;
- (void)bobbleBigToSmallSlow;
- (void)bumpRightToLeft;
- (void)dimInFromTapAnimationWithHighlight:(CGFloat)padding;
- (void)dimInFromTapAnimationWithHighlightCenteringToParent:(CGFloat)padding;

@end
