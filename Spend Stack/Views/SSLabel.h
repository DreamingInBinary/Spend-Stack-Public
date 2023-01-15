//
//  SSLabel.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSLabel : UILabel

@property (nonatomic, readonly, nonnull) UIFontTextStyle textStyle;
@property (nonatomic) CGFloat maximumFontSize;
@property (nonatomic) CGFloat smallestFontSize;

- (instancetype _Nonnull)initWithTextStyle:(UIFontTextStyle _Nonnull)textStyle;
- (void)configureFontWeight:(UIFontWeight)weight;
- (UIPreviewParameters * _Nonnull)paremetersHuggingText;

@end
