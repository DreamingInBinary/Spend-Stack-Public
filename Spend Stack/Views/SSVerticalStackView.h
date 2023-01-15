//
//  SSVerticalStackView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/21/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSVerticalStackView : UIStackView

@property (nonatomic) UIStackViewAlignment horizontalAlignment;
@property (nonatomic) UIStackViewDistribution verticalDistribution;
- (void)setInsetRect:(UIEdgeInsets)insets;
- (void)setArrangedSubviews:(NSArray <UIView *> *)arrangedSubviews;
- (void)removeArrangedSubviews;

@end
