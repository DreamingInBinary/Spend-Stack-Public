//
//  TaxUtility.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/26/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

static const NSUInteger DECIMAL_THRESHOLD = 2;
static const NSUInteger DECIMAL_ROUNDING_SCALE = 3;
static const NSUInteger MINIMUM_VALID_TAX_RATE_STRING_LENGTH = 2; //Assumes "%" is stripped from string
static const NSUInteger MAXIMUM_VALID_TAX_RATE_STRING_LENGTH = 6; //Assumes "%" is stripped from string

@interface TaxUtility : NSObject

- (void)decimalTaxValueFromString:(NSString * _Nonnull)currentTaxInput result:(void (^_Nonnull) (BOOL valid, NSString * _Nullable errorReason, NSDecimalNumber * _Nullable taxRate))onEvaluation;

// Manual Tax Entry
NS_ASSUME_NONNULL_BEGIN
@property (strong, nonatomic, readonly, nonnull) NSString *localeDecimal;
@property (strong, nonatomic, readonly, nonnull) NSString *localeSeparator;
@property (nonatomic, readonly, getter=localeHasDynamicSalesTax) BOOL dynamicSalesTax;
@property (nonatomic, readonly, getter=localeHasTrailingCurrencyFormat) BOOL localeTrailingCurrencyFormat;
@property (strong, nonatomic, readonly) NSString *localizedPlaceholderAmount;
@property (nonatomic, getter=isWholeNumbersEnabled, readonly) BOOL wholeNumbersEnabled;
@property (strong, nonatomic, readonly) NSString *localeID;
@property (strong, nonatomic, readonly, nonnull) NSLocale *currencyLocale;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype)initWithLocaleID:(NSString * _Nullable)localeID NS_DESIGNATED_INITIALIZER;
- (NSString *)stringNumbersSeparatorsOnly:(NSString *)input;
- (NSString *)currencyString:(NSString *)input; // If amount is 0, returns @""
- (NSString *)currencyStringFromInput:(NSString *)input; // If amount is 0, returns @""
- (NSString *)guranteedCurrencyString:(NSString *)input; // If amount is 0, returns $0.00
- (NSString *)placeholderStringForManualTaxRateEntry;
- (NSString *)localizedTaxRateString; // Sales Tax, VAT, etc.
- (NSString *)localizedTaxRateLocationString; // Only used for static tax rates, i.e. VAT. Produces Switzerland/VAT, etc
- (NSString *)countryVATString;
- (NSDecimalNumber *)priceDecimalFromString:(NSString *)string;
- (BOOL)stringIsValidTaxRate:(NSString *)currentTaxInput;
- (NSString *)taxStringForManualEntryFromString:(NSString *)currentTaxInput;
- (NSString *)displayTaxStringFromString:(NSString *)tax;
- (NSRange)selectedRangeFromInput:(NSString *)currentTaxInput;
- (UITextRange *)selectTextRangeForPriceTextView:(__kindof UITextView *)textView;
- (UITextRange *)selectTextRangeForPriceTextField:(__kindof UITextField *)textField;
NS_ASSUME_NONNULL_END

@end
