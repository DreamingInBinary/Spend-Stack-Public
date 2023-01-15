//
//  SSAdvancedListOptionsViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 12/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"

typedef NS_ENUM(NSUInteger, OptionScope) {
    OptionScopeList,
    OptionScopeApp
};

@interface SSAdvancedListOptionsViewController : SSBaseViewController

- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list scope:(OptionScope)scope;

@end
