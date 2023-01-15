//
//  SSTheaterAnimator.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTheaterAnimator.h"

@interface SSTheaterAnimator()

@end

@implementation SSTheaterAnimator

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.animationType == AnimationTypePresent)
    {
        self.presentingControllerImageView.hidden = YES;
        self.presentedControllerImageView.hidden = YES;

        // Add view
        [containerView addSubview:toViewController.view];
        
        // Add animatable image view
        UIImageView *animatedImageView = [self createAnimatingImageView];
        [containerView addSubview:animatedImageView];
        
        // Make the destination view fade in
        self.viewToDim.alpha = 0.0f;
        toViewController.view.frame = transitionContext.containerView.bounds;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f usingSpringWithDamping:0.74f initialSpringVelocity:0.8f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.viewToDim.alpha = 1.0f;
            animatedImageView.frame = self.destinationRectForAnimatingImageView;
        } completion:^(BOOL finished) {
            if (finished)
            {
                [animatedImageView removeFromSuperview];
                self.presentingControllerImageView.hidden = NO;
                self.presentedControllerImageView.hidden = NO;
                self.presentedControllerImageView.userInteractionEnabled = YES;
            }
            
            [transitionContext completeTransition:YES];
        }];
    }
    
    if (self.animationType == AnimationTypeDismiss)
    {
        self.presentingControllerImageView.hidden = YES;
        self.presentedControllerImageView.contentMode = self.presentingControllerImageView.contentMode;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState| UIViewAnimationOptionCurveLinear animations:^ {
            self.presentedControllerImageView.frame = self.beginningRectForAnimatingImageView;
            self.viewToDim.alpha = 0.0f;
            self.presentedControllerImageView.clipsToBounds = YES;
            self.presentedControllerImageView.layer.cornerRadius = SSSpacingMargin;
        } completion:^(BOOL finished) {
            if (finished) self.presentingControllerImageView.hidden = NO;
            if (finished) self.presentedControllerImageView.hidden = NO;
            [transitionContext completeTransition:transitionContext.transitionWasCancelled == NO];
        }];
    }
}

- (CGFloat)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return self.animationType == AnimationTypePresent ? 0.50f : 0.36f;
}

#pragma mark - Animating Image View

- (UIImageView *)createAnimatingImageView
{
    CGRect desiredRect;
    
    if (self.animationType == AnimationTypePresent)
    {
        desiredRect = self.beginningRectForAnimatingImageView;
    }
    else
    {
        desiredRect = self.destinationRectForAnimatingImageView;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:desiredRect];
    imageView.image = self.presentingControllerImageView.image;
    imageView.contentMode = self.presentingControllerImageView.contentMode;
    imageView.userInteractionEnabled = YES;
    imageView.clipsToBounds = YES;
    
    return imageView;
}

@end
