//
//  UIView+SSShimmer.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/8/18.
//  Copyright © 2018 Buffer. All rights reserved.
//

#import "UIView+SSShimmer.h"
#import "SSConstants.h"
#import <objc/runtime.h>

static NSString * const SS_SHIMMERING_KEY = @"ss.Shimmering.animationKey";

@implementation UIView (SSShimmer) 

#pragma mark - Dynamic Properties

static const void *IsShimmeringKey = &IsShimmeringKey;
static const void *GradientKey = &GradientKey;
static const void *AnimationKey = &AnimationKey;

- (BOOL)isShimmering
{
    return ((NSNumber *)objc_getAssociatedObject(self, IsShimmeringKey)).boolValue;
}

- (void)setIsShimmering:(BOOL)isShimmering
{
    objc_setAssociatedObject(self, IsShimmeringKey, @(isShimmering), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAGradientLayer *)gradient
{
    CAGradientLayer *returnVal = objc_getAssociatedObject(self, GradientKey);
    
    if (!returnVal)
    {
        returnVal = [CAGradientLayer new];
        objc_setAssociatedObject(self, GradientKey, returnVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return returnVal;
}

- (CABasicAnimation *)shimmerAnimation
{
    CABasicAnimation *returnVal = objc_getAssociatedObject(self, AnimationKey);
    
    if (!returnVal)
    {
        returnVal = [CABasicAnimation animationWithKeyPath:@"locations"];
        objc_setAssociatedObject(self, AnimationKey, returnVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return returnVal;
}

#pragma mark - Public API

- (void)startShimmeringWithRepitions:(NSInteger)reps
{
    if (self.isShimmering || CGSizeEqualToSize(CGSizeZero, self.layer.bounds.size)) return;
    self.isShimmering = YES;
    
    UIColor *lightColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    UIColor *darkColor = [[UIColor blackColor] colorWithAlphaComponent:1.0];
    
    self.gradient.colors = @[(id)darkColor.CGColor, (id)lightColor.CGColor, (id)darkColor.CGColor];
    self.gradient.frame = CGRectMake(-2*self.bounds.size.width, 0, 4*self.bounds.size.width, self.bounds.size.height);
    self.gradient.startPoint = CGPointMake(0, 0.5);
    self.gradient.endPoint = CGPointMake(1.0, 0.5);
    self.gradient.locations = @[@(0.4), @(0.5), @(0.6)];
    
    CABasicAnimation *shimmerAnimation = [CABasicAnimation animationWithKeyPath:@"locations"];
    shimmerAnimation.duration = SSBriefAnimationDuration;
    shimmerAnimation.repeatCount = reps > 0 ? reps : INFINITY;
    shimmerAnimation.fromValue = @[@(0.0),@(0.12),@(0.3)];
    shimmerAnimation.toValue = @[@(0.6),@(0.86),@(1.0)];
    shimmerAnimation.removedOnCompletion = NO;
    shimmerAnimation.delegate = reps > 0 ? self : nil;
    
    [self.gradient addAnimation:shimmerAnimation forKey:SS_SHIMMERING_KEY];
    self.layer.mask = self.gradient;
}

- (void)startShimmering
{
    [self startShimmeringWithRepitions:0];
}

- (void)endShimmering
{
    self.isShimmering = NO;
    [self.layer.mask removeAnimationForKey:SS_SHIMMERING_KEY];
    self.layer.mask = nil;
    [self.layer setNeedsDisplay];
}

#pragma mark - Animation Delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self endShimmering];
}

@end
