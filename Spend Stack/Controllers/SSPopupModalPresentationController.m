//
//  SSCustomModelPresentationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/7/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSPopupModalPresentationController.h"

@interface SSPopupModalPresentationController() <UIViewControllerAnimatedTransitioning>

@property (strong, nonatomic, nullable) __kindof UIView *dimmingView;
@property (strong, nonatomic, nonnull) UIViewPropertyAnimator *dimAnimator;

@end

@implementation SSPopupModalPresentationController

#pragma mark - Initializers

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    
    if (self)
    {
        presentedViewController.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    return self;
}

#pragma mark - UIPresentationController Overrides

- (void)presentationTransitionWillBegin
{
    if (self.shouldPreventDimming) return;
    
    __weak typeof(self) weakSelf = self;
    
    __kindof UIView *dimmingView = [SSCitizenship dimmingTransparentViewIfPossible:self.traitCollection.userInterfaceStyle];
    dimmingView.frame = self.containerView.bounds;
    dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dimmingView = dimmingView;
    [self.containerView addSubview:dimmingView];
    
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;

    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight)
    {
        [SSCitizenship setViewFadeOutAnimation:dimmingView];
        self.dimAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:[transitionCoordinator transitionDuration] curve:UIViewAnimationCurveEaseOut animations:^{
            [weakSelf handleStyleChange:nil];
        }];
        [self.dimAnimator startAnimation];
        [self.dimAnimator pauseAnimation];
        self.dimAnimator.fractionComplete = 0.25;
    }

    self.dimmingView.alpha = 0.0f;
    
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([self.dimmingView isKindOfClass:[UIVisualEffectView class]] == NO)
        {
            [SSCitizenship setDarkViewFadeInAnimation:dimmingView];
        }
        else
        {
            self.dimmingView.alpha = 1.0f;
        }
        
        if (self.shouldAlphaFadePresentingController)
        {
            self.presentingViewController.view.transform = CGAffineTransformMakeScale(0.8, 0.8);
            self.presentingViewController.view.alpha = 0.0f;
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    [super presentationTransitionDidEnd:completed];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return [transitionContext isAnimated] ? SSFasterThanFastestAnimationDuration : 0.0f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    
    BOOL isPresenting = (fromViewController == self.presentingViewController);
    CGRect fromViewFinalFrame = [transitionContext finalFrameForViewController:fromViewController];
    CGRect toViewInitialFrame = [transitionContext initialFrameForViewController:toViewController];
    CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
    [containerView addSubview:toView];
    
    if (isPresenting)
    {
        toViewInitialFrame.size = toViewFinalFrame.size;
        toViewInitialFrame.origin = CGPointMake(toViewFinalFrame.origin.x, CGRectGetMidY(containerView.bounds) - (CGRectGetHeight(toViewInitialFrame)/2));
        toView.frame = toViewFinalFrame;
        toView.alpha = 0.5f;
        toView.transform = CGAffineTransformMakeScale(0.92, 0.92);
    }
    else
    {
        fromViewFinalFrame = CGRectOffset(fromView.frame, 0, CGRectGetHeight([UIScreen mainScreen].bounds));
    }
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    UIViewAnimationOptions animationOption = isPresenting ? UIViewAnimationOptionCurveLinear : UIViewAnimationOptionCurveLinear;
    [UIView animateWithDuration:transitionDuration delay:0.0f options:animationOption animations:^{
        if (isPresenting)
        {
            toView.transform = CGAffineTransformIdentity;
            toView.alpha = 1.0f;
        }
        else
        {
            fromView.transform = CGAffineTransformMakeScale(0.92, 0.92);
            fromView.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        [transitionContext completeTransition:!wasCancelled];
    }];
}

- (void)dismissalTransitionWillBegin
{
    if (self.shouldPreventDimming) return;
    
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;
    
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimmingView.alpha = 0.0f;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.dimAnimator stopAnimation:NO];
        [self.dimAnimator finishAnimationAtPosition:UIViewAnimatingPositionCurrent];
    }];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    if (completed == YES)
    {
        self.dimmingView = nil;
        
        if (self.shouldAlphaFadePresentingController)
        {
            [UIView animateWithDuration:SSFastestAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.presentingViewController.view.transform = CGAffineTransformIdentity;
                self.presentingViewController.view.alpha = 1.0f;
            } completion:^(BOOL finished) {
                
            }];
        }
    }
}

#pragma mark - Layout

