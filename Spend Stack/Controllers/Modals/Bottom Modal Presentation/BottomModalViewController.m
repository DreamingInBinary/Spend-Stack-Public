//
//  BottomModalViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/27/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "BottomModalViewController.h"
#import "BottomModalCardAnimator.h"
#import "BottomModalCardTransitioningDelegate.h"

@interface BottomModalViewController ()

@property (strong, nonatomic, nonnull) BottomModalCardTransitioningDelegate *customTransitionDelegate;

@end

@implementation BottomModalViewController

#pragma mark - Custom Getters and Setters

- (void)setFixedHeight:(CGFloat)fixedHeight {
    _fixedHeight = fixedHeight;
    _customTransitionDelegate.animator.fixedHeight = _fixedHeight;
}

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.customTransitionDelegate = [BottomModalCardTransitioningDelegate new];
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self.customTransitionDelegate;
    }
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
