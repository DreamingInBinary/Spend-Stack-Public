//
//  UIColor+SSThemes.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SSThemes)

+ (UIColor * _Nonnull)ssControlHighlightedColor;
+ (UIColor * _Nonnull)ssPrimaryColor;
+ (UIColor * _Nonnull)ssSecondaryColor;
+ (UIColor * _Nonnull)ssMainFontColor;
+ (UIColor * _Nonnull)ssSectionHeaderColor;
+ (UIColor * _Nonnull)ssTextPlaceholderColor;
+ (UIColor * _Nonnull)ssMutedColor;
+ (UIColor * _Nonnull)ssSelectedBackgroundColor;
+ (UIColor * _Nonnull)ssDimmingBackgroundColor;
+ (UIColor * _Nonnull)ssOppositeSystemBackgroundColor;

// Apple Colors
+ (UIColor * _Nonnull)appleRed;
+ (UIColor * _Nonnull)appleOrange;
+ (UIColor * _Nonnull)appleYellow;
+ (UIColor * _Nonnull)appleGreen;
+ (UIColor * _Nonnull)appleTealBlue;
+ (UIColor * _Nonnull)appleBlue;
+ (UIColor * _Nonnull)applePurple;
+ (UIColor * _Nonnull)applePink;

// My Own Added Apple Colors
+ (UIColor * _Nonnull)appleNavy;
+ (UIColor * _Nonnull)appleDarkOrange;
+ (UIColor * _Nonnull)appleDarkGreen;
+ (UIColor * _Nonnull)appleDarkPurple;
+ (UIColor * _Nonnull)appleDarkBlue;

// No color
+ (UIColor * _Nonnull)clear;

// Social Icons
+ (UIColor * _Nonnull)facebookBlue;
+ (UIColor * _Nonnull)twitterBlue;
+ (UIColor * _Nonnull)instagramPink;
+ (UIColor * _Nonnull)redditOrange;

@end
