//
//  UISplitViewController+SSUtils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/11/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "UISplitViewController+SSUtils.h"
#import "Spend_Stack_2-Swift.h"

@implementation UISplitViewController (SSUtils)

#pragma mark - Nav Controller Access

- (SSNavigationController *)ss_masterNavController
{
    return (SSNavigationController *)self.viewControllers.firstObject;
}

- (SSNavigationController *)ss_detailNavController
{
    if (self.viewControllers.count > 1)
    {
        return (SSNavigationController * )self.viewControllers.lastObject;
    }
    
    return nil;
}

#pragma mark - Controller Access

- (ListsViewController *)ss_masterViewController
{
    SSNavigationController *masterNavVC = (SSNavigationController * )self.viewControllers.firstObject;
    return (ListsViewController *)masterNavVC.topViewController;
}

- (ListViewController *)ss_detailViewController
{
    SSNavigationController *detailNavVC = (SSNavigationController * )self.viewControllers.lastObject;
    ListViewController *listVC = (ListViewController *)detailNavVC.topViewController;
    
    // On iPhone, it could be nil due to the delegate handling
    if ([listVC isKindOfClass:[ListViewController class]] == NO)
    {
        return nil;
    }
    
    return listVC;
}

@end
