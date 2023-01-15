//
//  SSListItemPriceDataTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/19/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemPriceDataTableViewCell.h"
#import "SSListItemTableControllerAdapter.h"
#import "UIView+Animations.h"
#import "UITextField+NegativeInput.h"
#import "Spend_Stack_2-Swift.h"

static NSArray<SSToolBarItem *> *toolBarItemsForPriceEntry() {
    NSArray <SSToolBarItem *> *items = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @[SSToolBarItemTypeDoubleZero, SSToolBarItemTypePlusMinus, SSToolBarItemTypeFlexSpace] : @[SSToolBarItemTypeDoubleZero, SSToolBarItemTypePlusMinus, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeKeyboardDown];
    return items;
}

static NSArray<SSToolBarItem *> *toolBarItemsForDiscountEntry() {
    NSArray <SSToolBarItem *> *items = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @[SSToolBarItemTypeDoubleZero,  SSToolBarItemTypeFlexSpace] : @[SSToolBarItemTypeDoubleZero, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeKeyboardDown];
    return items;
}

@interface SSListItemPriceDataTableViewCell()

@property (strong, nonatomic, nonnull) SSToolbar *tb;
@property (strong, nonatomic, nonnull) SSLabel *leftTitleLabel;
@property (strong, nonatomic, nonnull) SSTextField *rightAmountTextField;
@property (strong, nonatomic, nonnull) SSLabel *editRecurringCostLabel;
@property (strong, nonatomic, nonnull) NSMeasurementFormatter *measurementFormatter;

@end

@implementation SSListItemPriceDataTableViewCell

#pragma mark - Custom Getters

- (BOOL)textViewIsFirstResponder
{
    return self.rightAmountTextField.isFirstResponder;
}

