//
//  SSListItemTaxToggleTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemTaxToggleTableViewCell.h"

@interface SSListItemTaxToggleTableViewCell()

@property (strong, nonatomic, nonnull) SSLabel *taxLabel;
@property (strong, nonatomic, nonnull) SSLabel *taxAmountLabel;
@property (strong, nonatomic, nonnull) UISwitch *taxToggleSwitch;

@end

@implementation SSListItemTaxToggleTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.taxLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.taxLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [self.taxLabel configureFontWeight:UIFontWeightMedium];
        self.taxAmountLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleFootnote];
        self.taxAmountLabel.textColor = [UIColor ssSecondaryColor];
        self.taxToggleSwitch = [UISwitch new];
        self.taxToggleSwitch.onTintColor = [UIColor ssPrimaryColor];
        [self.taxToggleSwitch addTarget:self action:@selector(onToggleChanged:) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubviews:@[self.taxLabel, self.taxAmountLabel, self.taxToggleSwitch]];
        
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferredContentSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    return self;
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    [super setConstraints];
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.taxLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.height.and.width.equalTo(self.taxLabel);
        }];
        
        [self.taxAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.taxLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
        
        [self.taxToggleSwitch mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.height.and.width.equalTo(self.taxToggleSwitch);
            make.top.equalTo(self.taxAmountLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
    else
    {
        [self.taxLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.width.equalTo(self.contentView.mas_width).multipliedBy(0.84f);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.height.equalTo(self.taxLabel);
        }];
        
        [self.taxAmountLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.taxLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.taxToggleSwitch mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView.mas_trailingMargin).with.priorityHigh();
            make.height.and.width.equalTo(self.taxToggleSwitch);
            make.centerY.equalTo(self.contentView.mas_centerY);
        }];
    }
}

#pragma mark - Private Methods

- (void)onToggleChanged:(UISwitch *)sender
{
    self.listItem.hasTaxApplied = sender.isOn;
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICE_AMOUNT_CHANGED object:nil];
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    
    self.taxLabel.text = [NSString stringWithFormat:ss_Localized(@"listEdit.include"), self.taxUtil.localizedTaxRateString];
    
    [self.taxToggleSwitch setOn:item.hasTaxApplied];
    self.taxToggleSwitch.enabled = YES;
    
    if (list.taxInfo.taxIsEnabled)
    {
        self.taxAmountLabel.text = list.taxInfo.taxRateStringValue;
    }
    else
    {
        self.taxAmountLabel.text = ss_Localized(@"listEdit.noTax");
        self.taxToggleSwitch.enabled = NO;
    }
}

@end
