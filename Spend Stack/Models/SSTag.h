//
//  SSTag.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/29/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGListDiffKit.h"

static const CGFloat TAG_HEIGHT_WIDTH_REGULAR = 20.0f;
static const CGFloat TAG_HEIGHT_WIDTH_ACCESSIBILITY = 40.0f;

static NSString * const _Nonnull AppleRed = @"appleRed";
static NSString * const _Nonnull AppleOrange = @"appleOrange";
static NSString * const _Nonnull AppleYellow = @"appleYellow";
static NSString * const _Nonnull AppleGreen = @"appleGreen";
static NSString * const _Nonnull AppleTealBlue = @"appleTealBlue";
static NSString * const _Nonnull AppleBlue = @"appleBlue";
static NSString * const _Nonnull ApplePurple = @"applePurple";
static NSString * const _Nonnull ApplePink = @"applePink";
static NSString * const _Nonnull AppleNavy = @"appleNavy";
static NSString * const _Nonnull AppleDarkOrange = @"appleDarkOrange";
static NSString * const _Nonnull AppleDarkGreen = @"appleDarkGreen";
static NSString * const _Nonnull AppleDarkPurple = @"appleDarkPurple";
static NSString * const _Nonnull AppleClear = @"clear";

@interface SSTag : SSObject <NSSecureCoding, IGListDiffable>

@property (strong, nonatomic, nonnull) NSString *color;
@property (strong, nonatomic, nonnull) NSString *name;
@property (strong, nonatomic, nonnull) NSNumber *orderingIndex;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithColor:(NSString * _Nonnull)color name:(NSString * _Nonnull)name order:(NSNumber * _Nullable)order;

+ (NSArray <UIColor *> * _Nonnull)tagColors;
+ (NSArray <NSString *> * _Nonnull)tagColorStrings;
+ (UIColor * _Nonnull)miscTagDisplayColor;

@end
