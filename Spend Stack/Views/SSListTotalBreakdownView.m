//
//  SSListTotalBreakdownView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListTotalBreakdownView.h"
#import "SSConstants.h"
#import "SSCountingLabel.h"

@interface SSListTotalBreakdownView()

@property (strong, nonatomic, nonnull) SSCountingLabel *subtotalTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *taxTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *discountsTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *totalTextLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *subtotalAmountLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *taxAmountLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *discountsAmountLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *totalAmountLabel;
@property (strong, nonatomic, nonnull) UIView *containerView;
@property (strong, nonatomic, nonnull) UIView *dividerView;

@end

@implementation SSListTotalBreakdownView

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        NSDictionary <NSString *, SSCountingLabel *> *labels = [SSListTotalBreakdownView labelsForListBreakdown:@""];
        
        self.subtotalTextLabel = labels[SS_SUBTOTAL_LABEL];
        self.taxTextLabel = labels[SS_TAX_TOTAL_LABEL];
        self.discountsTextLabel = labels[SS_DISCOUNT_LABEL];
        self.totalTextLabel = labels[SS_TOTAL_LABEL];
        
        self.subtotalAmountLabel = labels[SS_SUBTOTAL_AMOUNT_LABEL];
        self.taxAmountLabel = labels[SS_TAX_TOTAL_AMOUNT_LABEL];
        self.discountsAmountLabel = labels[SS_DISCOUNT_AMOUNT_LABEL];
        self.totalAmountLabel = labels[SS_TOTAL_AMOUNT_LABEL];
        
        self.containerView = [UIView new];
        
        self.dividerView = [UIView new];
        self.dividerView.backgroundColor = [UIColor ssMainFontColor];
        
        [self addSubview:self.containerView];
        [self.containerView addSubviews:@[self.subtotalTextLabel, self.taxTextLabel, self.discountsTextLabel, self.totalTextLabel, self.subtotalAmountLabel, self.taxAmountLabel, self.discountsAmountLabel, self.totalAmountLabel, self.dividerView]];
        
        [self setConstraints];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    return self;
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [NSLayoutConstraint deactivateConstraints:self.constraints];
    [self setConstraints];
}

- (void)setConstraints
{
    [self.containerView setMas_key:@"containerView"];
    [self.dividerView setMas_key:@"dividerView"];
    BOOL isUS = [[NSLocale currentLocale].localeIdentifier isEqualToString:@"en_US"];
    
    [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_top);
        make.bottom.equalTo(self.mas_bottom);
        make.centerX.equalTo(self.mas_centerX);
        make.width.equalTo(self.mas_width).multipliedBy(0.50f);
    }];
    
    // Label constraints
    [self.subtotalTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView.mas_left);
        make.top.equalTo(self.containerView.mas_top);
    }];
    
    [self.subtotalAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView.mas_right);
        make.left.equalTo(self.subtotalTextLabel.mas_right).with.offset(SSLeftElementMargin);
        make.top.equalTo(self.containerView.mas_top);
    }];
    
    // Tax
    [self.taxTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.subtotalTextLabel.mas_left);
        make.top.equalTo(self.subtotalAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        if (isUS == NO) make.height.equalTo(@0);
    }];
    
    [self.taxAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.subtotalAmountLabel.mas_right);
        make.left.equalTo(self.taxTextLabel.mas_right).with.offset(SSLeftElementMargin);
        make.top.equalTo(self.subtotalAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
        if (isUS == NO) make.height.equalTo(@0);
    }];
    
    // Discounts
    [self.discountsTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.subtotalTextLabel.mas_left);
        make.top.equalTo(self.taxAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
    }];
    
    [self.discountsAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.subtotalAmountLabel.mas_right);
        make.left.equalTo(self.discountsTextLabel.mas_right).with.offset(SSLeftElementMargin);
        make.top.equalTo(self.taxAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
    }];
    
    [self.dividerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(.5));
        make.centerX.equalTo(self.containerView.mas_centerX);
        make.width.equalTo(self.containerView.mas_width);
        make.top.equalTo(self.discountsAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
    }];
    
    // Total
    [self.totalTextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.subtotalTextLabel.mas_left);
        make.top.equalTo(self.dividerView.mas_bottom).with.offset(SSTopElementMargin);
        make.bottom.equalTo(self.containerView.mas_bottom);
    }];
    
    [self.totalAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.subtotalAmountLabel.mas_right);
        make.left.equalTo(self.totalTextLabel.mas_right).with.offset(SSLeftElementMargin);
        make.top.equalTo(self.dividerView.mas_bottom).with.offset(SSTopElementMargin);
        make.bottom.equalTo(self.containerView.mas_bottom);
    }];
}

