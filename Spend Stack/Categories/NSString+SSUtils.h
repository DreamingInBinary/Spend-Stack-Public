//
//  NSString+SSUtils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SSUtils)

- (NSString * _Nonnull)trimmed;
- (CGRect)boundingRectWithWidth:(CGFloat)width text:(NSString * _Nonnull)text font:(UIFont *_Nonnull)font;

@end
