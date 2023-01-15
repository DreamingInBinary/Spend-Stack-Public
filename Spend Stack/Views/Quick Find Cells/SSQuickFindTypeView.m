//
//  SSQuickFindTypeView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/5/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSQuickFindTypeView.h"
#import "SSQuickFindResult.h"

@interface SSQuickFindTypeView()

@property (strong, nonatomic, nonnull) SSLabel *typeLabel;

@end

@implementation SSQuickFindTypeView

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.typeLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption2];
        self.typeLabel.textAlignment = NSTextAlignmentCenter;
        self.typeLabel.textColor = [UIColor ssMainFontColor];
        [self.typeLabel configureFontWeight:UIFontWeightSemibold];
        [self addSubview:self.typeLabel];
        
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 4.0f;
        self.backgroundColor = [UIColor ssMutedColor];
        
        [self setConstraints];
    }
    
    return self;
}

#pragma mark - Constraints

- (void)setConstraints
{
    [self.typeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightElementMargin);
        make.top.equalTo(self.mas_top).with.offset(4);
        make.bottom.equalTo(self.mas_bottom).with.offset(-4);
    }];
    
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.greaterThanOrEqualTo(@60);
        make.height.greaterThanOrEqualTo(@30);
    }];
}

#pragma mark - Public Methods

- (void)setData:(SSQuickFindResult * _Nonnull)result
{
    self.typeLabel.text = stringFromType(result.type);
}

@end