#pragma mark - Sizing

- (CGFloat)estimatedHeightForListTotalHeaderInView:(UIView *)view
{
    CGFloat totalHeight = 0.0f;
    CGFloat labelWidth = view == nil ? self.boundsWidth : view.boundsWidth;
    CGFloat topPadding = SSTopElementMargin;
    
    // Add up subtotal
    CGFloat subTotalHeight = [self.subtotalAmountLabel.text boundingRectWithWidth:labelWidth
                                                                             text:self.subtotalAmountLabel.text
                                                                             font:self.subtotalAmountLabel.font].size.height;
    totalHeight += subTotalHeight;
    
    // Gap + tax total
    CGFloat taxTotalHeight = [self.taxAmountLabel.text boundingRectWithWidth:labelWidth
                                                                        text:self.taxAmountLabel.text
                                                                        font:self.taxAmountLabel.font].size.height;
    totalHeight += taxTotalHeight + topPadding;
    
    // Gap + discounts
    CGFloat discountsHeight = [self.discountsAmountLabel.text boundingRectWithWidth:labelWidth
                                                                               text:self.discountsAmountLabel.text
                                                                               font:self.discountsAmountLabel.font].size.height;
    totalHeight += discountsHeight + topPadding;
    
    // Gap + divider
    CGFloat dividerHeight = self.dividerView.ss_height;
    totalHeight += dividerHeight + topPadding;
    
    // Gap + total
    CGFloat totalAmountHeight = [self.totalAmountLabel.text boundingRectWithWidth:labelWidth
                                                                             text:self.totalAmountLabel.text
                                                                             font:self.totalAmountLabel.font].size.height;
    totalHeight += discountsHeight + topPadding;
    totalHeight += totalAmountHeight + topPadding;
    
    return ceilf(totalHeight);
}

#pragma mark - Public Methods

- (void)updateUIForList:(SSList *)list
{
    TaxUtility *taxUtil = [[TaxUtility alloc] initWithLocaleID:list.currencyIdentifier];
    if (self.totalAmountLabel.text == nil)
    {
        self.subtotalAmountLabel.text = [taxUtil guranteedCurrencyString:[list calcBaseCost].stringValue];
        self.taxAmountLabel.text = [taxUtil guranteedCurrencyString:[list calcTaxAmount].stringValue];
        self.discountsAmountLabel.text = [taxUtil guranteedCurrencyString:[list calcDiscountAmount].stringValue];
        self.totalAmountLabel.text = [taxUtil guranteedCurrencyString:[list calcTotalCost].stringValue];
    }
    else
    {
        [self.subtotalAmountLabel countFromCurrentValueTo:[list calcBaseCost].floatValue];
        [self.taxAmountLabel countFromCurrentValueTo:[list calcTaxAmount].floatValue];
        [self.discountsAmountLabel countFromCurrentValueTo:[list calcDiscountAmount].floatValue];
        [self.totalAmountLabel countFromCurrentValueTo:[list calcTotalCost].floatValue];
    }
}

