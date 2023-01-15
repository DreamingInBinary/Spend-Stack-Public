//
//  UISplitViewController+SSUtils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/11/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ListViewController;
@class ListsViewController;
@class SSNavigationController;

@interface UISplitViewController (SSUtils)

- (SSNavigationController * _Nonnull)ss_masterNavController;
- (SSNavigationController * _Nullable)ss_detailNavController;
- (ListsViewController * _Nonnull)ss_masterViewController;
- (ListViewController * _Nullable)ss_detailViewController;

@end
