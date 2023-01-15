//
//  UICollectionViewCell+Common.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/8/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionViewCell (Common)

+ (CGFloat)preferredDividerHeight;
- (UIView * _Nonnull)ssSelectionView;
- (UIImageView * _Nonnull)ssDisclosureImageView;
- (void)animateHighlightCallout;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsForDividerView:(UIView * _Nonnull)dividerView;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsForFullWidthDividerView:(UIView * _Nonnull)dividerView;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsForReadableWidthDividerView:(UIView * _Nonnull)dividerView;

@end
