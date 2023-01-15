//
//  SSImageExifLabel.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSLabel.h"

@interface SSImageExifLabel : SSLabel

+ (instancetype _Nullable)new NS_UNAVAILABLE;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nullable)initWithTextStyle:(UIFontTextStyle _Nonnull)textStyle image:(UIImage * _Nonnull)image NS_DESIGNATED_INITIALIZER;

@end
