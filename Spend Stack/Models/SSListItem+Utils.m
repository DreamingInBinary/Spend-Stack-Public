//
//  SSListItem+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItem.h"
#import "SSTagSelectionViewModel.h"
#import "SSListItem+Utils.h"
#import "SSListTag+Utils.h"
#import "NSData+OrientationExifFix.h"

static inline NSUInteger ss_daysInMonth() {
    NSDate *today = [NSDate date];
    NSCalendar *c = [NSCalendar currentCalendar];
    NSRange daysInMonth = [c rangeOfUnit:NSCalendarUnitDay
                           inUnit:NSCalendarUnitMonth
                          forDate:today];
    return daysInMonth.length;
}

static inline NSUInteger ss_weeksInMonth() {
    return 4;
    /*
    // This logic is confusing people, even though it's technically right.
    NSDate *today = [NSDate date];
    NSCalendar *c = [NSCalendar currentCalendar];
    NSRange weeksInMonth = [c rangeOfUnit:NSCalendarUnitWeekOfMonth
                           inUnit:NSCalendarUnitMonth
                          forDate:today];
    return weeksInMonth.length;
     */
}

static inline NSUInteger ss_daysInYear() {
    return 365;
    /*
    // This logic is confusing people, even though it's technically right.
    NSDate *today = [NSDate date];
    NSCalendar *c = [NSCalendar currentCalendar];
    NSRange daysInYear = [c rangeOfUnit:NSCalendarUnitDay
                           inUnit:NSCalendarUnitYear
                          forDate:today];
    return daysInYear.length;
     */
}

@implementation SSListItemMediaAttachResult
@end

@implementation SSListItem (Utils)

- (BOOL)itemHasNoExtraDetails:(SSTaxRateInfo *)taxInfo
{
    return [self itemHasOnlyLeadingExtraDetails:taxInfo] == NO &&
           [self itemHasOnlyTrailingExtraDetails:taxInfo] == NO &&
           [self itemHasAllExtraDetails:taxInfo] == NO;
}

- (BOOL)itemHasOnlyLeadingExtraDetails:(SSTaxRateInfo *)taxInfo
{
    // Does it have notes, an image or link and no tax details are shown below the total amount
    return ((self.notes && [self.notes isEqualToString:@""] == NO) ||
            (self.mediaAssetData != nil) || (self.linkAttachment && [self.linkAttachment isEqualToString:@""] == NO)) && !((self.hasTaxApplied && taxInfo.taxIsEnabled) && self.baseAmount.floatValue > 0);
}

- (BOOL)itemHasOnlyTrailingExtraDetails:(SSTaxRateInfo *)taxInfo
{
    // Does it not have notes, an image or link and does have tax details
    return ((self.notes && [self.notes isEqualToString:@""] == NO) || (self.linkAttachment && [self.linkAttachment isEqualToString:@""] == NO) || (self.mediaAssetData != nil)) == NO && ((self.hasTaxApplied && taxInfo.taxIsEnabled)  && self.baseAmount.floatValue > 0);
}

- (BOOL)itemHasAllExtraDetails:(SSTaxRateInfo *)taxInfo
{
    // It has both
    return (self.notes && [self.notes isEqualToString:@""] == NO) || (self.linkAttachment && [self.linkAttachment isEqualToString:@""] == NO) || ((self.hasTaxApplied && taxInfo.taxIsEnabled) && self.baseAmount.floatValue > 0)|| self.mediaAttachment;
}

- (BOOL)checkHasDiscountAmountApplied
{
    return self.discountAmount != nil;
}

- (BOOL)checkHasDiscountPercentageApplied
{
    return self.discountPercentage != nil;
}

- (BOOL)checkHasDiscountApplied
{
    return self.discountAmount != nil || self.discountPercentage != nil;
}

- (BOOL)checkHasWeightedPricing
{
    return self.weight != nil;
}

- (BOOL)checkIsNegativeAmount
{
    return [self.baseAmount.stringValue hasPrefix:@"-"];
}

- (BOOL)checkIsUsingRecurringPricing
{
    return self.recurringPricingCycle != ListItemRecurringPricingChoiceUnset;
}

- (BOOL)checkHasMediaAttachment
{
    return self.mediaAttachment != nil;
}

- (BOOL)checkHasLinkAttachment
{
    return self.linkAttachment != nil;
}

#pragma mark - Calculators

