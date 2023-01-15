//
//  SSListStatsViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSModalCardViewController.h"

@interface SSListInsightsViewController : SSModalCardViewController <UIPopoverPresentationControllerDelegate>

- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list;

@end
