//
//  SSBarcodeDataFetcher.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSBarcodeSearchResult.h"

@interface SSBarcodeDataFetcher : NSObject

+ (void)broadSearchEAN13Code:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion;
+ (void)digitEyesSearchUPCCode:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion;
+ (void)walmartSearchEAN13Code:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion;
+ (void)barcodeSpiderSearchEAN13Code:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion;
+ (void)googleSearchEAN13Code:(NSString * _Nonnull)code completion:(void (^ _Nonnull)(SSBarcodeSearchResult * _Nullable result))completion;

@end
