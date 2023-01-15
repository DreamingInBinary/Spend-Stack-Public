//
//  BottomModalCardPresentationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "BottomModalCardPresentationController.h"
#import "BottomModalCardTransitioningDelegate.h"

@interface BottomModalCardPresentationController()

@property (strong, nonatomic, nullable) UIView *dimmerView;

@end

@implementation BottomModalCardPresentationController

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    self.dimmerView = [[UIView alloc] initWithFrame:self.containerView.bounds];
    self.dimmerView.opaque = NO;
    self.dimmerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dimmerView.backgroundColor = [UIColor blackColor];
    self.dimmerView.alpha = 0.0f;
    [self.containerView addSubview:self.dimmerView];
    
    // P R I V A T E A P I
    [self.presentedView notchifyCornerRadius];
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Do any animations to the chrome (i.e. the presenting controller)
        self.dimmerView.alpha = 0.4f;
    } completion:nil];
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    
    [[self.presentedViewController transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Undo any animations to the chrome (i.e. the presenting controller)
        self.dimmerView.alpha = 0.0f;
    } completion:^(id <UIViewControllerTransitionCoordinatorContext>context) {
        [self.dimmerView removeFromSuperview];
    }];
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    [super presentationTransitionDidEnd:completed];
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    UISwipeGestureRecognizer *swipeToDismiss = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    swipeToDismiss.direction = UISwipeGestureRecognizerDirectionDown;
    
    [self.dimmerView addGestureRecognizer:tapToDismiss];
    [self.dimmerView addGestureRecognizer:swipeToDismiss];
}

#pragma mark - Rotations

- (void)containerViewWillLayoutSubviews
{
    [super containerViewWillLayoutSubviews];
    self.presentedViewController.view.frame = [self rectForPresentedController];
}

- (CGRect)rectForPresentedController
{
    CGFloat widthMultiplier = 0.0f;
    CGFloat preferredHeight, preferredWidth, xPos, yPos;
    
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
    {
        yPos = [self.presentedViewController isNotch] ? 44 : 20;
        CGFloat height = self.containerView.ss_size.height - yPos;
        
        widthMultiplier = 0.65f;
        preferredWidth = floorf(self.containerView.ss_size.width * widthMultiplier);
        
        xPos = (self.containerView.ss_size.width/2) - preferredWidth/2;
        self.presentedView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        
        return CGRectMake(xPos, yPos, preferredWidth, height);
    }
    else
    {
        preferredHeight = isnan([self animator].fixedHeight) ? 300 : [self animator].fixedHeight;
        BOOL isRegularWidth = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
        
        if ([self.presentedViewController isNotch])
        {
            preferredWidth = self.containerView.boundsWidth - SSSpacingMargin;
            xPos = SSSpacingMargin/2;
            yPos = self.containerView.boundsHeight - (preferredHeight + 4);
        }
        else
        {
            if (isRegularWidth)
            {
                preferredWidth = 380;
                xPos = floorf(self.containerView.centerX - (preferredWidth/2));
            }
            else
            {
                preferredWidth = self.containerView.boundsWidth - (SSSpacingMargin * 2);
                xPos = SSSpacingMargin;
            }
            
            yPos = self.containerView.boundsHeight - (preferredHeight + SSSpacingMargin + self.containerView.safeAreaInsets.bottom);
        }
        
        self.presentedView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        
        return CGRectMake(xPos, yPos, preferredWidth, preferredHeight);
    }
}

#pragma mark - Misc

- (BottomModalCardAnimator *)animator
{
    return ((BottomModalCardTransitioningDelegate *)self.presentedViewController.transitioningDelegate).animator;
}

- (void)hide
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

