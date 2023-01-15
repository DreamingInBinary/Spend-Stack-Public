//
//  SSTaxRateInfo+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTaxRateInfo+Utils.h"

@implementation SSTaxRateInfo (Utils)

- (NSDecimalNumber *)taxRateForCalculations:(TaxUtility *)taxUtil
{
    NSAssert(self.taxRate != nil, @"Received a tax rate without a tax rate set.");
    NSDecimalNumber *one = [[NSDecimalNumber alloc] initWithString:@"1.00" locale:taxUtil.currencyLocale];
    
    if (self.taxRate && isnan(self.taxRate.floatValue) == NO)
    {
        return [self.taxRate decimalNumberByMultiplyingByPowerOf10:-2];
    }
    else
    {
        return one;
    }
}

- (NSString *)taxRateStringValue
{
    if (self.taxRate)
    {
        return [NSString stringWithFormat:@"%@%%", self.taxRate.stringValue];
    }
    
    return nil;
}

@end
