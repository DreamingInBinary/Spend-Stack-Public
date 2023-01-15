//
//  SSListTotalBreakdownView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSCountingLabel;

static NSString * _Nonnull const SS_SUBTOTAL_LABEL = @"SS_SUBTOTAL_LABEL";
static NSString * _Nonnull const SS_SUBTOTAL_AMOUNT_LABEL = @"SS_SUBTOTAL_AMOUNT_LABEL";
static NSString * _Nonnull const SS_TAX_TOTAL_LABEL = @"SS_TAX_TOTAL_LABEL";
static NSString * _Nonnull const SS_TAX_TOTAL_AMOUNT_LABEL = @"SS_TAX_TOTAL_AMOUNT_LABEL";
static NSString * _Nonnull const SS_DISCOUNT_LABEL = @"SS_DISCOUNT_LABEL";
static NSString * _Nonnull const SS_DISCOUNT_AMOUNT_LABEL = @"SS_DISCOUNT_AMOUNT_LABEL";
static NSString * _Nonnull const SS_TOTAL_LABEL = @"SS_TOTAL_LABEL";
static NSString * _Nonnull const SS_TOTAL_AMOUNT_LABEL = @"SS_TOTAL_AMOUNT_LABEL";

@interface SSListTotalBreakdownView : UIView

+ (NSDictionary <NSString *, SSCountingLabel *> * _Nonnull)labelsForListBreakdown:(NSString * _Nonnull)currencyID;

- (CGFloat)estimatedHeightForListTotalHeaderInView:(UIView * _Nullable)view;
- (void)updateUIForList:(SSList * _Nonnull)list;

@end
