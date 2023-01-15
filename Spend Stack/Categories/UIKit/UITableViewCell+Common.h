//
//  UITableViewCell+Common.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/1/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (Common)

+ (CGFloat)preferredDividerHeight;
- (UIView * _Nonnull)ssSelectionView;
- (UIImageView * _Nonnull)ssDisclosureImageView;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsForDividerView:(UIView * _Nonnull)dividerView;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsForFullWidthDividerView:(UIView * _Nonnull)dividerView;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsForReadableWidthDividerView:(UIView * _Nonnull)dividerView;
- (void)animateHighlightCallout;

@end

API_AVAILABLE(ios(13.4))
@interface UITableViewCell (UIPointerUtil) <UIPointerInteractionDelegate>

- (void)addShadowInteraction API_AVAILABLE(ios(13.4));

@end
