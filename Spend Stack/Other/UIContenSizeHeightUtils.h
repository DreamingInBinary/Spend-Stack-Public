//
//  UIContenSizeHeightUtils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/29/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIContenSizeHeightUtils : NSObject

+ (CGFloat)heightForTextStyles:(NSArray <NSString *> * _Nonnull)styles margins:(CGFloat)margins traitCollection:(UITraitCollection * _Nullable)traitCollection;

@end
