//
//  SSVerticalSeparatorView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSVerticalSeparatorView.h"

@implementation SSVerticalSeparatorView

@synthesize color = _color;

#pragma mark - Custom Getter/Setters

- (UIColor *)color
{
    if (!_color) return [UIColor clearColor];
    return _color;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.backgroundColor = _color;
}

- (void)setSs_height:(CGFloat)height
{
    _height = height;
    [self invalidateIntrinsicContentSize];
}

#pragma mark - Initializers

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

#pragma mark - Overrides

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

@end
