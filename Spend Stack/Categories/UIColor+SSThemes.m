//
//  UIColor+SSThemes.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIColor+SSThemes.h"
#import "UIColor+Utils.h"

static NSString * const ssControlHighlightedColorHex = @"EFEFF4";
static NSString * const ssPrimaryColorHex = @"70A2F9";
static NSString * const ssSecondaryColorHex = @"C7C7CD";
static NSString * const ssMainFontColorHex = @"3F464B";
static NSString * const ssSectionHeaderColorHex = @"6D6D72";
static NSString * const ssTextPlaceholderColorHex = @"9A9A9A";
static NSString * const ssMutedColor = @"C8C7CC";

@implementation UIColor (SSThemes)

+ (UIColor * _Nonnull)ssControlHighlightedColor
{
    return [UIColor colorFromHexString:ssControlHighlightedColorHex];
}

+ (UIColor * _Nonnull)ssPrimaryColor
{
    return [UIColor colorFromHexString:ssPrimaryColorHex];
}

+ (UIColor * _Nonnull)ssSecondaryColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor secondaryLabelColor];
        }
        else
        {
            return [UIColor colorFromHexString:ssSecondaryColorHex];
        }
    }];
}

+ (UIColor * _Nonnull)ssMainFontColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor labelColor];
        }
        else
        {
            return [UIColor colorFromHexString:ssMainFontColorHex];
        }
    }];
}

+ (UIColor * _Nonnull)ssMutedColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor systemGray3Color];
        }
        else
        {
            return [UIColor colorFromHexString:ssMutedColor];
        }
    }];
}

#pragma mark - Control Specific

+ (UIColor * _Nonnull)ssSectionHeaderColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor systemGray2Color];
        }
        else
        {
            return [UIColor colorFromHexString:ssSectionHeaderColorHex];
        }
    }];
}

+ (UIColor * _Nonnull)ssTextPlaceholderColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor labelColor];
        }
        else
        {
            return [UIColor colorFromHexString:ssTextPlaceholderColorHex];
        }
    }];
}

+ (UIColor *)ssSelectedBackgroundColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor quaternarySystemFillColor];
        }
        else
        {
            return [UIColor colorFromHexString:@"F2F2F2"];
        }
    }];
}

+ (UIColor *)ssDimmingBackgroundColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor tertiarySystemBackgroundColor];
        }
        else
        {
            return [UIColor blackColor];
        }
    }];
}

+ (UIColor *)ssOppositeSystemBackgroundColor
{
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        {
            return [UIColor whiteColor];
        }
        else
        {
            return [UIColor blackColor];
        }
    }];
}


#pragma mark - Apple's HIG Colors

+ (UIColor * _Nonnull)appleRed
{
    return [UIColor colorWithRed:(CGFloat)1.000000 green:(CGFloat)0.231373 blue:(CGFloat)0.188235 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleOrange
{
    return [UIColor colorWithRed:(CGFloat)1.000000 green:(CGFloat)0.584314 blue:(CGFloat)0.282353 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleYellow
{
    return [UIColor colorWithRed:(CGFloat)1.000000 green:(CGFloat)0.800000 blue:(CGFloat)0.000000 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleGreen
{
    return [UIColor colorWithRed:(CGFloat)0.298039 green:(CGFloat)0.850980 blue:(CGFloat)0.392157 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleTealBlue
{
    return [UIColor colorWithRed:(CGFloat)0.352941 green:(CGFloat)0.784314 blue:(CGFloat)0.980392 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleBlue
{
    return [UIColor colorWithRed:(CGFloat)0.000000 green:(CGFloat)0.478431 blue:(CGFloat)1.000000 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)applePurple
{
    return [UIColor colorWithRed:(CGFloat)0.345098 green:(CGFloat)0.337255 blue:(CGFloat)0.839216 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)applePink
{
    return [UIColor colorWithRed:(CGFloat)1.000000 green:(CGFloat)0.176471 blue:(CGFloat)0.333333 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleNavy
{
    return [UIColor colorWithRed:(CGFloat)0.172549 green:(CGFloat)0.243137 blue:(CGFloat)0.313725 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleDarkOrange
{
    return [UIColor colorWithRed:(CGFloat)0.827450 green:(CGFloat)0.329411 blue:(CGFloat)0.000000 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleDarkGreen
{
    return [UIColor colorWithRed:(CGFloat)0.086274 green:(CGFloat)0.627450 blue:(CGFloat)0.521568 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleDarkPurple
{
    return [UIColor colorWithRed:(CGFloat)0.607843 green:(CGFloat)0.349019 blue:(CGFloat)0.713725 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)appleDarkBlue
{
    return [UIColor colorWithRed:(CGFloat)0.231373 green:(CGFloat)0.349020 blue:(CGFloat)0.596078 alpha:(CGFloat)1.000000];
}

+ (UIColor * _Nonnull)clear
{
    return [UIColor clearColor];
}

#pragma mark - Social Colors

+ (UIColor * _Nonnull)facebookBlue
{
    return [UIColor colorFromHexString:@"#3b5998"];
}

+ (UIColor * _Nonnull)twitterBlue
{
    return [UIColor colorFromHexString:@"#55acee"];
}

+ (UIColor * _Nonnull)instagramPink
{
    return [UIColor colorFromHexString:@"#e53c5f"];
}

+ (UIColor * _Nonnull)redditOrange
{
    return [UIColor colorFromHexString:@"#ff4500"];
}

@end
