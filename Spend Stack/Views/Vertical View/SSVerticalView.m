//
//  SSVerticalView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSVerticalView.h"
#import "SSVerticalViewCell.h"

static inline UIColor *defaultSeparatorColor()
{
    return [UITableView new].separatorColor;
}

static inline UIEdgeInsets defaultSeparatorInset()
{
    return [UITableView new].separatorInset;
}

@interface SSVerticalView()

@property (strong, nonatomic, nonnull) UIStackView *stackView;

@end

@implementation SSVerticalView

#pragma mark - Custom Getters/Setters

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    for (SSVerticalViewCell *cell in self.stackView.arrangedSubviews)
    {
        cell.separatorColor = _separatorColor;
    }
}

- (void)setSeparatorHeight:(CGFloat)separatorHeight
{
    _separatorHeight = separatorHeight;
    
    for (SSVerticalViewCell *cell in self.stackView.arrangedSubviews)
    {
        cell.separatorHeight = _separatorHeight;
    }
}

- (void)setHidesSeparatorsByDefault:(BOOL)hidesSeparatorsByDefault
{
    _hidesSeparatorsByDefault = hidesSeparatorsByDefault;
    
    for (SSVerticalViewCell *cell in [self getAllRows])
    {
        [self updateSeparatorVisibilityForCell:cell];
    }
}

- (void)setAutomaticallyHidesLastSeparator:(BOOL)automaticallyHidesLastSeparator
{
    _automaticallyHidesLastSeparator = automaticallyHidesLastSeparator;
    SSVerticalViewCell *lastCell = self.stackView.arrangedSubviews.lastObject;
    if (lastCell) [self updateSeparatorVisibilityForCell:lastCell];
}

- (void)setDistributionStrategy:(UIStackViewDistribution)distributionStrategy
{
    _stackView.distribution = distributionStrategy;
}

#pragma mark - Initializers

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithSecondaryBackgroundColor
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    UIEdgeInsets defaultInsets = defaultSeparatorInset();
    self.rowBackgroundColor = [UIColor clearColor];
    self.rowInset = UIEdgeInsetsMake(SSTopBigElementMargin, defaultInsets.left, SSBottomBigElementMargin, defaultInsets.right);
    self.separatorColor = defaultSeparatorColor();
    self.separatorHeight = 1/[UIScreen mainScreen].scale;
    self.separatorInset = defaultInsets;
    self.hidesSeparatorsByDefault = NO;
    self.stackView = [UIStackView new];

    [self setUpViews];
    [self setUpConstraints];
}

#pragma mark - Public Methods

- (void)addRow:(UIView *)row animated:(BOOL)animated
{
    [self insertCellWithContentView:row
                            atIndex:self.stackView.arrangedSubviews.count
                           animated:animated];
}

- (void)addRows:(NSArray<UIView *> *)row animated:(BOOL)animated
{
    for (UIView *view in row)
    {
        [self addRow:view animated:animated];
    }
}

- (void)prependRow:(UIView *)row animated:(BOOL)animated
{
    [self insertCellWithContentView:row atIndex:0 animated:animated];
}

- (void)prependRows:(NSArray<UIView *> *)rows animated:(BOOL)animated
{
    for (UIView *view in [rows reverseObjectEnumerator])
    {
        [self prependRow:view animated:animated];
    }
}

- (void)insertRow:(UIView *)row before:(UIView *)beforeRow animated:(BOOL)animated
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)beforeRow.superview;
    NSInteger index = [self.stackView.arrangedSubviews indexOfObject:cell];
    
    if (cell == nil || isnan(index)) return;
    
    [self insertCellWithContentView:row atIndex:index animated:animated];
}

- (void)insertRows:(NSArray<UIView *> *)rows before:(UIView *)beforeRow animated:(BOOL)animated
{
    for (UIView *view in rows)
    {
        [self insertRow:view before:beforeRow animated:animated];
    }
}

- (void)insertRow:(UIView *)row after:(UIView *)afterRow animated:(BOOL)animated
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)afterRow.superview;
    NSInteger index = [self.stackView.arrangedSubviews indexOfObject:cell];
    
    if (cell == nil || isnan(index)) return;
    
    [self insertCellWithContentView:row atIndex:index+1 animated:animated];
}

- (void)insertRows:(NSArray<UIView *> *)rows after:(UIView *)afterRow animated:(BOOL)animated
{
    UIView *lastRow = afterRow;
    
    for (UIView *view in rows)
    {
        [self insertRow:view after:lastRow animated:animated];
        lastRow = view;
    }
}

