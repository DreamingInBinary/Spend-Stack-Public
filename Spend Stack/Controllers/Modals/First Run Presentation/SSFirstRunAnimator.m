//
//  SSFirstRunAnimator.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSFirstRunAnimator.h"

@implementation SSFirstRunAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.animationType == SSFirstRunAnimationTypePresent)
    {
        [containerView addSubview:toViewController.view];
        toViewController.view.frame = containerView.bounds;
    }
    
    if (self.animationType == SSFirstRunAnimationTypeDismiss)
    {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^ {
            fromViewController.view.alpha = 0.0f;
            fromViewController.view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

- (CGFloat)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return (self.animationType == SSFirstRunAnimationTypeDismiss) ? SSUIKitTableViewBatchAnimationDuration : SSBriefAnimationDuration;
}

@end
