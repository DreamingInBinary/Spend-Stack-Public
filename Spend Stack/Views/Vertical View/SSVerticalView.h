//
//  SSVerticalView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSVerticalViewCell;

NS_ASSUME_NONNULL_BEGIN

@interface SSVerticalView : UIScrollView

@property (strong, nonatomic) UIColor *rowBackgroundColor;
@property (nonatomic) UIEdgeInsets rowInset;
@property (strong, nonatomic) UIColor *separatorColor;
@property (nonatomic) CGFloat separatorHeight;
@property (nonatomic) UIEdgeInsets separatorInset;
@property (nonatomic) BOOL hidesSeparatorsByDefault;
@property (nonatomic) BOOL automaticallyHidesLastSeparator;
@property (nonatomic) UIStackViewDistribution distributionStrategy;

- (instancetype)initWithSecondaryBackgroundColor;
- (void)addRow:(UIView *)row animated:(BOOL)animated;
- (void)addRows:(NSArray <UIView *> *)rows animated:(BOOL)animated;
- (void)prependRow:(UIView *)row animated:(BOOL)animated;
- (void)prependRows:(NSArray <UIView *> *)rows animated:(BOOL)animated;
- (void)insertRow:(UIView *)row before:(UIView *)beforeRow animated:(BOOL)animated;
- (void)insertRows:(NSArray <UIView *> *)rows before:(UIView *)beforeRow animated:(BOOL)animated;
- (void)insertRow:(UIView *)row after:(UIView *)afterRow animated:(BOOL)animated;
- (void)insertRows:(NSArray <UIView *> *)rows after:(UIView *)afterRow animated:(BOOL)animated;
- (void)removeRow:(UIView *)row animated:(BOOL)animated;
- (void)removeRows:(NSArray <UIView *> *)rows animated:(BOOL)animated;
- (void)removeAllRows:(BOOL)animated;
- (NSArray <SSVerticalViewCell *> *)getAllRows;
- (BOOL)containsRow:(UIView *)row;
- (void)hideRow:(UIView *)row animated:(BOOL)animated;
- (void)hideRows:(NSArray <UIView *> *)rows animated:(BOOL)animated;
- (void)hideAllRows:(BOOL)animated;
- (void)showRow:(UIView *)row animated:(BOOL)animated;
- (void)showRows:(NSArray <UIView *> *)rows animated:(BOOL)animated;
- (void)setRowHidden:(UIView *)row isHidden:(BOOL)isHidden animated:(BOOL)animated;
- (void)setRowsHidden:(NSArray <UIView *> *)rows isHidden:(BOOL)isHidden animated:(BOOL)animated;
- (BOOL)isRowHidden:(UIView *)row;
- (void)setTapHandlerForRow:(UIView *)row handler:(void (^)(UIView *))handler;
- (void)setBackgroundColorForRow:(UIView *)row color:(UIColor *)color;
- (void)setBackgroundColorForRows:(NSArray <UIView *> *)rows color:(UIColor *)color;
- (void)setInsetForRow:(UIView *)row inset:(UIEdgeInsets)inset;
- (void)setInsetForRows:(NSArray <UIView *> *)rows inset:(UIEdgeInsets)inset;
- (void)setSeparatorInsetForRow:(UIView *)row inset:(UIEdgeInsets)inset;
- (void)setSeparatorInsetForRows:(NSArray <UIView *> *)rows inset:(UIEdgeInsets)inset;
- (void)hideSeparatorForRow:(UIView *)row;
- (void)hideSeparatorForRows:(NSArray <UIView *> *)rows;
- (void)showSeparatorForRow:(UIView *)row;
- (void)showSeparatorForRows:(NSArray <UIView *> *)rows;
- (void)scrollRowToVisibleRow:(UIView *)row animated:(BOOL)animated;
- (SSVerticalViewCell *)cellForRow:(UIView *)row;
- (void)configureCell:(SSVerticalViewCell *)cell;

@end

NS_ASSUME_NONNULL_END
