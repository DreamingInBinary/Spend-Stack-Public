//
//  BottomModalCardAnimator.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "BottomModalCardAnimator.h"
#import "SSBottomNavigationViewController.h"
#import "SSTagsViewController.h"
#import "UITraitCollection+Utils.h"

@implementation BottomModalCardAnimator

#pragma mark - Initializer

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.fixedHeight = NAN;
    }
    
    return self;
}

#pragma mark - Animation APIs

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.animationType == AnimationTypePresent)
    {
        // Card setup
        BOOL notchin = [toViewController isNotch];
        if (notchin)
        {
            toViewController.view.layer.cornerRadius = [toViewController preferredCornerRadius];
        }
        else
        {
            [toViewController.view notchifyCornerRadius];
        }
        
        CGFloat width = fromViewController.view.frame.size.width - (SSSpacingMargin * 2);
        if (fromViewController.traitCollection.isInRegularTraitCollection)
        {
            width = fromViewController.view.readableContentGuide.layoutFrame.size.width;
        }
        
        NSUInteger height = isnan(self.fixedHeight) ? 400 : self.fixedHeight;
        toViewController.view.frame = CGRectMake(SSSpacingMargin, fromViewController.view.bounds.size.height, width, height);
        
        // Add view
        [containerView addSubview:toViewController.view];
        
        if (fromViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact || [self isTagController:transitionContext])
        {
            [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
                toViewController.view.ss_y -= toViewController.view.ss_height + SSSpacingMargin + toViewController.view.safeAreaInsets.bottom;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
        else
        {
            [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f usingSpringWithDamping: 0.80f initialSpringVelocity:0.40f options:UIViewAnimationOptionCurveEaseOut animations:^ {
                if (notchin)
                {
                    toViewController.view.ss_y -= toViewController.view.ss_height + 4;
                }
                else
                {
                    toViewController.view.ss_y -= toViewController.view.ss_height + SSSpacingMargin + toViewController.view.safeAreaInsets.bottom;
                }
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
    }
    
    if (self.animationType == AnimationTypeDismiss)
    {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^ {
            fromViewController.view.ss_y += fromViewController.view.ss_height + SSSpacingMargin + toViewController.view.safeAreaInsets.bottom;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

- (CGFloat)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if (self.animationType == AnimationTypeDismiss || [self isTagController:transitionContext]) return 0.25f;
    
    BOOL isCompactHeight = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
    
    return isCompactHeight ? SSUIKitTableViewBatchAnimationDuration : SSBriefAnimationDuration;
}

#pragma mark - Private

// If we ever want a faster transition here like we do with the tags controller, this should move to a BOOL on the transitioning delegate
// To set instead of checking controller types at runtime.
- (BOOL)isTagController:(id<UIViewControllerContextTransitioning>)transitionContext
{
    __kindof UIViewController *presentedController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([presentedController isKindOfClass:[SSBottomNavigationViewController class]])
    {
        return [((SSBottomNavigationViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]).viewControllers.firstObject isKindOfClass:[SSTagsViewController class]];
    }
    
    return NO;
}

@end
