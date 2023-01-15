//
//  SSHeaderCollectionReusableView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/2/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSHeaderCollectionReusableView.h"

@interface SSHeaderCollectionReusableView()

@property (strong, nonatomic, readwrite, nonnull) SSLabel *label;

@end;

@implementation SSHeaderCollectionReusableView

#pragma mark - Initializers

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.label = [[SSLabel alloc] initWithTextStyle:[SSHeaderCollectionReusableView headerTextStyle]];
        [self.label configureFontWeight:UIFontWeightSemibold];
        self.label.textColor = [UIColor ssMainFontColor];
        
        [self addSubview:self.label];
        
        [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(SSSpacingMargin, SSSpacingBigMargin, SSSpacingMargin, SSSpacingBigMargin));
        }];
    }
    
    return self;
}

#pragma mark - Class Methods

+ (CGSize)estimatedSizeHeaderInView:(UIView *)view withText:(NSString *)text
{
    CGFloat width = view.ss_width - (SSSpacingBigMargin * 2); // Mimic left and right margins
    CGFloat height = 0;
    
    // There might be a better way to automatically size a header but for now this is the world we live in.
    UIFontTextStyle headerTextStyle = [SSHeaderCollectionReusableView headerTextStyle];
    UIFont *headerFont = [UIFont preferredFontForTextStyle:headerTextStyle];
    
    height = [text boundingRectWithWidth:width
                                    text:text
                                    font:headerFont].size.height;
    height += SSSpacingMargin * 2; // Mimic top and bottom padding
    
    return CGSizeMake(width, height);
}

+ (UIFontTextStyle)headerTextStyle
{
    return UIFontTextStyleTitle3;
}

@end
