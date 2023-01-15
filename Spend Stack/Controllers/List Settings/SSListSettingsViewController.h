//
//  SSListSettingsViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/16/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"

@protocol SSListSettingsViewControllerDelegate <NSObject>

@required
- (void)ss_userRequestedShareSheet;
- (void)ss_userRequestedStartCollaboration;
- (void)ss_userRequestedRemoveAllItems:(SSList * _Nonnull)copiedList;
- (void)ss_userRequestedListRename:(NSString * _Nonnull)newName;
- (void)ss_userRequestedCheckboxToggle:(SSList * _Nonnull)copiedList;
- (void)ss_userChangedCurrency:(NSString * _Nonnull)currencyID;
- (UITableView * _Nonnull)ss_tableViewForImageShareSnapshot;

@end

@interface SSListSettingsViewController : SSBaseViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic, readonly, nullable) SSList *list;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list delegate:(id <SSListSettingsViewControllerDelegate> _Nullable)delegate NS_DESIGNATED_INITIALIZER;

@end