// Since this view has almost the same labels as the one in the SSListBreakdownViewController
// We just create them in one place here to avoid duplication. Embedding this view doesn't work
// Well outside of a table view header, which is why we create the labels separately.
+ (NSDictionary <NSString *, SSCountingLabel *> *)labelsForListBreakdown:(NSString *)currencyID
{
    TaxUtility *taxUtil = [[TaxUtility alloc] initWithLocaleID:currencyID];
    
    SSCountingLabel *subtotalTextLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    SSCountingLabel *taxTextLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    SSCountingLabel *discountsTextLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    SSCountingLabel *totalTextLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    [totalTextLabel configureFontWeight:UIFontWeightSemibold];
    
    SSCountingLabel *subtotalAmountLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    [subtotalAmountLabel configureFontWeight:UIFontWeightSemibold];
    SSCountingLabel *taxAmountLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    [taxAmountLabel configureFontWeight:UIFontWeightSemibold];
    SSCountingLabel *discountsAmountLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    [discountsAmountLabel configureFontWeight:UIFontWeightSemibold];
    SSCountingLabel *totalAmountLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    [totalAmountLabel configureFontWeight:UIFontWeightSemibold];
    
    // Amounts are right aligned. Will need to revisit for internationalization and RTL languages.
    subtotalAmountLabel.textAlignment = NSTextAlignmentRight;
    taxAmountLabel.textAlignment = NSTextAlignmentRight;
    discountsAmountLabel.textAlignment = NSTextAlignmentRight;
    totalAmountLabel.textAlignment = NSTextAlignmentRight;
    
    // The chances are higher the text here could be long, give them the lower resistance
    [subtotalAmountLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [taxAmountLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [discountsAmountLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [totalAmountLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    subtotalTextLabel.text = ss_Localized(@"breakdown.subtotal");
    subtotalTextLabel.textColor = [UIColor ssTextPlaceholderColor];
    taxTextLabel.text = ss_Localized(@"breakdown.tax");
    taxTextLabel.textColor = [UIColor ssTextPlaceholderColor];
    discountsTextLabel.text = ss_Localized(@"breakdown.discounts");
    discountsTextLabel.textColor = [UIColor ssTextPlaceholderColor];
    totalTextLabel.text = ss_Localized(@"breakdown.total");
    
    // Counting Setup
    subtotalAmountLabel.method = SSLabelCountingMethodEaseOut;
    subtotalAmountLabel.animationDuration = SSBriefAnimationDuration;
    subtotalAmountLabel.formatBlock = ^NSString * _Nullable(CGFloat value) {
        return [taxUtil guranteedCurrencyString:@(value).stringValue];
    };
    
    taxAmountLabel.method = SSLabelCountingMethodEaseOut;
    taxAmountLabel.animationDuration = SSBriefAnimationDuration;
    taxAmountLabel.formatBlock = ^NSString * _Nullable(CGFloat value) {
        return [taxUtil guranteedCurrencyString:@(value).stringValue];
    };
    
    discountsAmountLabel.method = SSLabelCountingMethodEaseOut;
    discountsAmountLabel.animationDuration = SSBriefAnimationDuration;
    discountsAmountLabel.formatBlock = ^NSString * _Nullable(CGFloat value) {
        return [taxUtil guranteedCurrencyString:@(value).stringValue];
    };
    
    totalAmountLabel.method = SSLabelCountingMethodEaseOut;
    totalAmountLabel.animationDuration = SSBriefAnimationDuration;
    totalAmountLabel.formatBlock = ^NSString * _Nullable(CGFloat value) {
        return [taxUtil guranteedCurrencyString:@(value).stringValue];
    };
    
    NSDictionary <NSString *, SSCountingLabel *> *returnValue =@{SS_SUBTOTAL_LABEL:subtotalTextLabel,
                                                         SS_SUBTOTAL_AMOUNT_LABEL:subtotalAmountLabel,
                                                         SS_TAX_TOTAL_LABEL:taxTextLabel,
                                                         SS_TAX_TOTAL_AMOUNT_LABEL:taxAmountLabel,
                                                         SS_DISCOUNT_LABEL:discountsTextLabel,
                                                         SS_DISCOUNT_AMOUNT_LABEL:discountsAmountLabel,
                                                         SS_TOTAL_LABEL:totalTextLabel,
                                                         SS_TOTAL_AMOUNT_LABEL:totalAmountLabel
                                                         };
    
    return returnValue;
}

@end
