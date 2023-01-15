//
//  SSCitizenship.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/9/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSCitizenship.h"

@implementation SSCitizenship

+ (BOOL)allowCustomPresentation
{
    return [SSCitizenship prefersReducedMotion] == NO &&
           [SSCitizenship lowPowerOn] == NO &&
           [SSCitizenship voiceOverOn] == NO;
}

+ (BOOL)prefersReducedMotion
{
    return UIAccessibilityIsReduceMotionEnabled();
}

+ (BOOL)prefersBoldText
{
    return UIAccessibilityIsBoldTextEnabled();
}

+ (BOOL)prefersIncreasedContrast
{
    // If you set a tint color, you shouldn't need to worry about this as iOS takes care of it.
    return UIAccessibilityDarkerSystemColorsEnabled();
}

+ (BOOL)lowPowerOn
{
    return [NSProcessInfo processInfo].isLowPowerModeEnabled;
}

+ (BOOL)voiceOverOn
{
    return UIAccessibilityIsVoiceOverRunning();
}

+ (BOOL)allowsBlurring
{
    return !UIAccessibilityIsReduceTransparencyEnabled();
}

+ (BOOL)accessibilityFontsEnabled
{
    return UIContentSizeCategoryIsAccessibilityCategory([SSCitizenship closestWindow].traitCollection.preferredContentSizeCategory);
}

+ (BOOL)displaySupportsP3ColorSpace
{
    return [[[UIScreen mainScreen] traitCollection] displayGamut] == UIDisplayGamutP3;
}

+ (BOOL)idiomIsiPad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

#pragma mark - Animations

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    if ([NSProcessInfo processInfo].lowPowerModeEnabled == YES || UIAccessibilityIsVoiceOverRunning())
    {
        animations();
        completion(YES);
        return;
    }

    [UIView animateWithDuration:duration delay:delay options:options animations:animations completion:completion];
}

+ (void)animateWithDuration:(NSTimeInterval)interval delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)damping initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    if ([NSProcessInfo processInfo].lowPowerModeEnabled == YES || UIAccessibilityIsVoiceOverRunning())
    {
        animations();
        completion(YES);
        return;
    }

    [UIView animateWithDuration:interval delay:delay usingSpringWithDamping:damping initialSpringVelocity:velocity options:options animations:animations completion:completion];
}

#pragma mark - Blurring

+ (void)setViewAsTransparentIfPossible:(UIView *)view
{
    
    if ([SSCitizenship allowsBlurring] && [SSCitizenship lowPowerOn] == NO)
    {
        view.backgroundColor = [UIColor clearColor];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        blurEffectView.userInteractionEnabled = NO;
        [view insertSubview:blurEffectView atIndex:0];
        
        [blurEffectView anchorToEdgesWithoutLeadingTrailing:view];
    }
    else
    {
        // Fallack, but you should call this assuming blurring is allowed
        view.backgroundColor = [UIColor systemBackgroundColor];
    }
}

+ (__kindof UIView *)transparentViewIfPossibleWithStyle:(UIBlurEffectStyle)style
{
    if ([SSCitizenship allowsBlurring] && [SSCitizenship lowPowerOn] == NO)
    {
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        blurEffectView.userInteractionEnabled = NO;
        
        return blurEffectView;
    }
    else
    {
        UIView *whiteView = [UIView new];
        whiteView.backgroundColor = [UIColor systemBackgroundColor];
        
        return whiteView;
    }
}

+ (__kindof UIView *)transparentViewIfPossible
{
    return [SSCitizenship transparentViewIfPossibleWithStyle:UIBlurEffectStyleSystemThinMaterial];
}

+ (__kindof UIView *)darkTransparentViewIfPossible
{
    if ([SSCitizenship allowsBlurring] && [SSCitizenship lowPowerOn] == NO)
    {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        blurEffectView.userInteractionEnabled = NO;
        
        return blurEffectView;
    }
    else
    {
        UIView *whiteView = [UIView new];
        whiteView.backgroundColor = [UIColor blackColor];
        
        return whiteView;
    }
}

+ (__kindof UIView *)dimmingTransparentViewIfPossible:(UIUserInterfaceStyle)style
{
    if ([SSCitizenship allowsBlurring] && [SSCitizenship lowPowerOn] == NO)
    {
        UIBlurEffect *blurEffect;
        
        if (style == UIUserInterfaceStyleDark)
        {
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        }
        else
        {
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        }
  
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
        blurEffectView.userInteractionEnabled = NO;
        
        return blurEffectView;
    }
    else
    {
        UIView *whiteView = [UIView new];
        whiteView.backgroundColor = [UIColor ssOppositeSystemBackgroundColor];
        
        return whiteView;
    }
}

+ (void)addSubView:(UIView *)subview toViewRespectingBlur:(__kindof UIView *)view
{
    if ([view isKindOfClass:[UIVisualEffectView class]])
    {
        [((UIVisualEffectView *)view).contentView addSubview:subview];
    }
    else
    {
        [view addSubview:subview];
    }
}

+ (void)setViewFadeInAnimation:(__kindof UIView * _Nonnull)view
{
    [SSCitizenship setViewFadeInAnimation:view effectStyle:UIBlurEffectStyleSystemThinMaterial];
}

+ (void)setViewFadeInAnimation:(__kindof UIView *)view effectStyle:(UIBlurEffectStyle)effectStyle
{
    if ([view isKindOfClass:[UIVisualEffectView class]])
    {
        ((UIVisualEffectView *)view).effect = [UIBlurEffect effectWithStyle:effectStyle];
    }
    else
    {
        view.alpha = 0.25f;
    }
}

+ (void)setDarkViewFadeInAnimation:(__kindof UIView * _Nonnull)view
{
    if ([view isKindOfClass:[UIVisualEffectView class]])
    {
        ((UIVisualEffectView *)view).effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    else
    {
        view.alpha = 0.25f;
    }
}

+ (void)setViewFadeOutAnimation:(__kindof UIView *)view
{
    if ([view isKindOfClass:[UIVisualEffectView class]])
    {
        ((UIVisualEffectView *)view).effect = nil;
    }
    else
    {
        view.alpha = 0.0f;
    }
}

#pragma mark - Private

+ (UIWindow *)closestWindow
{
    UIWindow *window;
    
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes)
    {
        if ([scene isKindOfClass:[UIWindowScene class]])
        {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            window = windowScene.windows.firstObject;
            break;
        }
    }
    
    NSAssert(window != nil, @"Spend Stack - Couldn't find a connected window.");
    return window;
}

@end
