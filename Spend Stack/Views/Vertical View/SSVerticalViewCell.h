//
//  SSVerticalViewCell.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSVerticalViewCell : UIView

@property (strong, nonatomic, nonnull) UIView *contentView;
@property (strong, nonatomic, nonnull) UIColor *rowBackgroundColor;
@property (nonatomic) UIEdgeInsets rowInset;
@property (strong, nonatomic, nonnull) UIColor *separatorColor;
@property (nonatomic) CGFloat separatorHeight;
@property (nonatomic) UIEdgeInsets separatorInset;
@property (nonatomic) BOOL isSeparatorHidden;
@property (nonatomic, copy, nullable) void (^tapHandler)(UIView * _Nonnull view);
@property (nonatomic) BOOL shouldHideSeparator;

- (instancetype _Nonnull)initWithContentView:(UIView * _Nonnull)contentView;


@end
