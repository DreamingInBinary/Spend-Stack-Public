//
//  SSLabel.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSLabel.h"
#import "UIColor+SSThemes.h"

@interface SSLabel()

@property (nonatomic, readwrite, nonnull) UIFontTextStyle textStyle;
@property (nonatomic) CGFloat weight;

@end

@implementation SSLabel

#pragma mark - Custom Setters

- (void)setMaximumFontSize:(CGFloat)maximumFontSize
{
    _maximumFontSize = maximumFontSize;
    
    // See if our current font exceeds our new desired upper limit
    if ([self fontDoesExceedMaximumFontSize:self.font.pointSize])
    {
        // Forward font weight if we set it
        if (_weight != INFINITY)
        {
            self.font = [UIFont systemFontOfSize:_maximumFontSize weight:_weight];
        }
        else
        {
            self.font = [UIFont systemFontOfSize:_maximumFontSize];
        }
    }
}

- (void)setSmallestFontSize:(CGFloat)smallestFontSize
{
    _smallestFontSize = smallestFontSize;
    
    // See if our current font exceeds our new desired lower limit
    if ([self fontDoesExceedSmallestFontSize:self.font.pointSize])
    {
        // Forward font weight if we set it
        if (_weight != INFINITY)
        {
            self.font = [UIFont systemFontOfSize:_smallestFontSize weight:_weight];
        }
        else
        {
            self.font = [UIFont systemFontOfSize:_smallestFontSize];
        }
    }
}

#pragma mark - Initializers

- (instancetype)initWithTextStyle:(UIFontTextStyle)textStyle
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.maximumFontSize = 0;
        self.smallestFontSize = 0;
        self.weight = INFINITY;
        self.textStyle = textStyle;
        self.font = [UIFont preferredFontForTextStyle:self.textStyle];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.adjustsFontForContentSizeCategory = YES;
        self.numberOfLines = 0;
        self.textColor = [UIColor ssMainFontColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)configureFontWeight:(UIFontWeight)weight
{
    self.weight = weight;
    self.font = [UIFont systemFontOfSize:self.font.pointSize weight:self.weight];
}

- (UIPreviewParameters *)paremetersHuggingText
{
    UIPreviewParameters *params = [UIPreviewParameters new];
    CGRect textRect = [self.text boundingRectWithWidth:self.boundsWidth text:self.text font:self.font];
    textRect = CGRectMake(self.boundsWidth/2 - textRect.size.width/2, textRect.origin.y, textRect.size.width, self.boundsHeight);
    textRect = CGRectInset(textRect, -6, -6);
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:textRect cornerRadius:SSSpacingMargin];
    
    return params;
}

#pragma mark - Font Weight | Sizing | Content Size Changes

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    CGFloat newPreferredStyleFontSize = [UIFont preferredFontForTextStyle:self.textStyle].pointSize;
    
    BOOL exceedsMaximumFontSize = [self fontDoesExceedMaximumFontSize:newPreferredStyleFontSize];
    BOOL exceedsSmallestFontSize = [self fontDoesExceedSmallestFontSize:newPreferredStyleFontSize];
    
    if (exceedsMaximumFontSize)
    {
        NSLog(@"Spend Stack - SSLabel (text:%@) didn't respond to UIContentSizeCategoryDidChangeNotification because the new size was larger than the maximum size.", self.text);
        if (_weight != INFINITY)
        {
            self.font = [UIFont systemFontOfSize:_maximumFontSize weight:_weight];
        }
        else
        {
            self.font = [UIFont systemFontOfSize:_maximumFontSize];
        }
        
        return;
    }
    else if (exceedsSmallestFontSize)
    {
        NSLog(@"Spend Stack - SSLabel (text:%@) didn't respond to UIContentSizeCategoryDidChangeNotification because the new size was smaller than the minimum size. Setting it the smallest preferred size now.", self.text);
        if (_weight != INFINITY)
        {
            self.font = [UIFont systemFontOfSize:_smallestFontSize weight:_weight];
        }
        else
        {
            self.font = [UIFont systemFontOfSize:_smallestFontSize];
        }
        
        return;
    }
    
    self.font = [UIFont systemFontOfSize:newPreferredStyleFontSize weight:self.weight];
}

- (BOOL)fontDoesExceedMaximumFontSize:(CGFloat)size
{
    BOOL exceedsMaximumFontSize = (self.maximumFontSize != 0 && size > self.maximumFontSize);
    return exceedsMaximumFontSize;
}

- (BOOL)fontDoesExceedSmallestFontSize:(CGFloat)size
{
    BOOL exceedsSmallestFontSize = (self.smallestFontSize != 0 && size < self.smallestFontSize);
    return exceedsSmallestFontSize;
}

@end
