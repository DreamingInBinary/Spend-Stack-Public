//
//  SSHorizontalStackView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/21/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSHorizontalStackView.h"

@implementation SSHorizontalStackView

#pragma mark - Custom Getter/Setter

- (UIStackViewAlignment)verticalAlignment
{
    return self.alignment;
}

- (void)setVerticalAlignment:(UIStackViewAlignment)verticalAlignment
{
    self.alignment = verticalAlignment;
}

- (UIStackViewDistribution)widthDistribution
{
    return self.distribution;
}

- (void)setWidthDistribution:(UIStackViewDistribution)widthDistribution
{
    self.distribution = widthDistribution;
}

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.axis = UILayoutConstraintAxisHorizontal;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Content Size

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    self.axis = [SSCitizenship accessibilityFontsEnabled] ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal;
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

@end
