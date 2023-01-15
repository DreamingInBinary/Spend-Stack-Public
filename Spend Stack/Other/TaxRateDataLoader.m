//
//  TaxRateDataLoader.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/4/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "TaxRateDataLoader.h"

static const NSString * API_URL = @"http://www.sale-tax.com/";
static const NSString * API_TOKEN = @"?api_token=SpendStack";

@implementation TaxRateDataLoader

+ (void)findLocaSalesTaxWithCompletion:(void (^)(NSError * _Nullable, NSDecimalNumber * _Nullable))completion
{
    NSError *error;
    
    if ([LocationUtil sharedInstance].fetchedUserLocale == SSFetchedUserLocaleNotFound)
    {
        error = [NSError errorWithDomain:@"taxRateLoader.taxUtils" code:01 userInfo:@{NSLocalizedDescriptionKey:@"User's locale hasn't been discovered."}];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            completion(error, nil);
        });
    }
    else if ([LocationUtil sharedInstance].fetchedUserLocale == SSFetchedUserLocaleUnitedStates)
    {
        [TaxRateDataLoader requestTaxRateForUnitedStates:completion];
    }
}

#pragma mark - Private Implementations

+ (void)requestTaxRateForUnitedStates:(void (^)(NSError * _Nullable, NSDecimalNumber * _Nullable))completion
{
    // Strip out any possible whitespace i.e. for San Francisco
    NSString *city = [LocationUtil sharedInstance].recentCity;
    NSString *state = [LocationUtil sharedInstance].recentState;
    NSString *cityState = [[[city stringByAppendingString:state] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    
    if ([TaxRateDataLoader hasAlreadyFetchedLocaleTaxRate:city])
    {
        NSLog(@"Spend Stack - Tax rate for %@ has already been fetched, returning with it now from %@", cityState, NSStringFromSelector(_cmd));
        NSError *sameLocationWarning = [NSError errorWithDomain:SS_WARNING_TAX_LOADER_LOCATION_SAME_DOMAIN
                                                           code:SS_WARNING_TAX_LOADER_LOCATION_SAME_CODE
                                                       userInfo:@{NSLocalizedDescriptionKey:@"Already queried location for tax rate."}];
        NSNumber *numberTaxRate = [ss_defaults() objectForKey:SS_LAST_FETCHED_CITY_TAX_RATE_KEY];
        NSDecimalNumber *decimalTaxRate = [[NSDecimalNumber alloc] initWithString:numberTaxRate.stringValue];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            completion(sameLocationWarning, decimalTaxRate);
        });
    }
    else
    {
        NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", API_URL, cityState, API_TOKEN]];
        
        [[[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^ (NSData *data, NSURLResponse *response, NSError * error) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                if (error)
                {
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        completion(error, nil);
                    });
                }
                else
                {
                    NSString *rawHTML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSArray <NSString *> *rate = [rawHTML.lowercaseString componentsSeparatedByString:@"calculator?rate="];
                    
                    if (rate.count >= 2 && rate[1].length >= 5)
                    {
                        NSString *parsedTaxRate = [rate[1] substringWithRange:NSMakeRange(0, 5)];
                        [[[TaxUtility alloc] initWithLocaleID:@"en_US"] decimalTaxValueFromString:parsedTaxRate result:^ (BOOL valid, NSString *errorString, NSDecimalNumber *taxRate) {
                            if (valid)
                            {
                                [ss_defaults() setObject:city forKey:SS_LAST_FETCHED_CITY_KEY];
                                [ss_defaults() setObject:taxRate forKey:SS_LAST_FETCHED_CITY_TAX_RATE_KEY];
                                [ss_defaults() synchronize];
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:SS_FOUND_TAX_RATE object:nil];
                                
                                dispatch_async(dispatch_get_main_queue(), ^ {
                                    completion(nil, taxRate);
                                });
                            }
                            else
                            {
                                NSError *error = [NSError errorWithDomain:@"taxRateLoader.taxUtils.htmlScrapeParseTaxString" code:01 userInfo:@{NSLocalizedDescriptionKey:errorString}];
                                dispatch_async(dispatch_get_main_queue(), ^ {
                                    completion(error, nil);
                                });
                            }
                        }];
                    }
                    else
                    {
                        NSError *error = [NSError errorWithDomain:@"taxRateLoader.taxUtils.htmlScrape" code:01 userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response from web page scraping."}];
                        
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            completion(error, nil);
                        });
                    }
                }
            });
        }] resume];
    }
    
    // NOTE!!!: Fall back to that other API if this one fails?
    // Possbily use http://taxratesapi.avalara.com/docs for tax rate information
}

+ (BOOL)hasAlreadyFetchedLocaleTaxRate:(NSString *)city
{
    NSString *lastFetchedCity = [ss_defaults() objectForKey:SS_LAST_FETCHED_CITY_KEY];
    if (lastFetchedCity == nil) lastFetchedCity = @"";
    BOOL sameCity = [lastFetchedCity isEqualToString:city];
    
    if (sameCity)
    {
        // Just for added safety, ensure we actually saved the tax rate ok
        BOOL hasTaxRate = NO;
        id savedTaxRate = [ss_defaults() objectForKey:SS_LAST_FETCHED_CITY_TAX_RATE_KEY];
        hasTaxRate = (savedTaxRate && [savedTaxRate isKindOfClass:[NSNumber class]]);
        return hasTaxRate;
    }
    else
    {
        return NO;
    }
}

@end
