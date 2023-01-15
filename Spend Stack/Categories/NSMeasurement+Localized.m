//
//  NSMeasurement+Localized.m
//  Spend Stack
//
//  Created by Jordan Morgan on 8/6/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "NSMeasurement+Localized.h"

@implementation NSMeasurement (Localized)

+ (NSMeasurement * _Nonnull)measurementWithValue:(double)value
{
    if ([NSLocale currentLocale].usesMetricSystem)
    {
        return [[NSMeasurement alloc] initWithDoubleValue:value unit:NSUnitMass.kilograms];
    }
    else
    {
        return [[NSMeasurement alloc] initWithDoubleValue:value unit:NSUnitMass.poundsMass];
    }
}

@end