- (NSDecimalNumber *)calcSubtotalAmount
{
    CGFloat baseAmountAndQuantity = self.baseAmount.floatValue;
    
    if ([self checkHasWeightedPricing])
    {
        baseAmountAndQuantity *= self.weight.doubleValue;
    }
    
    if (self.quantity > 1)
    {
        baseAmountAndQuantity *= self.quantity;
    }
    
    return [[NSDecimalNumber alloc] initWithFloat:baseAmountAndQuantity];
}

- (NSDecimalNumber *)calcTaxedAmount:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    
    if (self.hasTaxApplied)
    {
        if (taxInfo.taxIsEnabled == NO) return [[NSDecimalNumber alloc] initWithDouble:0]; // Even if a list has a tax rate set, each item can choose to adhere to it
        return [[self calcSubtotalAmount] decimalNumberByMultiplyingBy:[taxInfo taxRateForCalculations:taxUtil]];
    }
    else
    {
        return [[NSDecimalNumber alloc] initWithDouble:0];
    }
}

- (NSDecimalNumber *)calcActualDiscountOffPrice
{
    if(self.discountAmount != nil && isnan(self.discountAmount.floatValue) == NO)
    {
        return self.discountAmount;
    }
    else if (self.discountPercentage != nil && isnan(self.discountPercentage.floatValue) == NO)
    {
        CGFloat basePrice = [self calcSubtotalAmount].floatValue;
        NSDecimalNumber *discountRateForCalculation = [self.discountPercentage decimalNumberByMultiplyingByPowerOf10:-2];
        CGFloat percentageDiscount = (basePrice * discountRateForCalculation.floatValue);
        return [[NSDecimalNumber alloc] initWithFloat:percentageDiscount];
    }
    else
    {
        return [[NSDecimalNumber alloc] initWithDouble:0];
    }
}

- (NSDecimalNumber *)calcTotalAmount:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    if ([self checkHasDiscountApplied])
    {
        CGFloat basePrice = [self calcSubtotalAmount].floatValue;
        CGFloat discount = [self calcActualDiscountOffPrice].floatValue;
        basePrice -= discount;
        
        if (self.hasTaxApplied)
        {
            CGFloat taxAmount = (basePrice * [taxInfo taxRateForCalculations:taxUtil].floatValue);
            return [[NSDecimalNumber alloc] initWithFloat:(basePrice + taxAmount)];
        }
        else
        {
            return [[NSDecimalNumber alloc] initWithFloat:basePrice];
        }
    }
    else if (self.hasTaxApplied)
    {
        CGFloat taxAndQuantity = [self calcSubtotalAmount].floatValue + [self calcTaxedAmount:taxInfo taxUtil:taxUtil].floatValue;
        return [[NSDecimalNumber alloc] initWithFloat:taxAndQuantity];
    }
    else
    {
        return [[NSDecimalNumber alloc] initWithFloat:[self calcSubtotalAmount].floatValue];
    }
}

- (NSDecimalNumber *)calcTotalRecurringCostDaily:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    double total = [self calcTotalAmount:taxInfo taxUtil:taxUtil].doubleValue;
    NSInteger chargeFrequency = self.recurringPricingFrequency.integerValue;
    NSUInteger totalDaysCharged = 0;

    switch (self.recurringPricingCycle)
    {
        case ListItemRecurringPricingChoiceDay:
        {
            totalDaysCharged = chargeFrequency; // i.e. once every 1/2/etc days
            total = total/totalDaysCharged;
        }
            break;
        case ListItemRecurringPricingChoiceWeek:
        {
            total = (total/SS_Week) / chargeFrequency;
        }
            break;
        case ListItemRecurringPricingChoiceMonth:
        {
            NSUInteger daysInMonth = ss_daysInMonth();
            total = (total/daysInMonth) / chargeFrequency; // i.e. once every 1/2/etc months;
        }
            break;
        case ListItemRecurringPricingChoiceYear:
        {
            NSUInteger daysInYear = ss_daysInYear();
            totalDaysCharged = (daysInYear / chargeFrequency); // i.e. once every 1/2/etc months
            total = total/totalDaysCharged;
        }
            break;
        default:
            break;
    }
    
    return [[NSDecimalNumber alloc] initWithDouble:total];
}

