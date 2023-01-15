//
//  SSVerticalViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSVerticalViewCell.h"
#import "SSVerticalSeparatorView.h"

@interface SSVerticalViewCell()

@property (strong, nonatomic, nonnull) SSVerticalSeparatorView *separatorView;
@property (strong, nonatomic, nonnull) UITapGestureRecognizer *tapGestureRecognizer;
@property (strong, nonatomic, nullable) NSLayoutConstraint *topConstraint;
@property (strong, nonatomic, nullable) NSLayoutConstraint *leftConstraint;
@property (strong, nonatomic, nullable) NSLayoutConstraint *rightConstraint;
@property (strong, nonatomic, nullable) NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic, nullable) NSLayoutConstraint *separatorLeadingConstraint;
@property (strong, nonatomic, nullable) NSLayoutConstraint *separatorTrailingConstraint;

@end

@implementation SSVerticalViewCell

@synthesize rowInset = _rowInset;

#pragma mark - Custom Getter/Setters

- (void)setRowBackgroundColor:(UIColor *)rowBackgroundColor
{
    _rowBackgroundColor = rowBackgroundColor;
    self.backgroundColor = _rowBackgroundColor;
}

- (UIEdgeInsets)rowInset
{
    return self.layoutMargins;
}

- (void)setRowInset:(UIEdgeInsets)rowInset
{
    _rowInset = rowInset;
    self.layoutMargins = _rowInset;
    
    self.topConstraint.constant = self.layoutMargins.top;
    self.leftConstraint.constant = self.layoutMargins.left;
    self.bottomConstraint.constant = self.layoutMargins.bottom;
    self.rightConstraint.constant = self.layoutMargins.right;
}

- (UIColor *)separatorColor
{
    return self.separatorView.color;
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    self.separatorView.color = separatorColor;
}

- (CGFloat)separatorHeight
{
    return self.separatorView.height;
}

- (void)setSeparatorHeight:(CGFloat)separatorHeight
{
    self.separatorView.height = separatorHeight;
}

- (void)setSeparatorInset:(UIEdgeInsets)separatorInset
{
    _separatorInset = separatorInset;
    [self updateSeparatorInset];
}

- (BOOL)isSeparatorHidden
{
    return self.separatorView.isHidden;
}

- (void)setIsSeparatorHidden:(BOOL)isSeparatorHidden
{
    self.separatorView.hidden = isSeparatorHidden;
}

- (void)setTapHandler:(void (^)(UIView *view))tapHandler
{
    _tapHandler = tapHandler;
}

#pragma mark - Initializers

- (instancetype)initWithContentView:(UIView *)contentView
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.contentView = contentView;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.insetsLayoutMarginsFromSafeArea = NO;
        self.separatorView = [SSVerticalSeparatorView new];
        self.tapGestureRecognizer = [UITapGestureRecognizer new];
        
        [self setUpViews];
        [self setUpConstraints];
        [self setUpTapGestureRecognizer];
    }
    
    return self;
}

#pragma mark - UI Responder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (self.contentView.isUserInteractionEnabled == NO) return;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (self.contentView.isUserInteractionEnabled == NO) return;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (self.contentView.isUserInteractionEnabled == NO) return;
}

#pragma mark - Private Methods

- (void)setUpViews
{
    [self setUpSelf];
    [self setUpContentView];
    [self setUpSeparatorView];
}

- (void)setUpSelf
{
    self.clipsToBounds = YES;
}

- (void)setUpContentView
{
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.contentView];
}

- (void)setUpSeparatorView
{
    [self addSubview:self.separatorView];
}

- (void)setUpConstraints
{
    [self setUpContentViewConstraints];
    [self setUpSeparatorViewConstraints];
}

- (void)setUpContentViewConstraints
{
    self.topConstraint = [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor];
    self.leftConstraint = [self.contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    self.bottomConstraint = [self.contentView.bottomAnchor constraintEqualToAnchor:self.separatorView.topAnchor];
    self.rightConstraint = [self.contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
    
    [NSLayoutConstraint activateConstraints:@[self.topConstraint,
                                              self.leftConstraint,
                                              self.bottomConstraint,
                                              self.rightConstraint]];
}

- (void)setUpSeparatorViewConstraints
{
    NSLayoutConstraint *leadingConstraint = [self.separatorView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [self.separatorView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
    
    [NSLayoutConstraint activateConstraints:@[[self.separatorView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              leadingConstraint,
                                              trailingConstraint]];
    
    self.separatorLeadingConstraint = leadingConstraint;
    self.separatorTrailingConstraint = trailingConstraint;
}

- (void)setUpTapGestureRecognizer
{
    [self.tapGestureRecognizer addTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.contentView.isUserInteractionEnabled == NO || !self.tapHandler) return;
    self.tapHandler(self.contentView);
}

- (void)updateSeparatorInset
{
    self.separatorLeadingConstraint.constant = self.separatorInset.left;
    self.separatorTrailingConstraint.constant = self.separatorInset.right;
}

@end