- (NSMeasurementFormatter *)measurementFormatter
{
    if (!_measurementFormatter)
    {
        _measurementFormatter = [NSMeasurementFormatter new];
        _measurementFormatter.locale = [NSLocale currentLocale];
    }
    
    return _measurementFormatter;
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.leftTitleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.leftTitleLabel configureFontWeight:UIFontWeightMedium];
        self.rightAmountTextField = [[SSTextField alloc] initWithTextStyle:UIFontTextStyleBody];
        self.rightAmountTextField.textAlignment = NSTextAlignmentRight;
        self.rightAmountTextField.keyboardType = UIKeyboardTypeNumberPad;
        [self.rightAmountTextField setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.rightAmountTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        
        self.editRecurringCostLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.editRecurringCostLabel.userInteractionEnabled = YES;
        self.editRecurringCostLabel.accessibilityTraits = UIAccessibilityTraitButton;
        self.editRecurringCostLabel.text = ss_Localized(@"listEdit.monthly");
        self.editRecurringCostLabel.textColor = [UIColor ssPrimaryColor];
        self.editRecurringCostLabel.hidden = YES;
        [self.editRecurringCostLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(highlightTapAndPresentCycleEditor)]];
        [self.editRecurringCostLabel configureFontWeight:UIFontWeightMedium];
        
        self.tb = [[SSToolbar alloc] initWithItemTypes:toolBarItemsForPriceEntry()];
        __weak SSListItemPriceDataTableViewCell *weakSelf = self;
        self.tb.onKeyboardDown = ^{
            [weakSelf.rightAmountTextField resignFirstResponder];
        };
        self.tb.onDoubleZero = ^{
            weakSelf.rightAmountTextField.text = [weakSelf.rightAmountTextField.text stringByAppendingString:@"00"];
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification
                                                                object:weakSelf.rightAmountTextField];
        };
        self.tb.onPlusMinus = ^{
            weakSelf.rightAmountTextField.enteringNegativeNumber = !weakSelf.rightAmountTextField.enteringNegativeNumber;
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification
                                                                object:weakSelf.rightAmountTextField];
        };
        self.tb.clipsToBounds = NO;
        self.rightAmountTextField.inputAccessoryView = self.tb;
        
        [self.contentView addSubviews:@[self.leftTitleLabel,
                                        self.rightAmountTextField,
                                        self.editRecurringCostLabel]];
        
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldDidChangeNotification:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:self.rightAmountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTextViewBeganEditing:)
                                                     name:UITextFieldTextDidBeginEditingNotification
                                                   object:self.rightAmountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTextViewDidEndEditing:)
                                                     name:UITextFieldTextDidEndEditingNotification
                                                   object:self.rightAmountTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(beginEnterDiscountAmount:)
                                                     name:SS_PRICING_ENTER_DISCOUNT
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(beginEnterWeightAmount:)
                                                     name:SS_PRICING_ENTER_WEIGHT
                                                   object:nil];
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
    
    self.rightAmountTextField.textAlignment = [SSCitizenship accessibilityFontsEnabled] ? NSTextAlignmentLeft : NSTextAlignmentRight;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
        
        [self.rightAmountTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.leftTitleLabel.mas_bottom).with.offset(SSBottomElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.editRecurringCostLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.leftTitleLabel.mas_bottom).with.offset(SSBottomElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
    else
    {
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.rightAmountTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.left.equalTo(self.leftTitleLabel.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
        
        [self.editRecurringCostLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.left.equalTo(self.leftTitleLabel.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
}

#pragma mark - Text Field and Item Mutation

- (void)handleTextViewBeganEditing:(NSNotification *)notification
{
    // Handle toolbar item types
    if (self.type == SSListItemPriceDataDisplayTypeBaseAmount)
    {
        NSArray<SSToolBarItem *> * items = toolBarItemsForPriceEntry();
        [self.tb setToolBarItems:items];
    }
    else if (self.type == SSListItemPriceDataDisplayTypeDiscount && [self.listItem checkHasDiscountAmountApplied])
    {
        NSArray<SSToolBarItem *> * items = toolBarItemsForDiscountEntry();
        [self.tb setToolBarItems:items];
    }
    else if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
    {
        // Keyboard down is unnecessary on iPad
        [self.tb setToolBarItems:@[SSToolBarItemTypeFlexSpace,
                                   SSToolBarItemTypeKeyboardDown]];
    }
    
    if (self.type == SSListItemPriceDataDisplayTypeBaseAmount)
    {
        if ([self.listItem checkHasWeightedPricing])
        {
            // If we have weighted pricing, strip off the "per lb/kg/etc" for entry
            self.rightAmountTextField.text = [self.taxUtil guranteedCurrencyString:self.listItem.baseAmount.stringValue];
            return;
        }
        
        if ([self.listItem checkIsNegativeAmount])
        {
            // Strip off the accounting stlye negative ($3.22) to -$3.22
            self.rightAmountTextField.text = [self.rightAmountTextField.text stringByReplacingOccurrencesOfString:@"(" withString:@""];
            self.rightAmountTextField.text = [self.rightAmountTextField.text stringByReplacingOccurrencesOfString:@")" withString:@""];
            self.rightAmountTextField.enteringNegativeNumber = YES;
            
            if (self.taxUtil.localeHasTrailingCurrencyFormat)
            {
                self.rightAmountTextField.selectedTextRange = [self.taxUtil selectTextRangeForPriceTextField:self.rightAmountTextField];
            }
            
            return;
        }
    }
    
    if ((self.type == SSListItemPriceDataDisplayTypeDiscount ||
         self.type == SSListItemPriceDataDisplayTypeWeight) == NO)
    {
        if (self.taxUtil.localeHasTrailingCurrencyFormat)
        {
            self.rightAmountTextField.selectedTextRange = [self.taxUtil selectTextRangeForPriceTextField:self.rightAmountTextField];
        }
        
        return;
    }
    
    if (self.listItem.discountPercentage != nil)
    {
        if (self.listItem.discountPercentage.integerValue <= 0)
        {
            self.rightAmountTextField.text = [self.taxUtil guranteedCurrencyString:self.listItem.discountPercentage.stringValue];
        }
    }
    else if ([self.listItem checkHasWeightedPricing])
    {
        // Strip the locale's mass noun for easier text manipulation
        if (self.listItem.weight.doubleValue > 0)
        {
            self.rightAmountTextField.text = @(self.listItem.weight.doubleValue).stringValue;
        }
    }
}

- (void)handleTextViewDidEndEditing:(NSNotification *)notification
{
    if (self.type == SSListItemPriceDataDisplayTypeBaseAmount)
    {
        if ([self.listItem checkHasWeightedPricing])
        {
            // If we have weighed pricing, put back the "per lb/kg/etc"
            NSAssert(self.list != nil, @"List is nil.");
            [self setData:self.listItem list:self.list];
            return;
        }
    }
    
    if ((self.type == SSListItemPriceDataDisplayTypeDiscount ||
         self.type == SSListItemPriceDataDisplayTypeWeight) == NO) return;
    
    // Input validation. If 0 or NaN, kill it.
    BOOL isInvalid;
    if (self.listItem.discountAmount != nil)
    {
        isInvalid = (isnan(self.listItem.discountAmount.floatValue) || self.listItem.discountAmount.floatValue == 0);
        
        if (isInvalid)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF object:nil];
        }
    }
    
    if (self.listItem.discountPercentage != nil)
    {
        isInvalid = (isnan(self.listItem.discountPercentage.floatValue) || self.listItem.discountPercentage.floatValue == 0);
        
        if (isInvalid)
        {
            self.rightAmountTextField.text = @"";
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF object:nil];
        }
        else
        {
            NSString *percentString = [NSString stringWithFormat:@"%@%%", self.listItem.discountPercentage.stringValue];
            self.rightAmountTextField.text = percentString;
        }
    }
    
    if (self.listItem.weight != nil)
    {
        isInvalid = (isnan(self.listItem.weight.doubleValue) || self.listItem.weight.doubleValue == 0);
        
        if (isInvalid)
        {
            self.rightAmountTextField.text = @"";
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_WEIGHT_ENTRY_WAS_INVALID object:nil];
        }
        else
        {
            [self setData:self.listItem list:self.list];
        }
    }
    
}