- (NSDecimalNumber *)calcTotalRecurringCostWeekly:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    double total = [self calcTotalAmount:taxInfo taxUtil:taxUtil].doubleValue;
    NSInteger chargeFrequency = self.recurringPricingFrequency.integerValue;
    
    if (self.recurringPricingCycle == ListItemRecurringPricingChoiceDay)
    {
        total = [self calcTotalRecurringCostDaily:taxInfo taxUtil:taxUtil].doubleValue;
        total = (total * SS_Week) / chargeFrequency;
    }
    else if (self.recurringPricingCycle == ListItemRecurringPricingChoiceWeek)
    {
        total /= chargeFrequency;
    }
    else if (self.recurringPricingCycle == ListItemRecurringPricingChoiceYear)
    {
        total = floor((total/SS_WeeksInYear) / chargeFrequency);
    }
    else
    {
        NSUInteger weeksInMonth = ss_weeksInMonth();
        total = (total/weeksInMonth) / chargeFrequency;
    }
    
    return [[NSDecimalNumber alloc] initWithDouble:total];
}

- (NSDecimalNumber *)calcTotalRecurringCostMonthly:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    double total = [self calcTotalAmount:taxInfo taxUtil:taxUtil].doubleValue;
    NSInteger chargeFrequency = self.recurringPricingFrequency.integerValue;
    
    if (self.recurringPricingCycle == ListItemRecurringPricingChoiceYear)
    {
        total = floor((total/12) / chargeFrequency);
    }
    else if (self.recurringPricingCycle == ListItemRecurringPricingChoiceMonth)
    {
        total = (total / chargeFrequency);
    }
    else if (self.recurringPricingCycle == ListItemRecurringPricingChoiceWeek)
    {
        total = (total * ss_weeksInMonth()) / chargeFrequency;
    }
    else
    {
        double costPerDay = [self calcTotalRecurringCostDaily:taxInfo taxUtil:taxUtil].doubleValue;
        total = floor(costPerDay * 30);
    }

    return [[NSDecimalNumber alloc] initWithDouble:total];
}

- (NSDecimalNumber *)calcTotalRecurringCostYearly:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    double total = [self calcTotalAmount:taxInfo taxUtil:taxUtil].doubleValue;
    NSInteger chargeFrequency = self.recurringPricingFrequency.integerValue;
    
    if (self.recurringPricingCycle == ListItemRecurringPricingChoiceMonth)
    {
        total = (total * 12) / chargeFrequency;
    }
    else if (self.recurringPricingCycle == ListItemRecurringPricingChoiceWeek)
    {
        total = (total * SS_WeeksInYear) / chargeFrequency;
    }
    else if (self.recurringPricingCycle == ListItemRecurringPricingChoiceYear)
    {
        total = (total / chargeFrequency);
    }
    else
    {
        total = (total * ss_daysInYear()) / chargeFrequency;
    }

    return [[NSDecimalNumber alloc] initWithDouble:total];
}

+ (NSDecimalNumber *)calcTotalAmountWithRecord:(CKRecord *)record taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil
{
    BOOL hasTaxApplied = ((NSNumber *)record[@"hasTaxApplied"]).boolValue;

    NSNumber *discountAmountString = record[@"discountAmount"];
    NSDecimalNumber *discountAmount;
    if (discountAmountString)
    {
        discountAmount = [NSDecimalNumber decimalNumberWithString:discountAmountString.stringValue];
    }

    NSNumber *discountPercentageString = record[@"discountPercentage"];
    NSDecimalNumber *discountPercentage;
    if (discountPercentageString)
    {
        discountPercentage = [NSDecimalNumber decimalNumberWithString:discountPercentageString.stringValue];
    }

    NSNumber *weightString = record[@"weight"];
    NSMeasurement *weight;

    if (weightString)
    {
        double weightValue = weightString.doubleValue;
        weight = [NSMeasurement measurementWithValue:weightValue];
    }

    if (discountAmount != nil || discountPercentage != nil)
    {
        CGFloat basePrice = [SSListItem calcSubtotalAmountWithRecord:record].floatValue;
        CGFloat discount = [SSListItem calcActualDiscountOffPriceWithRecord:record].floatValue;
        basePrice -= discount;

        if (hasTaxApplied)
        {
            CGFloat taxAmount = (basePrice * [taxInfo taxRateForCalculations:taxUtil].floatValue);
            return [[NSDecimalNumber alloc] initWithFloat:(basePrice + taxAmount)];
        }
        else
        {
            return [[NSDecimalNumber alloc] initWithFloat:basePrice];
        }
    }
    else if (hasTaxApplied)
    {
        CGFloat taxAndQuantity = [SSListItem calcSubtotalAmountWithRecord:record].floatValue +
                                 [SSListItem calcTaxedAmountWithRecord:record taxInfo:taxInfo taxUtil:taxUtil].floatValue;
        return [[NSDecimalNumber alloc] initWithFloat:taxAndQuantity];
    }
    else
    {
        return [[NSDecimalNumber alloc] initWithFloat:[SSListItem calcSubtotalAmountWithRecord:record].floatValue];
    }
}

