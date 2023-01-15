//
//  UIContenSizeHeightUtils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/29/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIContenSizeHeightUtils.h"
#import <UIKit/UIKit.h>

@implementation UIContenSizeHeightUtils

/*
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryUnspecified NS_AVAILABLE_IOS(10_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryExtraSmall NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategorySmall NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryMedium NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryLarge NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryExtraLarge NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryExtraExtraLarge NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryExtraExtraExtraLarge NS_AVAILABLE_IOS(7_0);
 
 // Accessibility sizes
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryAccessibilityMedium NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryAccessibilityLarge NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraLarge NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraExtraLarge NS_AVAILABLE_IOS(7_0);
 UIKIT_EXTERN UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraExtraExtraLarge NS_AVAILABLE_IOS(7_0);
 */

+ (CGFloat)heightForTextStyles:(NSArray <NSString *> *)styles margins:(CGFloat)margins traitCollection:(UITraitCollection *)traitCollection
{
    CGFloat calculatedHeight = margins;
    
    if (traitCollection)
    {
        //An acceptable hack, all bolded, larger text sizes have "accessibility" in the string
        calculatedHeight += [traitCollection.preferredContentSizeCategory.lowercaseString containsString:@"accessibility"] ? 6.0f : 0.0f;
    }
    
    for (NSString *textStyle in styles)
    {
        calculatedHeight += [UIFont preferredFontForTextStyle:textStyle].pointSize;
    }
    
    return calculatedHeight;
}

@end
