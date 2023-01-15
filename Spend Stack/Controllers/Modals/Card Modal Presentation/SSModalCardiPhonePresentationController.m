//
//  SSModalCardiPhonePresentationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSModalCardiPhonePresentationController.h"
#import "ModalCardTransitioningDelegate.h"
#import "SSCardAnimatoriPhone.h"
#import "UITraitCollection+Utils.h"
#import "ORKBarGraphChartView.h"

static inline CGAffineTransform SS_transform(CGRect sourceRect, CGRect finalRect)
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -(CGRectGetMidX(sourceRect)-CGRectGetMidX(finalRect)), -(CGRectGetMidY(sourceRect)-CGRectGetMidY(finalRect)));
    transform = CGAffineTransformScale(transform, finalRect.size.width/sourceRect.size.width, finalRect.size.height/sourceRect.size.height);
    
    return transform;
}

static inline void SS_presentingTransforms(UIView * view, BOOL isNotch, CGRect containerSize)
{
    if ([view isLandscape])
    {
        view.transform = CGAffineTransformIdentity;
        view.frame = CGRectMake(0, 0, containerSize.size.width, containerSize.size.height);
    }
    else
    {
        view.transform = CGAffineTransformIdentity;
        
        CGFloat topPadding = isNotch ? 44.0f: 22.0f;
        CGFloat horizontalPadding = 10.0f;
        
        CGSize targetRectSize = containerSize.size;
        CGRect targetRect = CGRectMake(horizontalPadding, topPadding, targetRectSize.width - (horizontalPadding * 2), targetRectSize.height - topPadding);
        
        view.transform = SS_transform(view.frame, targetRect);
    }
    
    view.clipsToBounds = YES;
    view.layer.cornerRadius = 17.0f;
    view.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMinYCorner;
}

static inline void SS_dismissingTransforms(UIView *view, CGRect containerRect)
{
    view.transform = CGAffineTransformIdentity;
    view.layer.cornerRadius = 0.0f;
    view.frame = containerRect;
}

@interface SSModalCardiPhonePresentationController() <UIGestureRecognizerDelegate>

@property (strong, nonatomic, nullable) __kindof UIView *fxView;
@property (strong, nonatomic, readwrite) UIPercentDrivenInteractiveTransition *percentDriver;
@property (strong, nonatomic) UIPanGestureRecognizer *drag;

// Pure presentation helpers
@property (nonatomic, readonly, getter=shouldCreateModalCard) BOOL createModalCard;
@property (nonatomic, readonly) BOOL presentingControllerIsModalCard;

@end

@implementation SSModalCardiPhonePresentationController

#pragma mark - Computed Properties

- (BOOL)shouldCreateModalCard
{
    if ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"])
    {
        return self.presentingControllerIsModalCard;
    }
    
    return YES;
}

- (BOOL)presentingControllerIsModalCard
{
    return [self.presentingViewController.transitioningDelegate isKindOfClass:[ModalCardTransitioningDelegate class]];
}

#pragma mark - Presentation API

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    if (self.shouldCreateModalCard)
    {
        self.fxView = [SSCitizenship darkTransparentViewIfPossible];
        self.fxView.alpha = 0.5f;
        [SSCitizenship setViewFadeOutAnimation:self.fxView];
        
        [self.presentingViewController.view addSubview:self.fxView];
        self.fxView.frame = self.presentingViewController.view.bounds;
        self.fxView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setChromeForPresentation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setChromeForDismissal];
    } completion:^(id <UIViewControllerTransitionCoordinatorContext>context) {
        if (context.isCancelled)
        {
            [SSCitizenship setDarkViewFadeInAnimation:self.fxView];
        }
        else
        {
            [self.fxView removeFromSuperview];
        }
    }];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        SS_presentingTransforms(self.presentingViewController.view, [self.presentedViewController isNotch], CGRectMake(0, 0, size.width, size.height));
        
        if (CGAffineTransformEqualToTransform(self.presentedViewController.view.transform, CGAffineTransformIdentity))
        {
            [self.animator setPresentedViewFrame:self.presentedViewController containerView:self.containerView];
        }
        
    } completion:nil];
}

#pragma mark - Chrome Layout

- (void)setChromeForPresentation
{
    BOOL notchin = [self.presentingViewController isNotch];
    
    if (self.shouldCreateModalCard)
    {
        [SSCitizenship setDarkViewFadeInAnimation:self.fxView];
        SS_presentingTransforms(self.presentingViewController.view, notchin, self.containerView.bounds);
    }
}

- (void)setChromeForDismissal
{
    [SSCitizenship setViewFadeOutAnimation:self.fxView];
    
    if (self.presentingControllerIsModalCard)
    {
        self.presentingViewController.view.transform = CGAffineTransformIdentity;
        [[self animator] setPresentedViewFrame:self.presentingViewController containerView:self.containerView];
    }
    else
    {
        SS_dismissingTransforms(self.presentingViewController.view, self.containerView.bounds);
    }
}

#pragma mark - Animator Access

- (SSCardAnimatoriPhone *)animator
{
    return ((ModalCardTransitioningDelegate *)self.presentedViewController.transitioningDelegate).iPhoneAnimator;
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
