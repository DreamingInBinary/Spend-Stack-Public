//
//  BottomModalCardTransitioningDelegate.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "BottomModalCardTransitioningDelegate.h"
#import "BottomModalCardPresentationController.h"
#import <UIKit/UIKit.h>

@implementation BottomModalCardTransitioningDelegate

#pragma mark - Lazy Loads

- (BottomModalCardAnimator *)animator
{
    if (!_animator)
    {
        _animator = [BottomModalCardAnimator new];
    }
    
    return _animator;
}

#pragma mark - Custom Transition Vending

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    // This will return the card animator
    self.animator.animationType = AnimationTypePresent;
    return self.animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    // This will return the card animator
    self.animator.animationType = AnimationTypeDismiss;
    return self.animator;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    return [[BottomModalCardPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

@end
