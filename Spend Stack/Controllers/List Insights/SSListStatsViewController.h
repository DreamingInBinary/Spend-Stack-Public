//
//  SSListStatsViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSModalCardViewController.h"

@interface SSListInsightsViewController : SSModalCardViewController

+ (instancetype _Nullable)new NS_UNAVAILABLE;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list NS_DESIGNATED_INITIALIZER;

@end
