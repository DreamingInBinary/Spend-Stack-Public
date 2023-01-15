//
//  SSTextView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSTextView : UITextView

@property (strong, nonatomic, nullable) NSString *placeholderText;
@property (nonatomic) CGFloat maximumFontSize;
@property (nonatomic) CGFloat smallestFontSize;

- (instancetype _Nullable)initWithTextStyle:(UIFontTextStyle _Nonnull)textStyle;
- (void)configureFontWeight:(UIFontWeight)weight;

@end
