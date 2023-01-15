//
//  UICollectionViewCell+Common.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/8/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "UICollectionViewCell+Common.h"

@implementation UICollectionViewCell (Common)

+ (CGFloat)preferredDividerHeight
{
    return [SSCitizenship accessibilityFontsEnabled] || [SSCitizenship prefersBoldText] ? 2.0 : (1.0/[UIScreen mainScreen].scale);
}

- (UIView *)ssSelectionView
{
    UIView *selectionView = [UIView new];
    selectionView.backgroundColor = [UIColor ssSelectedBackgroundColor];
    
    return selectionView;
}

- (UIImageView *)ssDisclosureImageView
{
    UIImageView *disclosureImage = [UIImageView new];
    disclosureImage.tintColor = [UIColor ssMutedColor];
    disclosureImage.clipsToBounds = YES;
    disclosureImage.contentMode = UIViewContentModeCenter;
    UIImage *disclosureIcon = [[UIImage systemImageNamed:@"chevron.right"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    disclosureImage.image = disclosureIcon;
    
    return disclosureImage;
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsForDividerView:(UIView * _Nonnull)dividerView
{
    CGFloat dividerHeight = [UICollectionViewCell preferredDividerHeight];
    return ^(MASConstraintMaker *make) {
        make.height.equalTo(@(dividerHeight));
        // Recreate the indented look
        make.left.equalTo(self.contentView.mas_leftMargin);
        make.right.equalTo(self.contentView.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.contentView.mas_bottom);
    };
}

- (void)animateHighlightCallout
{
    if (@available(iOS 14.0, *)) {
        if ([self isKindOfClass:[UICollectionViewListCell class]])
        {
            UICollectionViewListCell *listCell = (UICollectionViewListCell *)self;
            
            [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
                [listCell setHighlighted:YES];
            } completion:^(BOOL finished) {
                if (finished) {
                    [UIView animateWithDuration:0.75f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
                        [listCell setHighlighted:NO];
                    } completion:^(BOOL finished) {
                        
                    }];
                }
            }];
        }
    }
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsForFullWidthDividerView:(UIView *)dividerView
{
    CGFloat dividerHeight = [UICollectionViewCell preferredDividerHeight];
    return ^(MASConstraintMaker *make) {
        make.height.equalTo(@(dividerHeight));
        make.left.equalTo(self.contentView.mas_left);
        make.right.equalTo(self.contentView.mas_right);
        make.bottom.equalTo(self.contentView.mas_bottom);
    };
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsForReadableWidthDividerView:(UIView *)dividerView
{
    CGFloat dividerHeight = [UICollectionViewCell preferredDividerHeight];
    return ^(MASConstraintMaker *make) {
        make.height.equalTo(@(dividerHeight));
        make.left.equalTo(self.contentView.mas_readableContentGuideLeft);
        make.right.equalTo(self.contentView.mas_readableContentGuideRight);
        make.bottom.equalTo(self.contentView.mas_bottom);
    };
}

@end
