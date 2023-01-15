//
//  SSVerticalStackView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/21/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSVerticalStackView.h"

@implementation SSVerticalStackView

#pragma mark - Custom Getter/Setter

- (UIStackViewAlignment)horizontalAlignment
{
    return self.alignment;
}

- (void)setHorizontalAlignment:(UIStackViewAlignment)horizontalAlignment
{
    self.alignment = horizontalAlignment;
}

- (UIStackViewDistribution)verticalDistribution
{
    return self.distribution;
}

- (void)setVerticalDistribution:(UIStackViewDistribution)verticalDistribution
{
    self.distribution = verticalDistribution;
}

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.axis = UILayoutConstraintAxisVertical;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)setInsetRect:(UIEdgeInsets)insets
{
    self.layoutMargins = insets;
    self.layoutMarginsRelativeArrangement = (UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero)) ? NO : YES;
}

- (void)setArrangedSubviews:(NSArray<UIView *> *)arrangedSubviews
{
    for (UIView *view in arrangedSubviews)
    {
        [self addArrangedSubview:view];
    }
}

- (void)removeArrangedSubviews
{
    NSArray <UIView *> *arrangedViews = self.arrangedSubviews;
    
    if (arrangedViews.count > 0)
    {
        for (UIView *view in arrangedViews)
        {
            [self removeArrangedSubview:view];
        }
    }
}

@end
