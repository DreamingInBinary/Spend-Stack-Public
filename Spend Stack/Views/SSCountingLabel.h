//
//  SSCountingLabel.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/14/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSLabel.h"

typedef NS_ENUM(NSInteger, SSLabelCountingMethod) {
    SSLabelCountingMethodEaseInOut,
    SSLabelCountingMethodEaseIn,
    SSLabelCountingMethodEaseOut,
    SSLabelCountingMethodLinear
};

typedef NSString * _Nullable (^SSCountingLabelFormatBlock)(CGFloat value);
typedef NSAttributedString * _Nullable (^SSCountingLabelAttributedFormatBlock)(CGFloat value);

@interface SSCountingLabel : SSLabel

@property (nonatomic, strong, nullable) NSString *format;
@property (nonatomic, assign) SSLabelCountingMethod method;
@property (nonatomic, assign) NSTimeInterval animationDuration;

@property (nonatomic, copy, nullable) SSCountingLabelFormatBlock formatBlock;
@property (nonatomic, copy, nullable) SSCountingLabelAttributedFormatBlock attributedFormatBlock;
@property (nonatomic, copy) void (^ _Nullable completionBlock)(void);

- (instancetype _Nonnull)initWithTextStyle:(UIFontTextStyle _Nonnull)textStyle;
-(void)countFrom:(CGFloat)startValue to:(CGFloat)endValue;
-(void)countFrom:(CGFloat)startValue to:(CGFloat)endValue withDuration:(NSTimeInterval)duration;

-(void)countFromCurrentValueTo:(CGFloat)endValue;
-(void)countFromCurrentValueTo:(CGFloat)endValue withDuration:(NSTimeInterval)duration;

-(void)countFromZeroTo:(CGFloat)endValue;
-(void)countFromZeroTo:(CGFloat)endValue withDuration:(NSTimeInterval)duration;

- (CGFloat)currentValue;
- (void)updateCurrentValue:(CGFloat)currentValue;

@end
