//
//  SSCardAnimatoriPhone.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSCardAnimatoriPhone.h"
#import "UITraitCollection+Utils.h"
#import <UIKit/UIKit.h>

static inline CGFloat SS_Padding(UIViewController *root)
{
    BOOL isNotch = [root isNotch];
    BOOL isLandscape = [root.view isLandscape];
    
    if (isLandscape) return 0.0f;
    
    if (isNotch)
    {
        return 64.0f;
    }
    else
    {
        return 44.0f;
    }
}

@implementation SSCardAnimatoriPhone


#pragma mark - Transition API

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.animationType == iPhoneAnimationTypePresent)
    {
        CGFloat springDamping = 0.90f;
        
        // Card setup
        toViewController.view.layer.cornerRadius = 17.0f;
        toViewController.view.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner;
        
        [self setPresentedViewFrame:toViewController containerView:containerView];
        toViewController.view.ss_y = containerView.ss_height;
        
        // Add view
        [containerView addSubview:toViewController.view];
        
        CGFloat padding = SS_Padding(containerView.window.rootViewController);
        BOOL isLandscape = fromViewController.view.boundsWidth > fromViewController.view.boundsHeight;
        if (isLandscape) padding = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f usingSpringWithDamping:springDamping initialSpringVelocity:0.85f options:UIViewAnimationOptionCurveEaseOut animations:^ {
            toViewController.view.ss_y = padding;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    
    if (self.animationType == iPhoneAnimationTypeDismiss)
    {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^ {
            fromViewController.view.layer.cornerRadius = 0.0f;
            fromViewController.view.ss_y = toViewController.view.bounds.size.height;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:transitionContext.transitionWasCancelled == NO];
        }];
    }
}

- (CGFloat)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.animationType == iPhoneAnimationTypePresent ? .50f : .25f;
}

#pragma mark - Rect Helpers

- (void)setPresentedViewFrame:(UIViewController *)presentedController containerView:(UIView * _Nonnull)containerView
{
    CGFloat padding = SS_Padding(containerView.window.rootViewController);
    presentedController.view.frame = CGRectMake(0, padding, containerView.ss_width, containerView.ss_height - padding);
}

@end
