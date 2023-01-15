//
//  TaxUtility.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/26/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "TaxUtility.h"
#import "SSConstants.h"
#import "NSLocale+Utils.h"

// Static locale tax strings
static NSString * _Nonnull const VAT_SWITZERLAND = @"7.7";

@interface TaxUtility()

@property (strong, nonatomic, readwrite, nonnull) NSLocale *currencyLocale;
@property (strong, nonatomic, readwrite, nonnull) NSString *localeDecimal;
@property (strong, nonatomic, readwrite, nonnull) NSString *localeSeparator;
@property (strong, nonatomic, nullable) NSString *previousTaxEntryText;
@property (strong, nonatomic, nonnull) NSNumberFormatter *currencyFormatter;

@end

@implementation TaxUtility

#pragma mark - Customer Getters

- (BOOL)localeHasDynamicSalesTax
{
    return [NSLocale isUnitedStates];
}

- (BOOL)localeHasTrailingCurrencyFormat
{
    NSDecimalNumber *dummyAmount = [[NSDecimalNumber alloc] initWithString:self.localizedPlaceholderAmount];
    NSString *stringRepresentation = @"";
    NSString *currencySymbol = self.currencyLocale.currencySymbol;
    stringRepresentation = [self.currencyFormatter stringFromNumber:dummyAmount];
    NSRange currencyRange = [stringRepresentation rangeOfString:currencySymbol];
    BOOL hasTrailingCurrency = currencyRange.location > 0;
    
    return hasTrailingCurrency;
}

- (NSString *)localizedPlaceholderAmount
{
    if (self.isWholeNumbersEnabled)
    {
        return @"0";
    }
    
    return @"0.00";
}

- (BOOL)isWholeNumbersEnabled
{
    return [ss_defaults() boolForKey:Use_Whole_Numbers];
}

- (NSString *)localeID
{
    return self.currencyLocale.localeIdentifier;
}

#pragma mark - Initializer

- (instancetype)initWithLocaleID:(NSString *)localeID
{
    self = [super init];
    
    if (self)
    {
        if (!localeID) localeID = [NSLocale currentLocale].localeIdentifier;
        self.currencyLocale = [NSLocale localeWithLocaleIdentifier:localeID];
        self.localeDecimal = self.currencyLocale.decimalSeparator;
        self.localeSeparator = [self.currencyLocale objectForKey:NSLocaleGroupingSeparator];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateCurrencyFormatterFractionLimit)
                                                     name:SS_WHOLE_NUMBERS_TOGGLED
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Lazy Loads

- (NSNumberFormatter *)currencyFormatter
{
    if(!_currencyFormatter)
    {
        _currencyFormatter = [NSNumberFormatter new];
        _currencyFormatter.numberStyle = NSNumberFormatterCurrencyAccountingStyle;
        
        if (self.isWholeNumbersEnabled)
        {
            _currencyFormatter.minimumFractionDigits = 0;
            _currencyFormatter.maximumFractionDigits = 0;
        }
        else
        {
            _currencyFormatter.minimumFractionDigits = 2;
            _currencyFormatter.maximumFractionDigits = 2;
        }
    
        _currencyFormatter.locale = self.currencyLocale;
    }
    
    return _currencyFormatter;
}

#pragma mark - Currency

- (void)updateCurrencyFormatterFractionLimit
{
    if (self.isWholeNumbersEnabled)
    {
        self.currencyFormatter.maximumFractionDigits = 0;
    }
    else
    {
        self.currencyFormatter.minimumFractionDigits = 2;
    }
}

- (NSString *)stringNumbersOnly:(NSString *)input
{
    NSError *formattingError;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"[^0-9]" options:NSRegularExpressionCaseInsensitive error:&formattingError];
    input = [regex stringByReplacingMatchesInString:input options:0 range:NSMakeRange(0, input.length) withTemplate:@""];
    
    return input;
}
 

- (NSString *)stringNumbersSeparatorsOnly:(NSString *)input
{
    NSError *formattingError;
    NSString *formattedPattern = [NSString stringWithFormat:@"[^0-9%@%@-]", self.localeDecimal, [self.currencyLocale objectForKey:NSLocaleGroupingSeparator]];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:formattedPattern options:NSRegularExpressionCaseInsensitive error:&formattingError];
    input = [regex stringByReplacingMatchesInString:input options:0 range:NSMakeRange(0, input.length) withTemplate:@""];
    input = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return input;
}

- (NSString *)stringByStrippingCurrencySymbol:(NSString *)input
{
    NSString *symbol = self.currencyLocale.currencySymbol;
    return [input stringByReplacingOccurrencesOfString:symbol withString:@""];
}