- (void)removeRow:(UIView *)row animated:(BOOL)animated
{
    if ([row.superview isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    [self removeCell:(SSVerticalViewCell *)row.superview animated:animated];
}

- (void)removeRows:(NSArray<UIView *> *)rows animated:(BOOL)animated
{
    for (UIView *view in rows)
    {
        [self removeRow:view animated:animated];
    }
}

- (void)removeAllRows:(BOOL)animated
{
    for (UIView *view in self.stackView.arrangedSubviews)
    {
        if ([view isKindOfClass:[SSVerticalViewCell class]])
        {
            [self removeRow:((SSVerticalViewCell *)view).contentView animated:animated];
        }
    }
}

- (NSArray <SSVerticalViewCell *> *)getAllRows
{
    NSMutableArray <UIView *> *views = [NSMutableArray new];
    
    for (UIView *view in self.stackView.arrangedSubviews)
    {
        if ([view isKindOfClass:[SSVerticalViewCell class]])
        {
            [views addObject:view];
        }
    }
    
    return [views copy];
}

- (BOOL)containsRow:(UIView *)row
{
    if ([row.superview isKindOfClass:[SSVerticalViewCell class]])
    {
        return [self.stackView.arrangedSubviews containsObject:row];
    }
    
    return NO;
}

- (void)hideRow:(UIView *)row animated:(BOOL)animated
{
    [self setRowHidden:row isHidden:YES animated:animated];
}

- (void)hideRows:(NSArray<UIView *> *)rows animated:(BOOL)animated
{
    for (UIView *view in rows)
    {
        [self hideRow:view animated:animated];
    }
}

- (void)hideAllRows:(BOOL)animated
{
    NSMutableArray <UIView *> *contentViews = [NSMutableArray new];
    
    for (SSVerticalViewCell *cell in self.stackView.arrangedSubviews)
    {
        [contentViews addObject:cell.contentView];
    }
    
    [self setRowsHidden:contentViews isHidden:YES animated:animated];
}

- (void)showRow:(UIView *)row animated:(BOOL)animated
{
    [self setRowHidden:row isHidden:NO animated:animated];
}

- (void)showRows:(NSArray<UIView *> *)rows animated:(BOOL)animated
{
    for (UIView *view in rows)
    {
        [self showRow:view animated:animated];
    }
}

- (void)setRowHidden:(UIView *)row isHidden:(BOOL)isHidden animated:(BOOL)animated
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    
    if (animated)
    {
        [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
            cell.hidden = isHidden;
        } completion:^(BOOL finished) {
            if (finished) [self layoutIfNeeded];
        }];
    }
    else
    {
        cell.hidden = isHidden;
    }
}

- (void)setRowsHidden:(NSArray<UIView *> *)rows isHidden:(BOOL)isHidden animated:(BOOL)animated
{
    for (UIView *view in rows)
    {
        [self setRowHidden:view isHidden:isHidden animated:animated];
    }
}

- (BOOL)isRowHidden:(UIView *)row
{
    if ([row.superview isKindOfClass:[SSVerticalViewCell class]])
    {
        return row.superview.hidden;
    }
    
    return NO;
}

- (void)setTapHandlerForRow:(UIView *)row handler:(void (^)(UIView * _Nonnull))handler
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;

    row.userInteractionEnabled = YES;
    cell.tapHandler = handler;
}

- (void)setBackgroundColorForRow:(UIView *)row color:(UIColor *)color
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    cell.rowBackgroundColor = color;
}

- (void)setBackgroundColorForRows:(NSArray<UIView *> *)rows color:(UIColor *)color
{
    for (UIView *view in rows)
    {
        [self setBackgroundColorForRow:view color:color];
    }
}

- (void)setInsetForRow:(UIView *)row inset:(UIEdgeInsets)inset
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    cell.rowInset = inset;
}

- (void)setInsetForRows:(NSArray<UIView *> *)rows inset:(UIEdgeInsets)inset
{
    for (UIView *view in rows)
    {
        [self setInsetForRow:view inset:inset];
    }
}

- (void)setSeparatorInsetForRow:(UIView *)row inset:(UIEdgeInsets)inset
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    cell.separatorInset = inset;
}

- (void)setSeparatorInsetForRows:(NSArray<UIView *> *)rows inset:(UIEdgeInsets)inset
{
    for (UIView *view in rows)
    {
        [self setSeparatorInsetForRow:view inset:inset];
    }
}

- (void)hideSeparatorForRow:(UIView *)row
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    cell.shouldHideSeparator = YES;
    [self updateSeparatorVisibilityForCell:cell];
}

- (void)hideSeparatorForRows:(NSArray<UIView *> *)rows
{
    for (UIView *view in rows)
    {
        [self hideSeparatorForRow:view];
    }
}

- (void)showSeparatorForRow:(UIView *)row
{
    SSVerticalViewCell *cell = (SSVerticalViewCell *)row.superview;
    if ([cell isKindOfClass:[SSVerticalViewCell class]] == NO) return;
    cell.shouldHideSeparator = NO;
    [self updateSeparatorVisibilityForCell:cell];
}

