//
//  SSBarcodeDataFetcher.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBarcodeDataFetcher.h"
#import "SSBarcodeSearchResult.h"
#import "NSString+SHA1.h"

static NSString * const DIGIT_EYES_AUTH_PARAMS = @"app_key=/xElKdofUTtg&language=en&signature=";
static NSString * const DIGIT_EYES_BASE_URL = @"https://digit-eyes.com/gtin/v2_0/?";
static NSString * const WALMART_API_KEY_PARAM = @"&apiKey=fypax9zng4qc9rsbktj76mv8";
static NSString * const WALMART_BASE_URL = @"https://api.walmartlabs.com/v1/items?upc=";
static NSString * const GOOGLE_API_KEY_PARAM = @"&cx=008591234760184625385:ifztzuppugi&key=AIzaSyDltBlQgU909CgQ9DA0hOlyZiwy3TrytNk";
static NSString * const GOOGLE_BASE_URL = @"https://www.googleapis.com/customsearch/v1?q=";

@implementation SSBarcodeDataFetcher

+ (void)broadSearchEAN13Code:(NSString *)code completion:(void (^)(SSBarcodeSearchResult *result))completion
{
    // Some codes will report an extra digit in front. We don't want that.
    if (code.length == 13)
    {
        code = [code substringFromIndex:1];
    }
    
    // Digit Eyes
    [SSBarcodeDataFetcher digitEyesSearchUPCCode:code completion:^(SSBarcodeSearchResult * _Nullable result) {
        if (result == nil)
        {
            // Barcode Wal Mart
            [SSBarcodeDataFetcher walmartSearchEAN13Code:code completion:^(SSBarcodeSearchResult * result) {
                if (result == nil)
                {
                    // Next attempt, Barcode Spider
                    [SSBarcodeDataFetcher barcodeSpiderSearchEAN13Code:code completion:^(SSBarcodeSearchResult *result) {
                        if (result == nil)
                        {
                            // Cut my network calls in two pieces, this is my last resort
                            [SSBarcodeDataFetcher googleSearchEAN13Code:code completion:^(SSBarcodeSearchResult *result) {
                                if (result == nil)
                                {
                                    completion(nil);
                                }
                                else
                                {
                                    NSLog(@"Spend Stack - Found barcode from Google Search.");
                                    completion(result);
                                }
                            }];
                        }
                        else
                        {
                            NSLog(@"Spend Stack - Found barcode from Barcode Spider.");
                            completion(result);
                        }
                    }];
                }
                else
                {
                    NSLog(@"Spend Stack - Found barcode from Wal Mart's API.");
                    completion(result);
                }
            }];
        }
        else
        {
            NSLog(@"Spend Stack - Found barcode from Digit Eyes.");
            completion(result);
        }
    }];
}

+ (void)digitEyesSearchUPCCode:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion
{
    NSString *requestString = [DIGIT_EYES_BASE_URL stringByAppendingString:DIGIT_EYES_AUTH_PARAMS];
    requestString = [requestString stringByAppendingString:[code hashedValue:@"Tu57P6e0x4Qw7Fs5"]];
    requestString = [requestString stringByAppendingString:@"&upcCode="];
    requestString = [requestString stringByAppendingString:code];
    
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    requestString = [requestString stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSURL *requestURL = [NSURL URLWithString:requestString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
        if (error)
        {
            completion(nil);
            return;
        }
        
        NSDictionary *resultData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if (isSafeAndKindOfClass(resultData[@"return_code"], [NSString class]) &&
            [resultData[@"return_code"] isEqualToString:@"000"])
        {
            SSBarcodeSearchResult *result = [SSBarcodeSearchResult new];
            result.title = [resultData[@"description"] capitalizedString];
            
            if (isSafeAndKindOfClass(resultData[@"image"], [NSString class]))
            {
                result.image = [NSURL URLWithString:resultData[@"image"]];
            }
            
            completion(result);
        }
        else
        {
            completion(nil);
        }
        
    }] resume];
}

