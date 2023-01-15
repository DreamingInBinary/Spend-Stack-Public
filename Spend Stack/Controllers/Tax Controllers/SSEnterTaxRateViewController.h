//
//  SSEnterTaxRateViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/3/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
@class SSListBuilder;

@interface SSEnterTaxRateViewController : SSBaseViewController

// Nil if they are making a new list, should be set otherwise.
@property (strong, nonatomic, nullable) SSList *editingList;
@property (copy) void (^ _Nullable onConfirmation)(void);

+ (instancetype _Nullable)new NS_UNAVAILABLE;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithTaxInfo:(SSTaxRateInfo * _Nonnull)taxInfo;
- (instancetype _Nonnull)initWithTaxInfoAndWhiteBackground:(SSTaxRateInfo * _Nonnull)taxInfo;

@end
