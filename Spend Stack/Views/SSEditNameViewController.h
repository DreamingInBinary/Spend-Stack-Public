//
//  SSEditListNameViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/19/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"

@interface SSEditNameViewController : SSBaseViewController

@property (copy) void (^ _Nullable onItemRenamed)(NSString * _Nullable newName);
+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list; // Does save locally.
- (instancetype _Nonnull)initWithListItem:(SSListItem * _Nullable)listItem; // Doesn't save locally, up to the block.

@end
