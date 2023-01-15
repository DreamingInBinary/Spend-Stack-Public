//
//  ExplainerDataUtil.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "ExplainerDataUtil.h"

@interface ExplainerDataUtil()

@property (nonatomic) ExplainFeature featureToExplain;

@end

@implementation ExplainerDataUtil

#pragma mark - Initializer

- (instancetype _Nonnull)initWithExplainedFeature:(ExplainFeature)feature
{
    self = [super init];
    
    if (self)
    {
        self.featureToExplain = feature;
    }
    
    return self;
}

#pragma mark - Data

- (NSString *)featureViewControllerTitle
{
    switch (self.featureToExplain)
    {
        case ExplainFeatureTags:
            return ss_Localized(@"ex.util.tag");
            break;
        case ExplainFeatureTagsFooterTotals:
            return ss_Localized(@"ex.util.tagTotal");
            break;
        case ExplainFeatureTotalHeader:
            return ss_Localized(@"ex.util.listTotal");
            break;
        case ExplainFeatureUseWholeNumbers:
            return ss_Localized(@"ex.util.wholeNum");
            break;
        case ExplainFeatureNewListTax:
            return ss_Localized(@"ex.util.tax");
            break;
        case ExplainFeatureNewListChecklist:
            return ss_Localized(@"ex.util.check");
            break;
        case ExplainFeatureNewListCurrency:
            return ss_Localized(@"ex.util.currency");
            break;
        default:
            return @"";
            break;
    }
}

- (UIImage *)featureImageWithScale:(CGFloat)scale containerWidth:(CGFloat)width
{
    switch (self.featureToExplain)
    {
        case ExplainFeatureTags:
            return [UIImage downsampledImageFromData:UIImageJPEGRepresentation([UIImage imageNamed:@"totalDisplay"], 1.0)
                                               scale:scale
                                        maxPixelSize:width];
            break;
        case ExplainFeatureTagsFooterTotals:
            return [UIImage downsampledImageFromData:UIImageJPEGRepresentation([UIImage imageNamed:@"TagTotals"], 1.0)
                                               scale:scale
                                        maxPixelSize:width];
            break;
        case ExplainFeatureTotalHeader:
            return [UIImage downsampledImageFromData:UIImageJPEGRepresentation([UIImage imageNamed:@"ListTotal"], 1.0)
                                               scale:scale
                                        maxPixelSize:width];
        default:
            return [UIImage downsampledImageFromData:UIImageJPEGRepresentation([UIImage imageNamed:@"TagsExplainer"], 1.0)
                                               scale:scale
                                        maxPixelSize:width];
            break;
    }
}

- (NSString *)featureImageAccessibilityLabel
{
    switch (self.featureToExplain)
    {
        case ExplainFeatureTags:
            return ss_Localized(@"ex.util.acc1");
            break;
        case ExplainFeatureTagsFooterTotals:
            return ss_Localized(@"ex.util.acc2");
            break;
        case ExplainFeatureTotalHeader:
            return ss_Localized(@"ex.util.acc3");
        default:
            return @"";
            break;
    }
}

- (NSString *)featureHeading
{
    switch (self.featureToExplain)
    {
        case ExplainFeatureTags:
            return ss_Localized(@"ex.util.subHead1");
            break;
        case ExplainFeatureTagsFooterTotals:
            return ss_Localized(@"ex.util.subHead2");
            break;
        case ExplainFeatureTotalHeader:
            return ss_Localized(@"ex.util.subhead3");
            break;
        case ExplainFeatureUseWholeNumbers:
            return ss_Localized(@"ex.util.subhead4");
            break;
        case ExplainFeatureNewListTax:
            return ss_Localized(@"ex.util.subhead5");
            break;
        case ExplainFeatureNewListChecklist:
            return ss_Localized(@"ex.util.subhead6");
            break;
        case ExplainFeatureNewListCurrency:
            return ss_Localized(@"ex.util.subhead7");
            break;
        default:
            return @"";
            break;
    }
}

- (NSString *)featureDescription
{
    switch (self.featureToExplain)
    {
        case ExplainFeatureTags:
            return ss_Localized(@"ex.util.detail1");
            break;
        case ExplainFeatureTagsFooterTotals:
            return ss_Localized(@"ex.util.detail2");
            break;
        case ExplainFeatureTotalHeader:
            return ss_Localized(@"ex.util.detail3");
            break;
        case ExplainFeatureUseWholeNumbers:
            return ss_Localized(@"ex.util.detail4");
            break;
        case ExplainFeatureNewListTax:
            return ss_Localized(@"ex.util.detail5");
            break;
        case ExplainFeatureNewListChecklist:
            return ss_Localized(@"ex.util.detail6");
            break;
        case ExplainFeatureNewListCurrency:
            return ss_Localized(@"ex.util.detail7");
            break;
        default:
            return @"";
            break;
    }
}

@end
