//
//  SSFirstRunTransitioningDelegate.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSFirstRunTransitioningDelegate.h"
#import "SSFirstRunAnimator.h"
#import "SSFirstRunPresentationController.h"

@implementation SSFirstRunTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    SSFirstRunAnimator *animator = [SSFirstRunAnimator new];
    animator.animationType = SSFirstRunAnimationTypePresent;
    return animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    SSFirstRunAnimator *animator = [SSFirstRunAnimator new];
    animator.animationType = SSFirstRunAnimationTypeDismiss;
    return animator;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    return [[SSFirstRunPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

@end
