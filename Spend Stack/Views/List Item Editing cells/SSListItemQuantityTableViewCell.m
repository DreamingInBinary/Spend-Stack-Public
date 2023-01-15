//
//  SSListItemQuantityTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemQuantityTableViewCell.h"

@interface SSListItemQuantityTableViewCell()

@property (strong, nonatomic, nonnull) SSLabel *leftTitleLabel;
@property (strong, nonatomic, nonnull) UIStepper *stepper;

@end

@implementation SSListItemQuantityTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.leftTitleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.leftTitleLabel configureFontWeight:UIFontWeightMedium];
        
        self.stepper = [UIStepper new];
        self.stepper.minimumValue = 1;
        self.stepper.maximumValue = 999;
        [self.stepper addTarget:self action:@selector(onStepperChanged:) forControlEvents:UIControlEventValueChanged];
        
        [self.contentView addSubviews:@[self.leftTitleLabel, self.stepper]];
        
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
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
        
        [self.stepper mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.leftTitleLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
            make.width.and.height.equalTo(self.stepper);
        }];
    }
    else
    {
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.right.equalTo(self.stepper.mas_left).with.offset(SSRightElementMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.stepper mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.width.and.height.equalTo(self.stepper);
        }];
    }
}

#pragma mark - Handle Steps

- (void)onStepperChanged:(UIStepper *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
    self.leftTitleLabel.text = @(sender.value).stringValue;
    self.listItem.quantity = @(sender.value).integerValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICE_AMOUNT_CHANGED object:nil];
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    self.stepper.value = item.quantity;
    self.leftTitleLabel.text = @(item.quantity).stringValue;
}

@end
