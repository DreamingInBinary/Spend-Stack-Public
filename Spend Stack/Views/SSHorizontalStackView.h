//
//  SSHorizontalStackView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/21/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSHorizontalStackView : UIStackView

@property (nonatomic) UIStackViewAlignment verticalAlignment;
@property (nonatomic) UIStackViewDistribution widthDistribution;
- (void)setInsetRect:(UIEdgeInsets)insets;
- (void)setArrangedSubviews:(NSArray <UIView *> *)arrangedSubviews;

@end