- (void)preferredContentSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container
{
    [super preferredContentSizeDidChangeForChildContentContainer:container];
    
    if (container == self.presentedViewController)
    {
        [self.containerView setNeedsLayout];
    }
}

- (CGRect)frameOfPresentedViewInContainerView
{
    return [self rectForModalInContainer:self.containerView.bounds];
}

- (void)containerViewWillLayoutSubviews
{
    [super containerViewWillLayoutSubviews];
    self.dimmingView.frame = self.containerView.bounds;
    self.presentedViewController.view.frame = [self rectForModalInContainer:self.containerView.bounds];
}

- (CGRect)rectForModalInContainer:(CGRect)containerViewBounds
{
    CGFloat widthMultiplier = 0.0f;
    CGFloat heightMultiplier = 0.0f;
    CGFloat preferredHeight, preferredWidth, xPos, yPos;
    self.presentedView.layer.maskedCorners = kCALayerMinXMinYCorner|kCALayerMaxXMinYCorner|kCALayerMinXMaxYCorner|kCALayerMaxXMaxYCorner;
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact)
    {
        widthMultiplier = self.containerView.isLandscape ? 0.46 : 0.64f;
        heightMultiplier = 0.76f;
        
        preferredWidth = floorf(containerViewBounds.size.width * widthMultiplier);
        preferredHeight = floorf(containerViewBounds.size.height * heightMultiplier);
        xPos = (containerViewBounds.size.width/2) - (preferredWidth/2);
        yPos = (containerViewBounds.size.height/2) - (preferredHeight/2);
        
        return CGRectMake(xPos, yPos, preferredWidth, preferredHeight);
    }
    else
    {
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
        {
            yPos = [self.presentedViewController isNotch] ? 44 : 20;
            CGFloat height = containerViewBounds.size.height - yPos;
            
            widthMultiplier = 0.65f;
            preferredWidth = floorf(containerViewBounds.size.width * widthMultiplier);
            
            xPos = (containerViewBounds.size.width/2) - preferredWidth/2;
            self.presentedView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
            return CGRectMake(xPos, yPos, preferredWidth, height);
        }
        else
        {
            CGSize preferredSize = CGSizeApplyAffineTransform(self.containerView.ss_size, CGAffineTransformMakeScale(0.86, 0.86));
            preferredHeight = roundf(preferredSize.height);
            preferredWidth = roundf(preferredSize.width);
            
            if ([self.presentedViewController isNotch])
            {
                preferredHeight = containerViewBounds.size.height * .74;
                preferredWidth = containerViewBounds.size.width - 32; // 16 either side
            }
            
            xPos = (containerViewBounds.size.width/2) - preferredWidth/2;
            yPos = (containerViewBounds.size.height/2) - preferredHeight/2;
            
            return CGRectMake(xPos, yPos, preferredWidth, preferredHeight);
        }
    }
    
    return CGRectZero;
}

#pragma mark UIViewControllerTransitioningDelegate

- (UIPresentationController*)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    NSAssert(self.presentedViewController == presented, @"You didn't initialize %@ with the correct presentedViewController.  Expected %@, got %@.", self, presented, self.presentedViewController);
    
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

#pragma mark - Misc

- (void)dimmingViewTapped:(UITapGestureRecognizer *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Static

+ (void)presentPresentationControllerFromController:(UIViewController *)presenting presentedController:(UIViewController *)presented
{
    SSNavigationController *navVC = [[SSNavigationController alloc] initWithRootViewController:presented];
    
    SSPopupModalPresentationController *modalPresentation = [[SSPopupModalPresentationController alloc] initWithPresentedViewController:navVC presentingViewController:presenting];
    navVC.transitioningDelegate = modalPresentation;
    navVC.view.layer.cornerRadius = 17.0f;
    navVC.view.layer.masksToBounds = YES;
    navVC.view.layer.cornerCurve = kCACornerCurveContinuous;
    
    [presenting presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - Misc

- (void)hide
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self handleStyleChange:nil];
    
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight)
    {
        self.dimAnimator.fractionComplete = 0.25f;
    }
    else
    {
        self.dimAnimator.fractionComplete = 0.0f;
    }
}

- (void)handleStyleChange:(NSNotification *)note
{
    UIBlurEffectStyle style = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? UIBlurEffectStyleSystemUltraThinMaterial : UIBlurEffectStyleDark;
    [SSCitizenship setViewFadeInAnimation:self.dimmingView effectStyle:style];
}

@end
