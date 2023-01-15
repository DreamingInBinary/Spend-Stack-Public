//
//  SSAllItemsInsightView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSAllItemsInsightView.h"
#import "SSCellStackView.h"

static const NSInteger SS_IDX_TOTAL = 0;
static const NSInteger SS_IDX_AVG = 1;
static const NSInteger SS_IDX_HIGH = 2;
static const NSInteger SS_IDX_LOW = 3;

@interface SSAllItemsInsightView()

@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nonnull) SSLabel *allItemsLabel;
@property (strong, nonatomic, nonnull) NSArray <SSCellStackView *> *labelStacks;

@end

@implementation SSAllItemsInsightView
    
#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.list = list;
        [self createViews];
        [self setConstraints];
    }
    
    return self;
}

#pragma mark - View Creation

- (void)createViews
{
    // Tag label
    self.allItemsLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
    [self.allItemsLabel configureFontWeight:UIFontWeightSemibold];
    self.allItemsLabel.text = ss_Localized(@"allItems.title");
    [self addSubview:self.allItemsLabel];
    
    // Total Items
    double count = self.list.datasourceAdapter.allItems.count;
    NSString *itemsText = [NSString stringWithFormat:@"%lu %@", (unsigned long)count, count == 1 ? ss_Localized(@"allItems.item") : ss_Localized(@"allItems.items")];
    SSCellStackView *totalCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"allItems.count") trailingText:itemsText];
    
    // Average Price
    double avg = [self.list averageItemPrice].doubleValue;
    NSString *avgText = [self.list.taxUtil guranteedCurrencyString:@(avg).stringValue];
    SSCellStackView *avgCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"allItems.average") trailingText:avgText];

    // Most Expensive
    SSListItem *expensiveItem = [self.list mostExpensiveItem];
    NSString *expensiveText = [NSString stringWithFormat:@"%@ (%@)", [self.list.taxUtil guranteedCurrencyString:[expensiveItem calcTotalAmount:self.list.taxInfo taxUtil:self.list.taxUtil].stringValue], expensiveItem.title];
    if (expensiveItem == nil) expensiveText = ss_Localized(@"allItems.na");
    SSCellStackView *expensiveCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"allitems.highest") trailingText:expensiveText];
    
    // Least Expensive
    SSListItem *cheapestItem = [self.list cheapestItem];
    NSString *cheapestText = [NSString stringWithFormat:@"%@ (%@)", [self.list.taxUtil guranteedCurrencyString:[cheapestItem calcTotalAmount:self.list.taxInfo taxUtil:self.list.taxUtil].stringValue], cheapestItem.title];
    if (cheapestItem == nil) cheapestText = ss_Localized(@"allItems.na");
    SSCellStackView *cheapestCellStack = [[SSCellStackView alloc] initWithLeadingText:ss_Localized(@"allItems.lowest") trailingText:cheapestText];
    
    self.labelStacks = @[totalCellStack,
                         avgCellStack,
                         expensiveCellStack,
                         cheapestCellStack];
    
    NSArray <UIView *> *allSubViews = [@[self.allItemsLabel] arrayByAddingObjectsFromArray:self.labelStacks];
    [self addSubviews:allSubViews];
}

#pragma mark - Layout

- (void)setConstraints
{
    // All Items Label
    [self.allItemsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.top.equalTo(self.mas_top).with.offset(SSTopBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
    }];
    
    // Total Items
    [self.labelStacks[SS_IDX_TOTAL] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.allItemsLabel.mas_bottom).with.offset(SSTopBigElementMargin);
    }];
    
    // Average Price
    [self.labelStacks[SS_IDX_AVG] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.labelStacks[SS_IDX_TOTAL].mas_bottom);
    }];
    
    // Most Expensive
    [self.labelStacks[SS_IDX_HIGH] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.labelStacks[SS_IDX_AVG].mas_bottom);
    }];
    
    // Least Expensive
    [self.labelStacks[SS_IDX_LOW] mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.labelStacks[SS_IDX_HIGH].mas_bottom);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
    }];
}

@end
