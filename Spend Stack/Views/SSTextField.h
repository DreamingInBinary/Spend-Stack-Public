//
//  SSTextField.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSTextField : UITextField

@property (nonatomic) CGFloat maximumFontSize;
@property (nonatomic) CGFloat smallestFontSize;

- (instancetype _Nonnull)initWithTextStyle:(UIFontTextStyle _Nonnull)textStyle;
- (void)configureFontWeight:(UIFontWeight)weight;

// Useful for entry scenarios like where we want a percent sign or a weight symbol on the end all the time.
- (void)changeFocusToSecondToLastCharacter;

@end
