//
//  SSListTagTotalFooterView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListSectionFooterView.h"
#import "SSCountingLabel.h"
#import "TaxUtility.h"

@interface SSListSectionFooterView()

@property (strong, nonatomic, nullable) NSString *tagDBID;
@property (strong, nonatomic, nonnull) SSLabel *totalLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *amountLabel;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSListSectionFooterView

#pragma mark - Initializer

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:nil];
        self.totalLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        self.totalLabel.textColor = [UIColor ssSecondaryColor];
        [self.totalLabel configureFontWeight:UIFontWeightMedium];
        
        self.amountLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.amountLabel.method = SSLabelCountingMethodEaseOut;
        self.amountLabel.animationDuration = SSBriefAnimationDuration;
        [self.amountLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        
        self.totalLabel.text = @"Total:";
        self.amountLabel.text = @"";
        
        [self.contentView addSubviews:@[self.totalLabel, self.amountLabel]];
        
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        self.totalLabel.textAlignment = NSTextAlignmentLeft;
        [self.totalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
        
        [self.amountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.totalLabel.mas_bottom).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.contentView.mas_bottom).with.offset(SSBottomBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
    }
    else
    {
        self.totalLabel.textAlignment = NSTextAlignmentRight;
        [self.totalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.centerY.equalTo(self.amountLabel.mas_centerY);
            make.width.equalTo(self.totalLabel.mas_width);
        }];
        
        [self.amountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.totalLabel.mas_trailing).with.offset(SSLeftBigElementMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.contentView.mas_bottom).with.offset(SSBottomBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
    }
}

- (CGFloat)estimatedHeightForHeaderInView:(UIView *)view
{
    CGFloat totalHeight = 0.0f;
    CGFloat labelWidth = view == nil ? self.boundsWidth : view.boundsWidth;
    CGFloat topPadding = SSTopBigElementMargin;
    CGFloat bottomPadding = SSTopBigElementMargin;
    
    // Total labels
    CGFloat totalLabelHeight = [self.totalLabel.text boundingRectWithWidth:labelWidth
                                                                      text:self.totalLabel.text
                                                                      font:self.totalLabel.font].size.height;
    CGFloat amountLabelHeight = [self.amountLabel.text boundingRectWithWidth:labelWidth
                                                                        text:self.amountLabel.text
                                                                        font:self.amountLabel.font].size.height;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        totalHeight = topPadding + totalLabelHeight + bottomPadding + amountLabelHeight +  bottomPadding;
    }
    else
    {
        totalHeight = topPadding + (totalLabelHeight > amountLabelHeight ? totalLabelHeight : amountLabelHeight) + bottomPadding;
    }
    
    return ceilf(totalHeight);
}

#pragma mark - Public Methods

- (void)setTotalWithTag:(SSListTag *)tag tagItems:(NSArray<SSListItem *> *)taggedItems taxInfo:(SSTaxRateInfo *)taxInfo currencyID:(NSString *)currencyID
{
    if ([self.taxUtil.localeID isEqualToString:currencyID] == NO)
    {
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:currencyID];
    }
    
    __weak typeof(self) weakSelf = self;
    self.amountLabel.formatBlock = ^NSString * _Nullable(CGFloat value) {
        return [weakSelf.taxUtil guranteedCurrencyString:@(value).stringValue];
    };
    
    self.tagDBID = tag.dbID;
    
    double total = 0;
    
    for (SSListItem *listItem in taggedItems)
    {
        total += [listItem calcTotalAmount:taxInfo taxUtil:self.taxUtil].doubleValue;
    }

    NSDecimalNumber *totalCost = [[NSDecimalNumber alloc] initWithDouble:total];
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        self.totalLabel.text = [NSString stringWithFormat:@"%@ Total:", tag.name];
    }
    else
    {
        self.totalLabel.text = @"Total:";
    }
    
    self.amountLabel.text = [self.taxUtil guranteedCurrencyString:totalCost.stringValue];
}

@end
