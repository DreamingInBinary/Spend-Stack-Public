//
//  SSListSectionHeaderView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListSectionHeaderView.h"

@interface SSListSectionHeaderView()

@property (strong, nonatomic, nonnull) SSLabel *titleLabel;

@end

@implementation SSListSectionHeaderView

#pragma mark - Custom Setters

- (void)setTitleString:(NSString *)titleString
{
    _titleString = titleString;
    _titleLabel.text = _titleString;
}

#pragma mark - Initializer

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.titleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle3];
        [self.titleLabel configureFontWeight:UIFontWeightSemibold];
        
        [self.contentView addSubview:self.titleLabel];
        
        [self setConstraints];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Constraint Handling

- (void)setConstraints
{
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.contentView.mas_bottom);
        make.right.equalTo(self.contentView.mas_rightMargin);
    }];
}

- (CGFloat)estimatedHeightForHeaderInView:(UIView *)view
{
    CGFloat totalHeight = 0.0f;
    CGFloat labelWidth = view == nil ? self.contentView.boundsWidth : view.boundsWidth;
    labelWidth -= (SSSpacingBigMargin * 2);
    CGFloat topPadding = SSTopBigElementMargin;
    CGFloat bottomPadding = SSTopBigElementMargin;

    // Title label
    CGFloat titleHeight = [self.titleLabel.text boundingRectWithWidth:labelWidth
                                                                 text:self.titleLabel.text
                                                                 font:self.titleLabel.font].size.height;
    
    totalHeight = topPadding + titleHeight + bottomPadding;
    return roundf(totalHeight);
}

@end
