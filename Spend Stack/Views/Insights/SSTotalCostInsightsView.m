//
//  SSTotalCostInsightsView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTotalCostInsightsView.h"
#import "SSCellStackView.h"

static const NSInteger SS_IDX_SUBTOTAL = 0;
static const NSInteger SS_IDX_TAX = 1;
static const NSInteger SS_IDX_DISCOUNTS = 2;
static const NSInteger SS_IDX_TOTAL = 3;

@interface SSTotalCostInsightsView()

@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;
@property (strong, nonatomic, nonnull) SSLabel *totalLabel;
@property (strong, nonatomic, nonnull) NSArray <SSCellStackView *> *labelStacks;

@end

@implementation SSTotalCostInsightsView

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.list = list;
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:self.list.currencyIdentifier];
        [self createViews];
        [self setConstraints];
    }
    
    return self;
}

#pragma mark - View Creation

- (void)createViews
{
    // Total Label
    self.totalLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
    [self.totalLabel configureFontWeight:UIFontWeightSemibold];
    self.totalLabel.text = ss_Localized(@"breakdown.vc.title");
    [self addSubview:self.totalLabel];
    
    // Subtotal
    NSString *subtotalText = [self.taxUtil guranteedCurrencyString:[self.list calcBaseCost].stringValue];
    SSCellStackView *subTotalCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"breakdown.vc.subtotal") trailingText:subtotalText];
    
    // Tax
    NSString *taxText = [self.taxUtil guranteedCurrencyString:[self.list calcTaxAmount].stringValue];
    SSCellStackView *taxCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"breakdown.vc.tax") trailingText:taxText];

    // Discounts
    NSString *discountsText = [self.taxUtil guranteedCurrencyString:[self.list calcDiscountAmount].stringValue];
    SSCellStackView *discountsCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"breakdown.vc.discounts") trailingText:discountsText];
    
    // Total
    NSString *totalText = [self.taxUtil guranteedCurrencyString:[self.list calcTotalCost].stringValue];
    SSCellStackView *cheapestCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"breakdown.vc.totalColon") trailingText:totalText];
    
    NSArray <SSCellStackView *> *stacks =  @[subTotalCellStack,
                                             taxCellStack,
                                             discountsCellStack,
                                             cheapestCellStack];

    self.labelStacks = stacks;
    
    NSArray <UIView *> *allSubViews = [@[self.totalLabel] arrayByAddingObjectsFromArray:self.labelStacks];
    [self addSubviews:allSubViews];
}

#pragma mark - Layout

- (void)setConstraints
{
    // Total Label
    [self.totalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.top.equalTo(self.mas_top).with.offset(SSTopBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
    }];
    
    // Subtotal
    [self.labelStacks[SS_IDX_SUBTOTAL] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.totalLabel.mas_bottom).with.offset(SSTopBigElementMargin);
    }];
    
    // Tax
    [self.labelStacks[SS_IDX_TAX] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.labelStacks[SS_IDX_SUBTOTAL].mas_bottom);
    }];
    
    // Discounts
    [self.labelStacks[SS_IDX_DISCOUNTS] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.labelStacks[SS_IDX_TAX].mas_bottom);
    }];
    
    // Total
    [self.labelStacks[SS_IDX_TOTAL] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.labelStacks[SS_IDX_DISCOUNTS].mas_bottom);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
    }];
}

@end
