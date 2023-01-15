//
//  SSListItemSegmentTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemSegmentTableViewCell.h"

static const NSInteger SS_REGULAR_PRICING = 0;
static const NSInteger SS_WEIGHTED_PRICING = 1;
static const NSInteger SS_RECURRING_PRICING = 2;

@interface SSListItemSegmentTableViewCell()

@property (strong, nonatomic, nonnull) UISegmentedControl *segment;

@end

@implementation SSListItemSegmentTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.segment = [[UISegmentedControl alloc] initWithItems:@[ss_Localized(@"listEdit.regularPricing"), ss_Localized(@"listEdit.weightedPricing"), ss_Localized(@"listEdit.recurringPricing")]];
        [self.segment addTarget:self action:@selector(handleSegmentChange:) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubviews:@[self.segment]];
        
        self.dividerView.hidden = YES;
        
        [self setConstraints];
    }
    
    return self;
}

#pragma mark - Constraint Handling

- (void)setConstraints
{
    [super setConstraints];
    
    [self.segment mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView.mas_leadingMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        make.trailing.equalTo(self.contentView.mas_trailingMargin);
    }];
}

#pragma mark - Segment Handling

- (void)handleSegmentChange:(UISegmentedControl *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
    NSString *pricingMethod;
    
    if (sender.selectedSegmentIndex == SS_REGULAR_PRICING)
    {
        pricingMethod = SS_PRICING_METHOD_REGULAR;
    }
    else if(sender.selectedSegmentIndex == SS_WEIGHTED_PRICING)
    {
        pricingMethod = SS_PRICING_METHOD_WEIGHT;
    }
    else if (sender.selectedSegmentIndex == SS_RECURRING_PRICING)
    {
        pricingMethod = SS_PRICING_METHOD_RECURRING;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_METHOD_CHANGED object:pricingMethod];
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    
    NSUInteger segment = SS_REGULAR_PRICING;
    if ([item checkHasWeightedPricing])
    {
        segment = SS_WEIGHTED_PRICING;
    }
    else if ([item checkIsUsingRecurringPricing])
    {
        segment = SS_RECURRING_PRICING;
    }
    
    [self.segment setSelectedSegmentIndex:segment];
}

- (void)setActivePricingSegmentAtIndex:(NSInteger)index
{
    if (index > self.segment.numberOfSegments) return;
    [self.segment setSelectedSegmentIndex:index];
}

@end
