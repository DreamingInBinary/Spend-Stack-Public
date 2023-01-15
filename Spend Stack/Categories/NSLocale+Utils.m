//
//  NSLocale+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 8/10/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "NSLocale+Utils.h"

@implementation NSLocale (Utils)

+ (BOOL)isUnitedStates
{
    return [[NSLocale currentLocale].countryCode isEqualToString:COUNTRY_CODE_US];
}

+ (BOOL)isWholeNumberRegion
{
    return ([[NSLocale currentLocale].countryCode isEqualToString:COUNTRY_CODE_CHILE] ||
            [[NSLocale currentLocale].countryCode isEqualToString:COUNTRY_CODE_INDONESIA]);
}

@end