+ (void)walmartSearchEAN13Code:(NSString *)code completion:(void (^)(SSBarcodeSearchResult * _Nullable))completion
{
    NSString *requestString = [NSString stringWithFormat:@"%@%@%@", WALMART_BASE_URL, code, WALMART_API_KEY_PARAM];
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    requestString = [requestString stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSURL *requestURL = [NSURL URLWithString:requestString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
        if (error)
        {
            // Get out
            completion(nil);
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if ([json.allKeys containsObject:@"errors"])
        {
            completion(nil);
        }
        else if (isSafeAndKindOfClass(json[@"items"], [NSArray class]))
        {
            NSDictionary *resultData = ((NSArray *)json[@"items"]).firstObject;
            if ([resultData isKindOfClass:[NSDictionary class]] && isSafeAndKindOfClass(resultData[@"name"], [NSString class]))
            {
                SSBarcodeSearchResult *result = [SSBarcodeSearchResult new];
                result.title = [resultData[@"name"] capitalizedString];
                
                if (isSafeAndKindOfClass(resultData[@"largeImage"], [NSString class]))
                {
                    result.image = [NSURL URLWithString:resultData[@"largeImage"]];
                }
                
                completion(result);
            }
            else
            {
                completion(nil);
            }
        }
        else
        {
            completion(nil);
        }
    }] resume];
}

+ (void)barcodeSpiderSearchEAN13Code:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion
{
    NSString *requestString = [@"https://www.barcodespider.com/" stringByAppendingString:code];
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    requestString = [requestString stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSURL *requestURL = [NSURL URLWithString:requestString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
        if (error)
        {
            completion(nil);
            return;
        }
        
        NSString *rawHTML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        rawHTML = [rawHTML stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // Get title
        NSArray *splitTitle = [rawHTML componentsSeparatedByString:@"is associated with <h3>"];
        NSString *parsedTitle;
        if (splitTitle.count >= 2)
        {
            NSString *proposedTitle = splitTitle.lastObject;
            NSRange parseRange = [proposedTitle rangeOfString:@"</h3>"];
            parsedTitle = [proposedTitle substringToIndex:parseRange.location];
        }
        
        // Get image url
        NSArray *splitImage = [rawHTML componentsSeparatedByString:@"<div id=\"images\">\n<img src=\""];
        NSString *parsedImageURL;
        if (splitImage.count >= 2)
        {
            NSString *proposedImage = splitImage.lastObject;
            NSRange parseRange = [proposedImage rangeOfString:@"\""];
            parsedImageURL = [proposedImage substringToIndex:parseRange.location];
        }
        
        if (parsedTitle == nil)
        {
            completion(nil);
        }
        else
        {
            SSBarcodeSearchResult *result = [SSBarcodeSearchResult new];
            result.title = [parsedTitle capitalizedString];
            if (parsedImageURL) result.image = [NSURL URLWithString:parsedImageURL];
            completion(result);
        }
    }] resume];
}

+ (void)googleSearchEAN13Code:(NSString *)code completion:(void (^)(SSBarcodeSearchResult *))completion
{
    NSString *requestString = [NSString stringWithFormat:@"%@%@%@", GOOGLE_BASE_URL, code, GOOGLE_API_KEY_PARAM];
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    requestString = [requestString stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSURL *requestURL = [NSURL URLWithString:requestString];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
        if (error)
        {
            // Get out
            completion(nil);
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if (isSafeAndKindOfClass(json, [NSDictionary class]))
        {
            if (isSafeAndKindOfClass(json[@"items"], [NSArray class]))
            {
                NSArray *results = json[@"items"];
                
                if (isSafeAndKindOfClass(results.firstObject, [NSDictionary class]))
                {
                    NSString *title = ((NSDictionary *)results.firstObject)[@"title"];
                    
                    if (isSafeAndKindOfClass(title, [NSString class]))
                    {
                        SSBarcodeSearchResult *result = [SSBarcodeSearchResult new];
                        result.title = [title capitalizedString];
                        completion(result);
                    }
                    else
                    {
                        completion(nil);   
                    }
                }
                else
                {
                    completion(nil);
                }
            }
            else
            {
                completion(nil);
            }
        }
        else
        {
           completion(nil);
        }
        
    }] resume];
}

@end
