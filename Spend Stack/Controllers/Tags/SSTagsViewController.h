//
//  SSTagsViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/3/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "BottomModalViewController.h"
@class SSTagSelectionViewModel;
@class SSTagsViewController;

@protocol SSTagsViewControllerDelegate <NSObject>

@required
- (void)onTagSelectionChanged:(SSTagSelectionViewModel * _Nullable)tag controller:(SSTagsViewController * _Nonnull)controller;

@optional
- (NSArray <SSListTag *> * _Nonnull)tagsFromListShare;
- (BOOL)shouldMakeTagLabelFirstResponderOnSelection;
- (BOOL)controllerShouldPushTagsManagerWhenPresenting;
- (void)tagsControllerWillDismiss:(SSTagSelectionViewModel * _Nullable)selectedTag;

@end

typedef NS_ENUM(NSUInteger, SSTagsScenario) {
    SSTagsScenarioManageTags,
    SSTagsScenarioAddingToItem
};


@interface SSTagsViewController : SSBaseViewController <SSBaseViewControllerDataReloadable>

- (instancetype _Nonnull)initWithSelectedTag:(SSTagSelectionViewModel * _Nullable)selectedTag delegate:(id <SSTagsViewControllerDelegate> _Nullable)delegate scenario:(SSTagsScenario)scenario;

@end
