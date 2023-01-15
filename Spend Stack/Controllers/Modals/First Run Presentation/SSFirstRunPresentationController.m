//
//  SSFirstRunPresentationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSFirstRunPresentationController.h"

@interface SSFirstRunPresentationController()

@property (strong, nonatomic, nonnull) __kindof UIView *effectView;

@end

@implementation SSFirstRunPresentationController

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    self.containerView.window.backgroundColor = [UIColor systemBackgroundColor];
    self.containerView.backgroundColor = [UIColor clearColor];
    
    self.effectView = [SSCitizenship transparentViewIfPossible];
    [SSCitizenship setViewFadeOutAnimation:self.effectView];
    
    self.effectView.frame = self.containerView.bounds;
    self.effectView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.containerView addSubview:self.effectView];
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
        // UIWindow should be black, set it back.
        self.presentingViewController.ss_windowScene.windows.firstObject.backgroundColor = [UIColor blackColor];
        self.containerView.window.backgroundColor = [UIColor blackColor];
        self.containerView.backgroundColor = [UIColor blackColor];
    }];
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    [super presentationTransitionDidEnd:completed];
}

#pragma mark - Rotations

- (void)containerViewWillLayoutSubviews
{
    [super containerViewWillLayoutSubviews];
    self.presentedViewController.view.frame = self.containerView.bounds;
}

#pragma mark - Misc

- (void)hide
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
