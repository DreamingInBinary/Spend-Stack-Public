//
//  SSBlurModalPresentationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/8/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSBlurModalPresentationController.h"

@interface SSBlurModalPresentationController()

@property (strong, nonatomic, nonnull) __kindof UIView *effectView;

@end

@implementation SSBlurModalPresentationController

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    // UIWindow is black, and the user will see it during dismiss. Edit that here.
    self.containerView.window.backgroundColor = [UIColor systemBackgroundColor];
    self.containerView.backgroundColor = [UIColor clearColor];
    
    self.effectView = [SSCitizenship transparentViewIfPossible];
    [SSCitizenship setViewFadeOutAnimation:self.effectView];
    
    self.effectView.frame = self.containerView.bounds;
    self.effectView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.containerView addSubview:self.effectView];
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Do any animations to the chrome (i.e. the presenting controller)
       [SSCitizenship setViewFadeInAnimation:self.effectView];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [UIView animateWithDuration:[context transitionDuration] animations:^ {
            [SSCitizenship setViewFadeOutAnimation:self.effectView];
        } completion:nil];
    }];
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    
    self.presentingViewController.view.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [SSCitizenship setViewFadeInAnimation:self.effectView];
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Undo any animations to the chrome (i.e. the presenting controller)
        [SSCitizenship setViewFadeOutAnimation:self.effectView];
        self.presentingViewController.view.transform = CGAffineTransformIdentity;
    } completion:^(id <UIViewControllerTransitionCoordinatorContext>context) {
        [self.effectView removeFromSuperview];
    }];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    if (completed)
    {
        // Switch it back to its default color.
        self.containerView.window.backgroundColor = [UIColor blackColor];
    }
}

#pragma mark - Trait Collection

- (void)containerViewDidLayoutSubviews
{
    [super containerViewDidLayoutSubviews];

    self.presentedViewController.view.frame = self.containerView.bounds;
    self.effectView.frame = self.containerView.bounds;
}

#pragma mark - Private

- (CGRect)presentingMasterViewRect
{
    UISplitViewController *splitVC = (UISplitViewController *)self.presentingViewController;
    return splitVC.viewControllers.firstObject.view.bounds;
}

- (UIViewController *)presentingMasterViewController
{
    UISplitViewController *splitVC = (UISplitViewController *)self.presentingViewController;
    return splitVC.viewControllers.firstObject;
}

@end
