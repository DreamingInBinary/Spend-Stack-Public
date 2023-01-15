//
//  CardAnimator.m
//  CardTransition
//
//  Created by Jordan Morgan on 10/13/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "CardAnimator.h"
#import "UITraitCollection+Utils.h"
#import <UIKit/UIKit.h>

static NSInteger TOP_PADDING = 0;
static NSInteger MAX_WIDTH = 320;

@implementation CardAnimator

#pragma mark - Transition API

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGFloat topSafeAreaInset = fromViewController.view.safeAreaInsets.top;
    topSafeAreaInset = [fromViewController isNotch] ? topSafeAreaInset : 44.0f;
    TOP_PADDING = topSafeAreaInset + 10;
    
    if (self.animationType == AnimationTypePresent)
    {
        BOOL isRegularSize = [fromViewController.traitCollection isInRegularTraitCollection];
        CGFloat springDamping = 0.90f;
        
        // Card setup
        toViewController.view.layer.cornerRadius = 17.0f;
        toViewController.view.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner;
        
        if (isRegularSize)
        {
            [self setPresentedViewForRegularTraitSize:toViewController containerView:containerView];
            toViewController.view.ss_y = containerView.boundsHeight;
            springDamping = 0.85f;
        }
        else
        {
            [self setPresentedViewForSmallerTraitSize:toViewController containerView:containerView];
            toViewController.view.ss_y = containerView.ss_height;
        }
        
        // Add view
        [containerView addSubview:toViewController.view];
        
        CGFloat padding = TOP_PADDING;
        BOOL isLandscape = fromViewController.view.boundsWidth > fromViewController.view.boundsHeight;
        if (isLandscape) padding = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f usingSpringWithDamping:springDamping initialSpringVelocity:0.85f options:UIViewAnimationOptionCurveEaseOut animations:^ {
            toViewController.view.ss_y = padding;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    
    if (self.animationType == AnimationTypeDismiss)
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
    return self.animationType == AnimationTypePresent ? .50f : .25f;
}

#pragma mark - Rect Helpers

- (void)setPresentedViewForSmallerTraitSize:(UIViewController *)presentedController containerView:(UIView * _Nonnull)containerView
{
    CGFloat padding = TOP_PADDING;
    BOOL isLandscape = presentedController.view.boundsWidth > presentedController.view.boundsHeight;
    if (isLandscape) padding += 20;
    
    presentedController.view.frame = CGRectMake(0, padding, containerView.ss_width, containerView.ss_height - padding);
    presentedController.view.layer.cornerRadius = 17.0f;
    presentedController.view.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner;
}

- (void)setPresentedViewForRegularTraitSize:(UIViewController *)presentedController containerView:(UIView * _Nonnull)containerView
{
    CGFloat padding = TOP_PADDING;
    BOOL isLandscape = presentedController.view.boundsWidth > presentedController.view.boundsHeight;
    if (isLandscape) padding = 0;
    
    // Modal card on the right side
    CGFloat width = roundf(containerView.boundsWidth * 0.45f);
    if (width > MAX_WIDTH) width = MAX_WIDTH;
    presentedController.view.ss_width = width;
    presentedController.view.ss_height = (containerView.boundsHeight - padding) - SSSpacingBigMargin;
    presentedController.view.ss_y = TOP_PADDING;
    presentedController.view.ss_x = (containerView.boundsWidth - presentedController.view.boundsWidth) - SSSpacingBigMargin;
    
    presentedController.view.layer.cornerRadius = 17.0f;
    presentedController.view.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner | kCALayerMaxXMaxYCorner | kCALayerMinXMaxYCorner;
}

@end
