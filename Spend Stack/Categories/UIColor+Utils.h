//
//  UIColor+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Utils)

+ (UIColor * _Nonnull)colorFromHexString:(NSString * _Nonnull)hexString;
+ (UIImage * _Nonnull)imageWithColor:(UIColor * _Nonnull)color;

@end
