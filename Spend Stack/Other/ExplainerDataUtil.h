//
//  ExplainerDataUtil.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ExplainFeature) {
    ExplainFeatureTags,
    ExplainFeatureTagsFooterTotals,
    ExplainFeatureTotalHeader,
    ExplainFeatureUseWholeNumbers,
    ExplainFeatureNewListTax,
    ExplainFeatureNewListChecklist,
    ExplainFeatureNewListCurrency
};

@interface ExplainerDataUtil : NSObject

- (instancetype _Nonnull)initWithExplainedFeature:(ExplainFeature)feature;

- (NSString * _Nonnull)featureViewControllerTitle;
- (UIImage * _Nonnull)featureImageWithScale:(CGFloat)scale containerWidth:(CGFloat)width;
- (NSString * _Nonnull)featureImageAccessibilityLabel;
- (NSString * _Nonnull)featureHeading;
- (NSString * _Nonnull)featureDescription;

@end
