//
//  SSModalCardViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSModalCardViewController.h"
#import "ModalCardTransitioningDelegate.h"

@interface SSModalCardViewController ()

@property (strong, nonatomic, nonnull) ModalCardTransitioningDelegate *customTransitionDelegate;

@end

@implementation SSModalCardViewController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        if ([NSProcessInfo processInfo].operatingSystemVersion.majorVersion >= 13 &&
            [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            self.modalPresentationStyle = UIModalPresentationAutomatic;
        }
        else if ([SSCitizenship voiceOverOn] == NO)
        {
            self.customTransitionDelegate = [ModalCardTransitioningDelegate new];
            self.modalPresentationStyle = UIModalPresentationCustom;
            self.transitioningDelegate = self.customTransitionDelegate;
        }
    }
    
    return self;
}

- (BOOL)modalPresentationCapturesStatusBarAppearance
{
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
