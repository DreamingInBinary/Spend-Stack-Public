//
//  SSTheaterPresentationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTheaterPresentationController.h"
#import "SSTheaterTransitioningDelegate.h"
#import "SSTheaterAnimator.h"

@interface SSTheaterPresentationController()

@property (strong, nonatomic, nullable) __kindof UIView *effectView;
@property (strong, nonatomic, readwrite) UIPercentDrivenInteractiveTransition *percentDriver;
@property (strong, nonatomic) UIPanGestureRecognizer *drag;

@end

@implementation SSTheaterPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    return self;
}

#pragma mark - Presentation API

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    [super presentationTransitionDidEnd:completed];
    
    self.drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateDrag:)];
    self.drag.maximumNumberOfTouches = 1;
    self.drag.cancelsTouchesInView = NO;
    self.drag.delegate = (id <UIGestureRecognizerDelegate>)self.presentedViewController;
    
    UIImageView *draggableImageView = [((id <SSTheaterImageViewProvidingDelegate>)self.presentedViewController) ss_presentedControllerImageView];
    
    [draggableImageView addGestureRecognizer:self.drag];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    [super dismissalTransitionDidEnd:completed];
}

#pragma mark - Drag to Dismiss

- (SSTheaterAnimator *)animator
{
    return ((SSTheaterTransitioningDelegate *)self.presentedViewController.transitioningDelegate).animator;
}

// Drag to dimisss
- (void)updateDrag:(UIPanGestureRecognizer *)drag
{
    CGPoint translation = [drag translationInView:self.presentedViewController.view];
    CGFloat percentComplete = translation.y/CGRectGetMidY(self.presentedViewController.view.bounds);

    switch (drag.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.percentDriver = [UIPercentDrivenInteractiveTransition new];
            ((SSTheaterTransitioningDelegate *)self.presentedViewController.transitioningDelegate).percentDriver = self.percentDriver;
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
