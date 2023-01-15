//
//  SSBlurModalAnimator.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/8/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSBlurModalAnimator.h"
#import "SSConstants.h"
#import "SSBlurModalPresentationController.h"

@interface SSBlurModalAnimator()

@property (nonatomic, getter=isPresenting) BOOL presenting;

@end

@implementation SSBlurModalAnimator

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.presenting = YES;
    }
    
    return self;
}

#pragma mark - Animator delegate

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if (self.presenting)
    {
        [self performPresentationAnimation:transitionContext];
    }
    else
    {
        [self performDismissingAnimation:transitionContext];
    }
}

- (void)performPresentationAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *animationContainerView = transitionContext.containerView;
    UIView *destinationView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    animationContainerView.backgroundColor = [UIColor clearColor];
    [animationContainerView addSubviews:@[destinationView]];
    
    destinationView.alpha = 0.0f;
    destinationView.transform = CGAffineTransformMakeScale(1.3, 1.3);

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^ {
        destinationView.alpha = 1.0f;
        destinationView.transform = CGAffineTransformIdentity;
    } completion:^ (BOOL done) {
        [transitionContext completeTransition:YES];
        self.presenting = !self.isPresenting;
    }];
}

- (void)performDismissingAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = fromViewVC.view;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseOut animations:^ {
        fromView.alpha = 0.0f;
    } completion:^ (BOOL done) {
        [transitionContext completeTransition:YES];
        self.presenting = !self.isPresenting;
        [fromView removeFromSuperview];
    }];
}

#pragma mark - Transitioning Delegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    return [[SSBlurModalPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}


@end