+ (NSDecimalNumber *)calcSubtotalAmountWithRecord:(CKRecord *)record
{
    NSDecimalNumber *baseAmount = [NSDecimalNumber decimalNumberWithString:((NSNumber *)record[@"baseAmount"]).stringValue];
    CGFloat baseAmountAndQuantity = baseAmount.floatValue;
    
    NSNumber *weightString = record[@"weight"];
    NSMeasurement *weight;
    NSInteger quantity = ((NSNumber *)record[@"quantity"]).integerValue;
    
    if (weightString)
    {
        double weightValue = weightString.doubleValue;
        weight = [NSMeasurement measurementWithValue:weightValue];
    }
    
    if (weight != nil)
    {
        baseAmountAndQuantity *= weight.doubleValue;
    }
    
    if (quantity > 1)
    {
        baseAmountAndQuantity *= quantity;
    }
    
    return [[NSDecimalNumber alloc] initWithFloat:baseAmountAndQuantity];
}

+ (NSDecimalNumber * _Nonnull)calcTaxedAmountWithRecord:(CKRecord * _Nonnull)record taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil
{
    BOOL hasTaxApplied = ((NSNumber *)record[@"hasTaxApplied"]).boolValue;
    
    NSNumber *discountAmountString = record[@"discountAmount"];
    NSDecimalNumber *discountAmount;
    if (discountAmountString)
    {
        discountAmount = [NSDecimalNumber decimalNumberWithString:discountAmountString.stringValue];
    }
    
    NSNumber *discountPercentageString = record[@"discountPercentage"];
    NSDecimalNumber *discountPercentage;
    if (discountPercentageString)
    {
        discountPercentage = [NSDecimalNumber decimalNumberWithString:discountPercentageString.stringValue];
    }
    
    NSNumber *weightString = record[@"weight"];
    NSMeasurement *weight;
    
    if (weightString)
    {
        double weightValue = weightString.doubleValue;
        weight = [NSMeasurement measurementWithValue:weightValue];
    }
    
    if (hasTaxApplied)
    {
        if (taxInfo.taxIsEnabled == NO) return [[NSDecimalNumber alloc] initWithDouble:0]; // Even if a list has a tax rate set, each item can choose to adhere to it
        return [[SSListItem calcSubtotalAmountWithRecord:record] decimalNumberByMultiplyingBy:[taxInfo taxRateForCalculations:taxUtil]];
    }
    else
    {
        return [[NSDecimalNumber alloc] initWithDouble:0];
    }
}

+ (NSDecimalNumber *)calcActualDiscountOffPriceWithRecord:(CKRecord *)record
{
    NSNumber *discountAmountString = record[@"discountAmount"];
    NSDecimalNumber *discountAmount;
    if (discountAmountString)
    {
        discountAmount = [NSDecimalNumber decimalNumberWithString:discountAmountString.stringValue];
    }

    NSNumber *discountPercentageString = record[@"discountPercentage"];
    NSDecimalNumber *discountPercentage;
    if (discountPercentageString)
    {
        discountPercentage = [NSDecimalNumber decimalNumberWithString:discountPercentageString.stringValue];
    }

    if (discountAmount != nil && isnan(discountAmount.floatValue) == NO)
    {
        return discountAmount;
    }
    else if (discountPercentage != nil && isnan(discountPercentage.floatValue) == NO)
    {
        CGFloat basePrice = [SSListItem calcSubtotalAmountWithRecord:record].floatValue;
        NSDecimalNumber *discountRateForCalculation = [discountPercentage decimalNumberByMultiplyingByPowerOf10:-2];
        CGFloat percentageDiscount = (basePrice * discountRateForCalculation.floatValue);
        return [[NSDecimalNumber alloc] initWithFloat:percentageDiscount];
    }
    else
    {
        return [[NSDecimalNumber alloc] initWithDouble:0];
    }
}

