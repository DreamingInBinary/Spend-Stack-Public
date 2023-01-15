//
//  SSCitizenship.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/9/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SSCitizenship : NSObject

+ (BOOL)allowCustomPresentation;
+ (BOOL)prefersReducedMotion;
+ (BOOL)prefersBoldText;
+ (BOOL)prefersIncreasedContrast;
+ (BOOL)lowPowerOn;
+ (BOOL)voiceOverOn;
+ (BOOL)allowsBlurring;
+ (BOOL)accessibilityFontsEnabled;
+ (BOOL)displaySupportsP3ColorSpace;
+ (BOOL)idiomIsiPad;

//If you already have a view, i.e. a view controller, use this
+ (void)setViewAsTransparentIfPossible:(UIView * _Nonnull)view;
//If you're creating the view, use this
+ (__kindof UIView * _Nonnull)transparentViewIfPossible;
+ (__kindof UIView * _Nonnull)transparentViewIfPossibleWithStyle:(UIBlurEffectStyle)style;
+ (__kindof UIView * _Nonnull)darkTransparentViewIfPossible;
+ (__kindof UIView * _Nonnull)dimmingTransparentViewIfPossible:(UIUserInterfaceStyle)style;
+ (void)addSubView:(UIView * _Nonnull)subview toViewRespectingBlur:(__kindof UIView * _Nonnull)view;
+ (void)setViewFadeInAnimation:(__kindof UIView * _Nonnull)view;
+ (void)setViewFadeInAnimation:(__kindof UIView * _Nonnull)view effectStyle:(UIBlurEffectStyle)effectStyle;
+ (void)setDarkViewFadeInAnimation:(__kindof UIView * _Nonnull)view;
+ (void)setViewFadeOutAnimation:(__kindof UIView * _Nonnull)view;

@end
