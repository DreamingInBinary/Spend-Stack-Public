//
//  ModalCardTransitioningDelegate.m
//  CardTransition
//
//  Created by Jordan Morgan on 10/17/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "ModalCardTransitioningDelegate.h"
#import "ModalCardPresentationController.h"
#import "SSModalCardiPhonePresentationController.h"
#import "CardAnimator.h"
#import "SSCardAnimatoriPhone.h"
#import <UIKit/UIKit.h>

@interface ModalCardTransitioningDelegate()

@property (strong, nonatomic, readwrite, nonnull) CardAnimator *animator;
@property (strong, nonatomic, readwrite, nonnull) SSCardAnimatoriPhone *iPhoneAnimator;

@end

@implementation ModalCardTransitioningDelegate

#pragma mark - Intializer

- (instancetype)init
{
    self = [super init]; 
    
    if (self)
    {
        self.animator = [CardAnimator new];
        self.iPhoneAnimator = [SSCardAnimatoriPhone new];
    }
    
    return self;
}

#pragma mark - Transitioning Object Vending

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    self.animator.animationType = AnimationTypePresent;
    self.iPhoneAnimator.animationType = iPhoneAnimationTypePresent;
    return [SSCitizenship idiomIsiPad] ? self.animator : self.iPhoneAnimator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.animator.animationType = AnimationTypeDismiss;
    self.iPhoneAnimator.animationType = iPhoneAnimationTypeDismiss;
    return [SSCitizenship idiomIsiPad] ? self.animator : self.iPhoneAnimator;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    if ([SSCitizenship idiomIsiPad])
    {
        return [[ModalCardPresentationController alloc] initWithPresentedViewController:presented
                                                               presentingViewController:presenting];
    }
    else
    {
        return [[SSModalCardiPhonePresentationController alloc] initWithPresentedViewController:presented
                                                                       presentingViewController:presenting];
    }
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.percentDriver;
}

@end
