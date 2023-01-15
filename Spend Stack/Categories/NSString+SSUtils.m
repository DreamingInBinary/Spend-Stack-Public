//
//  NSString+SSUtils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "NSString+SSUtils.h"

@implementation NSString (SSUtils)

- (NSString *)trimmed
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (CGRect)boundingRectWithWidth:(CGFloat)width text:(NSString *)text font:(UIFont *)font
{
    NSStringDrawingOptions options = (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading);
    NSDictionary *textAttributes = @{NSFontAttributeName: font};
    
    return CGRectIntegral([text boundingRectWithSize:CGSizeMake(width, FLT_MAX)
                                             options:options
                                          attributes:textAttributes
                                             context:nil]);
}

@end