- (void)showSeparatorForRows:(NSArray<UIView *> *)rows
{
    for (UIView *view in rows)
    {
        [self showSeparatorForRow:view];
    }
}

- (void)scrollRowToVisibleRow:(UIView *)row animated:(BOOL)animated
{
    if (row.superview != nil)
    {
        [self scrollRectToVisible:row.superview.frame animated:YES];
    }
}

- (SSVerticalViewCell *)cellForRow:(UIView *)row
{
    return [[SSVerticalViewCell alloc] initWithContentView:row];
}

- (void)configureCell:(SSVerticalViewCell *)cell
{
    // Meant to be overriden
}

#pragma mark - Private Methods

- (void)setUpViews
{
    [self setUpSelf];
    [self setUpStackView];
}

- (void)setUpSelf
{
    self.rowBackgroundColor = [UIColor systemBackgroundColor];
}

- (void)setUpStackView
{
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.axis = UILayoutConstraintAxisVertical;
    [self addSubview:self.stackView];
}

- (void)setUpConstraints
{
    [self setUpStackViewConstraints];
}

- (void)setUpStackViewConstraints
{
    [NSLayoutConstraint activateConstraints:@[[self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [self.stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              [self.stackView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                              [self.stackView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
                                              [self.stackView.widthAnchor constraintEqualToAnchor:self.widthAnchor]]];
}

- (SSVerticalViewCell *)createCellWithContentView:(UIView *)contentView
{
    SSVerticalViewCell *cell = [self cellForRow:contentView];
    
    cell.rowBackgroundColor = self.rowBackgroundColor;
    cell.rowInset = self.rowInset;
    cell.separatorColor = self.separatorColor;
    cell.separatorHeight = self.separatorHeight;
    cell.separatorInset = self.separatorInset;
    cell.shouldHideSeparator = self.hidesSeparatorsByDefault;
    
    [self configureCell:cell];
    
    return cell;
}

- (void)insertCellWithContentView:(UIView *)contentView atIndex:(NSInteger)index animated:(BOOL)animated
{
    UIView *cellToRemove = [self containsRow:contentView] ? contentView.superview : nil;
    SSVerticalViewCell *cell = [self createCellWithContentView:contentView];
    [self.stackView insertArrangedSubview:cell atIndex:index];
    
    if ([cellToRemove isKindOfClass:[SSVerticalViewCell class]])
    {
        [self removeCell:(SSVerticalViewCell *)cellToRemove animated:false];
    }
    
    [self updateSeparatorVisibilityForCell:cell];
    
    // A cell can affect the visibility of the cell before it, e.g. if
    // `automaticallyHidesLastSeparator` is true and a new cell is added as the last cell, so update
    // the previous cell's separator visibility as well.
    SSVerticalViewCell *cellAbove = [self cellAboveCell:cell];
    if (cellAbove) [self updateSeparatorVisibilityForCell:cellAbove];
    
    if (animated)
    {
        cell.hidden = YES;
        [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
            cell.hidden = NO;
        } completion:^(BOOL finished) {
            if (finished) [self layoutIfNeeded];
        }];
    }
}

- (void)removeCell:(SSVerticalViewCell *)cell animated:(BOOL)animated
{
    SSVerticalViewCell *aboveCell = [self cellAboveCell:cell];

    __weak typeof(self) weakSelf = self;
    void (^onCompletion)(BOOL completion) = ^(BOOL completion){
        [cell removeFromSuperview];
        
        if (aboveCell)
        {
            [weakSelf updateSeparatorVisibilityForCell:aboveCell];
        }
    };
    
    if (animated)
    {
        [UIView animateWithDuration:SSFastestAnimationDuration animations:^{
            cell.hidden = YES;
        } completion:onCompletion];
    }
    else
    {
        onCompletion(YES);
    }
}

- (void)updateSeparatorVisibilityForCell:(SSVerticalViewCell *)cell
{
    BOOL isLastCellAndHidingIsEnabled = self.automaticallyHidesLastSeparator && [cell isEqual:self.stackView.arrangedSubviews.lastObject];
    
    cell.isSeparatorHidden = isLastCellAndHidingIsEnabled || cell.shouldHideSeparator || self.hidesSeparatorsByDefault;
}

- (SSVerticalViewCell *)cellAboveCell:(SSVerticalViewCell *)cell
{
    NSInteger index = [self.stackView.arrangedSubviews indexOfObject:cell];
    
    if (index == 0) return nil;
    if (index == NSNotFound || self.stackView.arrangedSubviews.count == 0 || self.stackView.arrangedSubviews.count == 1) return nil;
    return (SSVerticalViewCell *)self.stackView.arrangedSubviews[index - 1];
}

@end
