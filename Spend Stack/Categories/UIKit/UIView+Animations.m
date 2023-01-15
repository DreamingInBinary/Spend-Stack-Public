//
//  UIView+Animations.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/18/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIView+Animations.h"
#import "SSConstants.h"
#import <objc/runtime.h>

static const void *AnimationCompletionBlockKey = &AnimationCompletionBlockKey;

@implementation UIView (Animations)

#pragma mark - Properties

- (void)setOnAnimationFinished:(void (^)(void))onAnimationFinished
{
    objc_setAssociatedObject(self, AnimationCompletionBlockKey, onAnimationFinished, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(void))onAnimationFinished
{
    return objc_getAssociatedObject(self, AnimationCompletionBlockKey);
}

#pragma mark - Animations

- (void)bobble
{
    [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
        self.transform = CGAffineTransformMakeScale(0.90f, 0.90f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished && self.onAnimationFinished) {
                self.onAnimationFinished();
            }
        }];
    }];
}

- (void)bobbleBigToSmall
{
    [self bobbleBigToWithDuration:SSFasterThanFastestAnimationDuration];
}

- (void)bobbleBigToSmallSlow
{
    [self bobbleBigToWithDuration:1.0f];
}

- (void)bobbleBigToWithDuration:(CGFloat)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformMakeScale(1.10f, 1.10f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished && self.onAnimationFinished) {
                self.onAnimationFinished();
            }
        }];
    }];
}

- (void)bumpRightToLeft
{
    NSInteger startingX = self.ss_x;
    
    [UIView animateWithDuration:SSFasterThanFastestAnimationDuration delay:0.0f usingSpringWithDamping:.90f initialSpringVelocity:0.85f options:UIViewAnimationOptionCurveLinear animations:^{
        self.ss_x += 10;
    } completion:^(BOOL finished) {
        if (finished == NO) return;
        [UIView animateWithDuration:SSFasterThanFastestAnimationDuration delay:0.0f usingSpringWithDamping:.90f initialSpringVelocity:0.85f options:UIViewAnimationOptionCurveLinear animations:^{
            self.ss_x = startingX;
        } completion:^(BOOL finished) {
            if (finished && self.onAnimationFinished) {
                self.onAnimationFinished();
            }
        }];
    }];
}

- (void)dimInFromTapAnimationWithHighlight:(CGFloat)padding
{
    [self dimInFromTapAnimationWithCentering:NO padding:padding];
}

- (void)dimInFromTapAnimationWithHighlightCenteringToParent:(CGFloat)padding
{
    [self dimInFromTapAnimationWithCentering:YES padding:padding];
}

#pragma mark - Private Methods

- (void)dimInFromTapAnimationWithCentering:(BOOL)shouldCenter padding:(CGFloat)padding
{
    UIView *tapDim = [UIView new];
    tapDim.backgroundColor = [UIColor ssTextPlaceholderColor];
    tapDim.alpha = 0.0f;
    tapDim.frame = self.frame;
    // Hack to hug labels only around its text
    if ([self isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *)self;
        CGRect textRect = [label.text boundingRectWithWidth:tapDim.boundsWidth text:label.text font:label.font];
        tapDim.ss_width = textRect.size.width + padding;
    }
    else
    {
        tapDim.ss_width += padding;
    }
    tapDim.ss_x = -(padding/2);
    tapDim.ss_y = -(padding/2);
    tapDim.ss_height += padding;
    tapDim.layer.cornerRadius = SSSpacingMargin;
    tapDim.clipsToBounds = YES;
    [self addSubview:tapDim];
    [self sendSubviewToBack:tapDim];
    
    if (shouldCenter)
    {
        [tapDim centerToParent];
    }
    
    tapDim.alpha = 0.0f;
    tapDim.transform = CGAffineTransformMakeScale(0.90, 0.90);
    
    [UIView animateWithDuration:0.10f animations:^{
        tapDim.alpha = 0.35f;
        tapDim.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        if (finished)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.onAnimationFinished) self.onAnimationFinished();
                [tapDim removeFromSuperview];
            });
        }
    }];
}

@end
