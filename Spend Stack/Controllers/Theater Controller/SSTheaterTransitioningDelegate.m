//
//  SSTheaterTransitioningDelegate.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTheaterTransitioningDelegate.h"
#import "SSTheaterAnimator.h"
#import "SSTheaterPresentationController.h"

@interface SSTheaterTransitioningDelegate()

@property (strong, nonatomic, readwrite, nonnull) SSTheaterAnimator *animator;
@property (weak, nonatomic, nullable) UIViewController *presented;
@property (weak, nonatomic, nullable) UIViewController *presenting;

@end;

@implementation SSTheaterTransitioningDelegate

#pragma mark - Custom Getter

- (SSTheaterAnimator *)animator
{
    if (_animator == nil)
    {
        _animator = [SSTheaterAnimator new];
        _animator.animationType = AnimationTypePresent;
    }
    
    return _animator;
}

#pragma mark - Transition API

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    [self setAnimatorProperties];
    return self.animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.animator.animationType = AnimationTypeDismiss;
    
    // Check if 3D touch was used to present. If so, these weren't set up within the presentation animation
    if (self.animator.viewToDim == nil)
    {
        [self setAnimatorProperties];
    }
    
    return self.animator;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    self.presenting = presenting ? presenting : source;
    self.presented = presented;
    return [[SSTheaterPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.percentDriver;
}

#pragma mark - Private

- (void)setAnimatorProperties
{
    self.animator.presentedControllerImageView = [((id <SSTheaterImageViewProvidingDelegate>)self.presented) ss_presentedControllerImageView];
    self.animator.destinationRectForAnimatingImageView = [((id <SSTheaterImageViewProvidingDelegate>)self.presented) ss_destinationRectForAnimatingImageView];
    self.animator.viewToDim = [((id <SSTheaterImageViewProvidingDelegate>)self.presented) ss_viewForDimissingAnimation];
    
    // Account for a navigation controller in the hierarchy
    if ([self.presenting isKindOfClass:[SSModalCardNavigationController class]])
    {
        UIViewController *presentingController = ((SSModalCardNavigationController *)self.presenting).viewControllers.lastObject;
        id <SSTheaterImageViewProvidingDelegate> providingDelegate = (id <SSTheaterImageViewProvidingDelegate>)presentingController;
        self.animator.presentingControllerImageView = [providingDelegate ss_presentingControllerImageView];
    }
    else
    {
        self.animator.presentingControllerImageView = [((id <SSTheaterImageViewProvidingDelegate>)self.presenting) ss_presentingControllerImageView];
    }
    
    self.animator.beginningRectForAnimatingImageView = [self.animator.presentingControllerImageView convertRect:self.animator.presentingControllerImageView.bounds toView:nil];
}

@end