- (void)textFieldDidChangeNotification:(NSNotification *)note
{
    if (self.textViewIsFirstResponder == NO)
    {
        return;
    }

    SSTextField *changedTextField = note.object;
    if ([changedTextField isKindOfClass:[SSTextField class]] == NO) return;
    
    // Double comma input validtion no matter the scenario
    NSArray *textCommaComponents = [changedTextField.text componentsSeparatedByString:@"."];
    BOOL textHasMultipleCommas = textCommaComponents.count > 2;
    if (textHasMultipleCommas)
    {
        // Strip the last one
        [changedTextField bumpRightToLeft];
        changedTextField.text = [NSString stringWithFormat:@"%@.%@", textCommaComponents[0],textCommaComponents[1]];
        return;
    }
    
    // Entering price, discount or weight?
    if (self.type == SSListItemPriceDataDisplayTypeBaseAmount)
    {
        [self handleTextFieldChangeForPriceEntry:changedTextField];
        
        if (self.taxUtil.localeHasTrailingCurrencyFormat)
        {
            self.rightAmountTextField.selectedTextRange = [self.taxUtil selectTextRangeForPriceTextField:self.rightAmountTextField];
        }
    }
    else if (self.type == SSListItemPriceDataDisplayTypeDiscount)
    {
        [self handleTextFieldChangeForDiscountEntry:changedTextField];
    }
    else if (self.type == SSListItemPriceDataDisplayTypeWeight)
    {
        [self handleTextFieldChangeForWeightedEntry:changedTextField];
    }
}

- (void)handleTextFieldChangeForPriceEntry:(SSTextField *)changedTextField
{
    changedTextField.text = [self.taxUtil currencyStringFromInput:changedTextField.text];
    
    // Ensure default values
    NSString *amountAsString = @"0";
    if (changedTextField.text.length <= 0)
    {
        changedTextField.text = [self.taxUtil guranteedCurrencyString:@"0"];
    }
    else
    {
        amountAsString = [changedTextField.text stringByReplacingOccurrencesOfString:self.taxUtil.currencyLocale.currencySymbol withString:@""];
        
        if (changedTextField.enteringNegativeNumber)
        {
            // Ensure the amount that's parsed for the data is negative, then after the fact tack it on the textfield.
            amountAsString = [NSString stringWithFormat:@"-%@", amountAsString];
        }

        changedTextField.text = [self.taxUtil currencyStringFromInput:amountAsString];
        
        if (changedTextField.enteringNegativeNumber)
        {
            [changedTextField prefixNegativeSignToText];
        }
    }
    
    NSDecimalNumber *itemAmount = [self.taxUtil priceDecimalFromString:amountAsString];
    self.listItem.baseAmount = itemAmount;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICE_AMOUNT_CHANGED object:nil];
}

- (void)handleTextFieldChangeForDiscountEntry:(SSTextField *)changedTextField
{
    // Ensure default values
    NSString *amountAsString = @"0";

    if (self.listItem.discountAmount != nil)
    {
        changedTextField.text = [self.taxUtil currencyStringFromInput:changedTextField.text];
        
        if (changedTextField.text.length <= 0)
        {
            changedTextField.text = [self.taxUtil guranteedCurrencyString:@"0"];
        }
        else
        {
            amountAsString = [changedTextField.text stringByReplacingOccurrencesOfString:self.taxUtil.currencyLocale.currencySymbol withString:@""];
        }

        NSDecimalNumber *discountAmount = [self.taxUtil priceDecimalFromString:amountAsString];
        self.listItem.discountAmount = discountAmount;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICE_AMOUNT_CHANGED object:nil];
        return;
    }
    
    if (self.listItem.discountPercentage != nil)
    {
        amountAsString = [changedTextField.text stringByReplacingOccurrencesOfString:@"%" withString:@""];
        NSDecimalNumber *itemDiscountPercent = [NSDecimalNumber decimalNumberWithString:amountAsString locale:self.taxUtil.currencyLocale];
        self.listItem.discountPercentage = itemDiscountPercent;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICE_AMOUNT_CHANGED object:nil];
        return;
    }
}

