//
//  TaxRateDataLoader.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/4/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TaxUtility;

static NSString * const _Nonnull  SS_LAST_FETCHED_CITY_KEY = @"lastFetchedCity";
static NSString * const _Nonnull  SS_LAST_FETCHED_CITY_TAX_RATE_KEY = @"lastFetchedCityTaxRate";
static NSString * const _Nonnull SS_WARNING_TAX_LOADER_LOCATION_SAME_DOMAIN = @"ssTaxRateSameLocationQueried";
static NSInteger const SS_WARNING_TAX_LOADER_LOCATION_SAME_CODE = 901243;

@interface TaxRateDataLoader : NSObject

+ (void)findLocaSalesTaxWithCompletion:(void(^ _Nonnull)(NSError * _Nullable error, NSDecimalNumber * _Nullable taxRate))completion;

@end