- (NSString *)currencyString:(NSString *)input
{
    NSString *amountWithPrefix = input;
    
    // Strip currency symbol
    amountWithPrefix = [self stringByStrippingCurrencySymbol:amountWithPrefix];
    
    if ([amountWithPrefix isEqualToString:@""])
    {
        return @"";
    }
    
    NSDecimalNumber *decimal = [[NSDecimalNumber alloc] initWithDouble:amountWithPrefix.doubleValue];

    return [self.currencyFormatter stringFromNumber:decimal];
}

- (NSString *)currencyStringFromInput:(NSString *)input
{
    NSNumber *numberValue;
    NSString *amountWithPrefix = input;
    
    // Strip currency symbol
    amountWithPrefix = [self stringNumbersOnly:amountWithPrefix];
    
    double newValue = amountWithPrefix.doubleValue;
    
    if (self.isWholeNumbersEnabled)
    {
        numberValue = @(newValue);
    }
    else
    {
        numberValue = @(newValue/100);
    }
    
    if ([numberValue isEqual:@0])
    {
        return @"";
    }
    
    return [self.currencyFormatter stringFromNumber:numberValue];
}

- (NSString *)guranteedCurrencyString:(NSString *)input
{
    if (input == nil) return @"";
        
    NSString *value = [self currencyString:input];
    
    if ([value isEqualToString:@""])
    {
        return [self.currencyFormatter stringFromNumber:@0];
    }
    
    return value;
}

