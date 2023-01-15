//
//  SSBarcodeSearchResult.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/12/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSBarcodeSearchResult : NSObject

@property (strong, nonatomic, nonnull) NSString *title;
@property (strong, nonatomic, nullable) NSURL *image;
@property (strong, nonatomic, nullable) NSData *imageData;
@property (strong, nonatomic, nullable) NSDecimalNumber *price;

@end