#pragma mark - Media and Utils

- (SSListItemMediaAttachResult *)generateNewMediaItemResultFromData:(NSData *)data
{
    NSError *writeError;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *docsURL = [[defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *outputURL = [docsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"image%@-%@.png", self.title, self.dbID]];
    
    [data writeToURL:outputURL options:NSDataWritingAtomic error:&writeError];
    
    if (writeError)
    {
        NSLog(@"Spend Stack - Couldn't write image data: %@", writeError.localizedDescription);
    }
    
    SSListItemMediaAttachResult *result = [SSListItemMediaAttachResult new];
    result.data = data;
    result.asset = [[CKAsset alloc] initWithFileURL:outputURL];
    
    return result;
}

- (NSString *)modifiderDataString:(TaxUtility *)taxUtil
{
    NSMutableString *modifierData = [[NSMutableString alloc] initWithString:@"("];
    
    if (self.quantity > 1)
    {
        [modifierData appendString:[NSString stringWithFormat:@"x%lu", (unsigned long)self.quantity]];
    }
    
    if ([self checkHasWeightedPricing])
    {
        NSString *weightString = [[NSMeasurementFormatter new] stringFromMeasurement:self.weight];
        
        if (modifierData.length > 1)
        {
            weightString = [NSString stringWithFormat:@" • %@", weightString];
        }
        
        if (self.weight.doubleValue > 1)
        {
            weightString = [weightString stringByAppendingString:@"s"];
        }
        
        [modifierData appendString:weightString];
    }
    
    if ([self checkHasDiscountApplied])
    {
        NSString *discountString = @"";
        BOOL amountOff = self.discountAmount != nil;
        BOOL percentOff = self.discountPercentage != nil;
        
        if (amountOff)
        {
            discountString = [NSString stringWithFormat:@"%@ off", [taxUtil currencyString:self.discountAmount.stringValue]];
        }
        else if(percentOff)
        {
            discountString = [NSString stringWithFormat:@"%@%% off", self.discountPercentage];
        }
        
        if (modifierData.length > 1)
        {
            discountString = [NSString stringWithFormat:@" • %@", discountString];
        }
        
        [modifierData appendString:discountString];
    }
    
    // Check for an empty string, which would only be an "(" at this point
    if ([modifierData isEqualToString:@"("])
    {
        return nil;
    }
    
    [modifierData appendString:@")"];
    
    return [modifierData copy];
}

- (SSTagSelectionViewModel *)createTagViewModel
{
    if (self.tag == nil) return nil;
    
    if ([self.tag tagIsSharedWithMe])
    {
        return [[SSTagSelectionViewModel alloc] initWithListTag:self.tag];
    }
    else
    {
        SSTag *masterTag = [SSListTag masterTagForListItem:self];
        return [[SSTagSelectionViewModel alloc] initWithMasterTag:masterTag];
    }
}

- (NSString *)recurringPriceDisplayString
{
    NSInteger frequency = self.recurringPricingFrequency.integerValue;
    
    if (frequency == 1)
    {
        switch (self.recurringPricingCycle)
        {
            case ListItemRecurringPricingChoiceDay:
                return ss_Localized(@"listEdit.daily");
            case ListItemRecurringPricingChoiceWeek:
                return ss_Localized(@"listEdit.weekly");
            case ListItemRecurringPricingChoiceMonth:
                return ss_Localized(@"listEdit.monthly");
            case ListItemRecurringPricingChoiceYear:
                return ss_Localized(@"listEdit.yearly");
            default:
                break;
        }
    }
    else
    {
        switch (self.recurringPricingCycle)
        {
            case ListItemRecurringPricingChoiceDay:
                return [NSString stringWithFormat:ss_Localized(@"listEdit.multDaily"), @(frequency)];
            case ListItemRecurringPricingChoiceWeek:
                return [NSString stringWithFormat:ss_Localized(@"listEdit.multWeekly"), @(frequency)];
            case ListItemRecurringPricingChoiceMonth:
                return [NSString stringWithFormat:ss_Localized(@"listEdit.multMonthly"), @(frequency)];
            case ListItemRecurringPricingChoiceYear:
                return [NSString stringWithFormat:ss_Localized(@"listEdit.multYearly"), @(frequency)];
            default:
                break;
        }
    }
    
    return @"";
}

@end
