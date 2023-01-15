//
//  SSDebugDataViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/29/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"

typedef NS_ENUM(NSUInteger, SSDebugData) {
    SSDebugDataShowLists,
    SSDebugDataShowListItems,
    SSDebugDataShowAllListItems,
    SSDebugDataShowTags,
    SSDebugDataShowListTags,
    SSDebugDataShowAllListTags,
    SSDebugDataShowOptions
};

@interface SSDebugDataViewController : UITableViewController

- (instancetype _Nonnull)initWithDebugDataCase:(SSDebugData)displayCase parentItem:(__kindof SSObject * _Nullable)parentObj;

@end