- (void)handleTextFieldChangeForWeightedEntry:(SSTextField *)changedTextField
{
    double rawValue = changedTextField.text.doubleValue;
    self.listItem.weight = [NSMeasurement measurementWithValue:rawValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICE_AMOUNT_CHANGED object:nil];
}

- (void)beginEnterDiscountAmount:(NSNotification *)notification
{
    if (self.type != SSListItemPriceDataDisplayTypeDiscount) return;
    self.rightAmountTextField.text = @"";
    [self handleTextFieldChangeForDiscountEntry:self.rightAmountTextField];
    [self.rightAmountTextField becomeFirstResponder];
}

- (void)beginEnterWeightAmount:(NSNotification *)notification
{
    if (self.type != SSListItemPriceDataDisplayTypeWeight) return;
    self.rightAmountTextField.text = @"";
    [self.rightAmountTextField becomeFirstResponder];
}

#pragma mark - Cycle Editor

- (void)presentCycleEditor
{
    __weak typeof(self) weakSelf = self;
    RecurringCostEditorViewController *editorVC = [[RecurringCostEditorViewController alloc] initWithListItem:weakSelf.listItem onDimiss:^(NSInteger frequency, ListItemRecurringPricingChoice choice) {
        weakSelf.listItem.recurringPricingCycle = choice;
        weakSelf.listItem.recurringPricingFrequency = @(frequency);
        
        NSIndexPath *recurringCostIDP = [NSIndexPath indexPathForRow:1
                                                           inSection:SECTION_PRICING];
        [weakSelf.containingTableView reloadRowsAtIndexPaths:@[recurringCostIDP]
                                            withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    __kindof UINavigationController *navVC;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        navVC = [[SSNavigationController alloc] initWithRootViewController:editorVC];
        
        navVC.popoverPresentationController.sourceView = self.editRecurringCostLabel;
        navVC.modalPresentationStyle = UIModalPresentationPopover;
        navVC.popoverPresentationController.sourceView = self.contentView;
        navVC.popoverPresentationController.sourceRect = CGRectMake(self.editRecurringCostLabel.ss_x, self.contentView.boundsHeight/2, 0, 0);
        navVC.preferredContentSize = CGSizeMake(340, 200);
        navVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionRight;
    }
    else
    {
        navVC = [[SSBottomNavigationViewController alloc] initWithRootViewController:editorVC];
    }
    
    [weakSelf.closestViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)highlightTapAndPresentCycleEditor
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    [self.editRecurringCostLabel dimInFromTapAnimationWithHighlight:SSSpacingMargin];
    __weak typeof(self) weakSelf = self;
    self.editRecurringCostLabel.onAnimationFinished = ^{
        [weakSelf presentCycleEditor];
    };
}

#pragma mark - Public Methods

- (void)makePriceEntryTextViewFirstResponder
{
    if (self.textViewIsFirstResponder == NO)
    {
        [self.rightAmountTextField becomeFirstResponder];
    }
}

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    
    self.rightAmountTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.rightAmountTextField.hidden = NO;
    self.rightAmountTextField.userInteractionEnabled = YES;
    self.editRecurringCostLabel.hidden = YES;
    
    switch (self.type)
    {
        case SSListItemPriceDataDisplayTypeBaseAmount:
        {
            self.leftTitleLabel.text = ss_Localized(@"listEdit.price");
            self.rightAmountTextField.text = [self.taxUtil currencyString:item.baseAmount.stringValue];
            self.rightAmountTextField.textColor = [UIColor ssMainFontColor];
            self.rightAmountTextField.enabled = YES;
            self.rightAmountTextField.placeholder = [self.taxUtil guranteedCurrencyString:@"0"];
            
            if ([self.listItem checkHasWeightedPricing])
            {
                // !!!: Might be a better way to grab the localized mass unit
                NSString *massUnit = [[self.measurementFormatter stringFromMeasurement:self.listItem.weight] componentsSeparatedByString:@" "].lastObject;
                NSString *priceText = [self.rightAmountTextField.text stringByAppendingString:[NSString stringWithFormat:ss_Localized(@"listEdit.per"), massUnit]];
                
                self.rightAmountTextField.text = priceText;
            }
            break;
        }
        case SSListItemPriceDataDisplayTypeSubtotalAmount:
        {
            self.leftTitleLabel.text = ss_Localized(@"listEdit.subtotal");
            self.rightAmountTextField.text = [self.taxUtil guranteedCurrencyString:[item calcSubtotalAmount].stringValue];
            self.rightAmountTextField.textColor = [UIColor ssSecondaryColor];
            self.rightAmountTextField.enabled = NO;
            break;
        }
        case SSListItemPriceDataDisplayTypeWeight:
        {
            self.rightAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
            self.leftTitleLabel.text = ss_Localized(@"listEdit.weight");
            self.rightAmountTextField.text = [self.measurementFormatter stringFromMeasurement:self.listItem.weight];
            if (self.listItem.weight.doubleValue > 1)
            {
                self.rightAmountTextField.text = [self.rightAmountTextField.text stringByAppendingString:@"s"];
            }
            self.rightAmountTextField.textColor = [UIColor ssMainFontColor];
            self.rightAmountTextField.enabled = [self.listItem checkHasWeightedPricing];
            self.rightAmountTextField.placeholder = [self.measurementFormatter stringFromMeasurement:[NSMeasurement measurementWithValue:0]];
            break;
        }
        case SSListItemPriceDataDisplayTypeRecurring:
        {
            self.leftTitleLabel.text = ss_Localized(@"listEdit.cycle");
            self.rightAmountTextField.hidden = YES;
            self.rightAmountTextField.userInteractionEnabled = NO;
            self.editRecurringCostLabel.hidden = NO;
            self.editRecurringCostLabel.text = [self.listItem recurringPriceDisplayString];
            break;
        }
        case SSListItemPriceDataDisplayTypeDiscount:
        {
            self.leftTitleLabel.text = ss_Localized(@"listEdit.discount");
            self.rightAmountTextField.textColor = [UIColor ssMainFontColor];
            self.rightAmountTextField.enabled = [self.listItem checkHasDiscountApplied];
            if (item.discountAmount != nil)
            {
                if (isnan(item.discountAmount.floatValue) == NO)
                {
                    self.rightAmountTextField.text = [self.taxUtil currencyString:item.discountAmount.stringValue];
                }
  
                self.rightAmountTextField.placeholder = [self.taxUtil guranteedCurrencyString:@"0"];
            }
            else if (item.discountPercentage != nil)
            {
                if (isnan(item.discountPercentage.floatValue) == NO)
                {
                    NSString *percentString = [NSString stringWithFormat:@"%@%%",item.discountPercentage.stringValue];
                    self.rightAmountTextField.text = percentString;
                }
                
                self.rightAmountTextField.keyboardType = UIKeyboardTypeDecimalPad;
                self.rightAmountTextField.placeholder = @"0.00%";
            }
            
            break;
        }
        case SSListItemPriceDataDisplayTypeTaxAmount:
        {
            self.leftTitleLabel.text = ss_Localized(@"listEdit.tax");
            if (item.hasTaxApplied)
            {
                self.rightAmountTextField.text = [self.taxUtil guranteedCurrencyString:[self.listItem calcTaxedAmount:self.taxRateInfo taxUtil:list.taxUtil].stringValue];
            }
            else
            {
                self.rightAmountTextField.text = @"––";
            }
            self.rightAmountTextField.textColor = [UIColor ssSecondaryColor];
            self.rightAmountTextField.enabled = NO;
            break;
        }
        case SSListItemPriceDataDisplayTypeTotalAmount:
        {
            self.leftTitleLabel.text = ss_Localized(@"listEdit.total");
            self.rightAmountTextField.text = [self.taxUtil guranteedCurrencyString:[item calcTotalAmount:self.taxRateInfo taxUtil:list.taxUtil].stringValue];
            self.rightAmountTextField.textColor = [UIColor ssSecondaryColor];
            self.rightAmountTextField.enabled = NO;
            break;
        }
        case SSListItemPriceDataDisplayTypeUnknown:
        {
            self.leftTitleLabel.text = @"";
            self.rightAmountTextField.text = @"";
            self.rightAmountTextField.enabled = NO;
            break;
        }
        default:
            break;
    }
    
    if (self.type == SSListItemPriceDataDisplayTypeTotalAmount)
    {
        [self.leftTitleLabel configureFontWeight:UIFontWeightSemibold];
        [self.rightAmountTextField configureFontWeight:UIFontWeightSemibold];
    }
    else
    {
        [self.leftTitleLabel configureFontWeight:UIFontWeightRegular];
        [self.rightAmountTextField configureFontWeight:UIFontWeightRegular];
    }
}

@end
