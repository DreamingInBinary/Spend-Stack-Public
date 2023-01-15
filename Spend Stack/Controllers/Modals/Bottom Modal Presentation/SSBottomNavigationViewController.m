//
//  SSBottomNavigationViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/27/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBottomNavigationViewController.h"
#import "BottomModalCardTransitioningDelegate.h"

@interface SSBottomNavigationViewController ()

@property (strong, nonatomic, nonnull) BottomModalCardTransitioningDelegate *customTransitionDelegate;

@end

@implementation SSBottomNavigationViewController

#pragma mark - Custom Getters and Setters

- (void)setFixedHeight:(CGFloat)fixedHeight {
    _fixedHeight = fixedHeight;
    _customTransitionDelegate.animator.fixedHeight = _fixedHeight;
}

#pragma mark - Initializers

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    
    if (self)
    {
        self.customTransitionDelegate = [BottomModalCardTransitioningDelegate new];
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self.customTransitionDelegate;
        
        self.view.clipsToBounds = YES;
        self.view.layer.cornerRadius = 17.0f;
    }
    
    return self;
}

- (BOOL)modalPresentationCapturesStatusBarAppearance
{
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