- (void)decimalTaxValueFromString:(NSString *)currentTaxInput result:(void (^) (BOOL valid, NSString *errorReason, NSDecimalNumber *taxRate))onEvaluation
{
    NSDecimalNumberHandler *roundHandler = [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundPlain scale:DECIMAL_ROUNDING_SCALE raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    NSString *currentInput = [currentTaxInput stringByReplacingOccurrencesOfString:@"%" withString:@""];
    
    // If they put something like 10, automatically make it 10.0
    if ([currentInput rangeOfString:self.localeDecimal].location == NSNotFound)
    {
        currentInput = [currentInput stringByAppendingFormat:@"%@0", self.localeDecimal];
    }
    
    NSDecimalNumber *taxRate = [[NSDecimalNumber alloc] initWithString:currentTaxInput locale:self.currencyLocale];
    
    NSUInteger digitsBeforeDecimalPoint = [currentInput componentsSeparatedByString:self.localeDecimal].firstObject.length;
    if (digitsBeforeDecimalPoint > DECIMAL_THRESHOLD)
    {
        NSString *errorString;
        NSMutableString *rearrangedTaxRate = [[NSMutableString alloc] initWithString:[currentTaxInput stringByReplacingOccurrencesOfString:self.localeDecimal withString:@""]];
        [rearrangedTaxRate insertString:self.localeDecimal atIndex:DECIMAL_THRESHOLD];
        taxRate = [[NSDecimalNumber alloc] initWithString:rearrangedTaxRate locale:self.currencyLocale];
        
        //Trim it if I just made it too long
        if (rearrangedTaxRate.length > MAXIMUM_VALID_TAX_RATE_STRING_LENGTH)
        {
            NSString *fixedLengthTaxRate = [[rearrangedTaxRate substringToIndex:MAXIMUM_VALID_TAX_RATE_STRING_LENGTH] stringByAppendingString:@"%"];
            taxRate = [[NSDecimalNumber alloc] initWithString:fixedLengthTaxRate locale:self.currencyLocale];
            errorString = [NSString stringWithFormat:@"Your tax rate (%@) should only have up to two numbers before the decimal point.\n\nShould we change it for you to %@?", currentTaxInput, fixedLengthTaxRate];
        }
        else
        {
            errorString = [NSString stringWithFormat:@"Your tax rate (%@) should only have up to two numbers before the decimal point.\n\nShould we change it for you to %@?", currentTaxInput, rearrangedTaxRate];
        }
        
        onEvaluation(NO, errorString, [taxRate decimalNumberByRoundingAccordingToBehavior:roundHandler]);
    }
    
    return onEvaluation(YES, @"", [taxRate decimalNumberByRoundingAccordingToBehavior:roundHandler]);
}

#pragma mark - Text Entry

- (NSString *)placeholderStringForManualTaxRateEntry;
{
    if ([self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_US])
    {
        return @"i.e. 7.8%";
    }
    
    return @"i.e. 7.8%";
}

- (NSString *)localizedTaxRateString
{
    if ([self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_US])
    {
        return ss_Localized(@"taxUtil.tax");
    }
    else if ([self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_SWITZERLAND])
    {
        return @"VAT";
    }
    else
    {
        // a sales tax or VAT rate
        return ss_Localized(@"createList.vc.manualEnterTax");
    }
    
    return ss_Localized(@"taxUtil.tax");
}

- (NSString *)localizedTaxRateLocationString
{
    if ([self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_SWITZERLAND])
    {
        return @"Switzerland/VAT";
    }
    
    return @"";
}

- (NSString *)countryVATString
{
    if ([self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_SWITZERLAND])
    {
        return [VAT_SWITZERLAND stringByAppendingString:@"%"];
    }
    
    return @"";
}

- (BOOL)stringIsValidTaxRate:(NSString *)currentTaxInput
{
    NSString *currentInput = [currentTaxInput stringByReplacingOccurrencesOfString:@"%" withString:@""];
    self.previousTaxEntryText = currentInput;
    BOOL inputIsNumericOnly = [currentInput rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound;

    if (inputIsNumericOnly == NO)
    {
        return NO;
    }
    
    return currentInput.length >= MINIMUM_VALID_TAX_RATE_STRING_LENGTH;
}

- (NSDecimalNumber *)priceDecimalFromString:(NSString *)string
{
    NSString *thousandSeparator = [self.currencyLocale objectForKey:NSLocaleGroupingSeparator];
    string = [string stringByReplacingOccurrencesOfString:thousandSeparator withString:@""];
    
    // Some locales have some spaces in the currency, so eliminate those
    NSArray <NSString *> *split = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *sanitizedEntry = [split componentsJoinedByString:@""];
    string = sanitizedEntry;
    
    return [NSDecimalNumber decimalNumberWithString:string locale:self.currencyLocale];
}

- (NSString *)taxStringForManualEntryFromString:(NSString *)currentTaxInput
{
    NSString *currentInput = [currentTaxInput stringByReplacingOccurrencesOfString:@"%" withString:@""];
    
    if (currentInput.length > MAXIMUM_VALID_TAX_RATE_STRING_LENGTH)
    {
        currentInput = [currentInput substringToIndex:currentInput.length - 1]; //i.e. 08.8888 to 08.888
    }
    
    currentInput = [currentInput stringByAppendingString:@"%"];
    
    // If this should effectively be an empty string
    if ([currentInput isEqualToString:@"%"])
    {
        currentInput = @"";
    }
    
    return currentInput;
}

- (NSString *)displayTaxStringFromString:(NSString *)tax
{
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    numberFormatter.maximumFractionDigits = 2;
    numberFormatter.minimumFractionDigits = 2;
    numberFormatter.roundingMode = NSNumberFormatterRoundDown;
    
    NSString *currentInput = [tax stringByReplacingOccurrencesOfString:@"%" withString:@""];
    currentInput = [numberFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:currentInput locale:self.currencyLocale]];
    
    currentInput = [currentInput stringByAppendingString:@"%"];
    
    // If this should effectively be an empty string
    if ([currentInput isEqualToString:@"%"])
    {
        currentInput = @"";
    }
    
    return currentInput;
}

- (NSRange)selectedRangeFromInput:(NSString *)currentTaxInput
{
    if ([self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_US] || [self.currencyLocale.countryCode isEqualToString:COUNTRY_CODE_SWITZERLAND])
    {
        return NSMakeRange(currentTaxInput.length - 1, 0);
    }
    
    return NSMakeRange(currentTaxInput.length, 0);
}

- (UITextRange *)selectTextRangeForPriceTextView:(__kindof UITextView *)textView
{
    if (self.localeHasTrailingCurrencyFormat)
    {
        if (textView.selectedTextRange != nil)
        {
            NSUInteger moneyLength = [self stringNumbersSeparatorsOnly:textView.text].length;
            UITextPosition *currencyOffsetPosition = [textView positionFromPosition:textView.beginningOfDocument
                                                                             offset:moneyLength];
            
            if (currencyOffsetPosition)
            {
                return [textView textRangeFromPosition:currencyOffsetPosition toPosition:currencyOffsetPosition];
            }
            else
            {
                return textView.selectedTextRange;
            }
        }
        else
        {
            return textView.selectedTextRange;
        }
    }
    else
    {
        return textView.selectedTextRange;
    }
}

- (UITextRange *)selectTextRangeForPriceTextField:(__kindof UITextField *)textField
{
    // This logic is duped from selectTextRangeForPriceTextView:, should try and find a way to centralize it.
    if (self.localeHasTrailingCurrencyFormat)
    {
        if (textField.selectedTextRange != nil)
        {
            NSUInteger moneyLength = [self stringNumbersSeparatorsOnly:textField.text].length;
            UITextPosition *currencyOffsetPosition = [textField positionFromPosition:textField.beginningOfDocument
                                                                             offset:moneyLength];
            
            if (currencyOffsetPosition)
            {
                return [textField textRangeFromPosition:currencyOffsetPosition toPosition:currencyOffsetPosition];
            }
            else
            {
                return textField.selectedTextRange;
            }
        }
        else
        {
            return textField.selectedTextRange;
        }
    }
    else
    {
        return textField.selectedTextRange;
    }
}

@end
