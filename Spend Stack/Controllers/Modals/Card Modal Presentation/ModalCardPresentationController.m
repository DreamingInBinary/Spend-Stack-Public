//
//  ModalCardPresentationController.m
//  CardTransition
//
//  Created by Jordan Morgan on 10/17/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "ModalCardPresentationController.h"
#import "ModalCardTransitioningDelegate.h"
#import "CardAnimator.h"
#import "UITraitCollection+Utils.h"
#import "ORKBarGraphChartView.h"

@interface ModalCardPresentationController() <UIGestureRecognizerDelegate>

@property (strong, nonatomic, nullable) __kindof UIView *effectView;
@property (strong, nonatomic, readwrite) UIPercentDrivenInteractiveTransition *percentDriver;
@property (strong, nonatomic) UIPanGestureRecognizer *drag;

@end

@implementation ModalCardPresentationController

#pragma mark - Presentation API

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    self.effectView = [SSCitizenship darkTransparentViewIfPossible];
    self.effectView.frame = self.presentingViewController.view.bounds;
    self.effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [SSCitizenship setViewFadeOutAnimation:self.effectView];
    [self.presentingViewController.view addSubview:self.effectView];
    self.presentingViewController.view.clipsToBounds = YES;
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Do any animations to the chrome (i.e. the presenting controller)
        if ([self.traitCollection isInRegularTraitCollection])
        {
            [self setChromeForRegularTraitCollectionDuringPresentation];
        }
        else
        {
            [self setChromeForSmallerTraitCollectionDuringPresentation];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(presentationControllerWillDismiss:)]) {
        [self.delegate presentationControllerWillDismiss:self];
    }
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Undo any animations to the chrome (i.e. the presenting controller)
        if ([self.traitCollection isInRegularTraitCollection])
        {
            [self setChromeForRegularTraitCollectionDuringDismissal];
        }
        else
        {
            [self setChromeForSmallerTraitCollectionDuringDismissal];
        }
    } completion:^(id <UIViewControllerTransitionCoordinatorContext>context) {
        if (context.isCancelled)
        {
            [SSCitizenship setDarkViewFadeInAnimation:self.effectView];
        }
        else
        {
            [self.effectView removeFromSuperview];
            self.presentingViewController.view.clipsToBounds = NO;
        }
    }];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    [super dismissalTransitionDidEnd:completed];
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    [super presentationTransitionDidEnd:completed];
    
    self.drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateDrag:)];
    self.drag.maximumNumberOfTouches = 1;
    self.drag.cancelsTouchesInView = YES;
    self.drag.delegate = self;
    [self.presentedViewController.view addGestureRecognizer:self.drag];
}

#pragma mark - Trait Collection

- (void)containerViewDidLayoutSubviews
{
    [super containerViewDidLayoutSubviews];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if ([self.traitCollection isInRegularTraitCollection])
        {
            [self.animator setPresentedViewForRegularTraitSize:self.presentedViewController containerView:self.containerView];
            [self setChromeForRegularTraitCollectionDuringPresentation];
        }
        else
        {
            [self.animator setPresentedViewForSmallerTraitSize:self.presentedViewController containerView:self.containerView];
            [self setChromeForSmallerTraitCollectionDuringPresentation];
        }
    }
}

#pragma mark - Chrome Layout

- (void)setChromeForRegularTraitCollectionDuringPresentation
{
    [SSCitizenship setDarkViewFadeInAnimation:self.effectView];
    self.effectView.alpha = 0.5f;
    self.presentingViewController.view.transform = CGAffineTransformIdentity;
    self.presentingViewController.view.layer.cornerRadius = 0.0f;
    self.presentingViewController.view.frame = CGRectMake(0, 0, self.containerView.boundsWidth, self.containerView.boundsHeight);
}

- (void)setChromeForSmallerTraitCollectionDuringPresentation
{
    // Do any animations to the chrome (i.e. the presenting controller)
    [SSCitizenship setDarkViewFadeInAnimation:self.effectView];
    self.effectView.alpha = 1.0f;
    self.presentingViewController.view.transform = CGAffineTransformMakeScale(0.90f, 0.90f);
    self.presentingViewController.view.layer.cornerRadius = 17.0f;
    self.presentingViewController.view.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner;
}

- (void)setChromeForRegularTraitCollectionDuringDismissal
{
    [SSCitizenship setViewFadeOutAnimation:self.effectView];
    self.presentingViewController.view.transform = CGAffineTransformIdentity;
    self.presentingViewController.view.layer.cornerRadius = 0.0f;
    self.presentingViewController.view.frame = CGRectMake(0, 0, self.containerView.boundsWidth, self.containerView.boundsHeight);
}

- (void)setChromeForSmallerTraitCollectionDuringDismissal
{
    [SSCitizenship setViewFadeOutAnimation:self.effectView];
    self.presentingViewController.view.transform = CGAffineTransformIdentity;
    self.presentingViewController.view.layer.cornerRadius = 0.0f;
    self.presentingViewController.view.frame = self.containerView.bounds;
}

#pragma mark - Animator Access

- (CardAnimator *)animator
{
    return ((ModalCardTransitioningDelegate *)self.presentedViewController.transitioningDelegate).animator;
}

#pragma mark - Drag to dimiss

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] ||
        [otherGestureRecognizer.view isKindOfClass:[ORKBarGraphChartView class]])
    {
        return NO;
    }
    
    return YES;
}

- (void)updateDrag:(UIPanGestureRecognizer *)drag
{
    CGPoint dragPoint = [drag translationInView:drag.view];
    NSInteger dragViewHeight = (drag.view.bounds.size.height);
    CGFloat percentComplete = (dragPoint.y/dragViewHeight) *.80f;
    
    switch (drag.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.percentDriver = [UIPercentDrivenInteractiveTransition new];
            ((ModalCardTransitioningDelegate *)self.presentedViewController.transitioningDelegate).percentDriver = self.percentDriver;
            [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            [self.percentDriver updateInteractiveTransition:percentComplete];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            
            if (percentComplete > 0.5 || [drag velocityInView:drag.view].y > 0)
            {
                self.percentDriver.completionCurve = UIViewAnimationCurveEaseOut;
                [self.percentDriver finishInteractiveTransition];
            }
            else
            {
                self.percentDriver.completionCurve = UIViewAnimationCurveLinear;
                self.percentDriver.completionSpeed = 1.0 * percentComplete;
                [self.percentDriver cancelInteractiveTransition];
            }
            
            self.percentDriver = nil;
            break;
        }
        default:
        {
            break;
        }
    }
}

@end
