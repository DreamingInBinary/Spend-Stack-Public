//
//  UIView+SSUtils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIView+SSUtils.h"

#define SCREEN_SCALE                    ([[UIScreen mainScreen] scale])
#define PIXEL_INTEGRAL(pointValue)      (round(pointValue * SCREEN_SCALE) / SCREEN_SCALE)

@implementation UIView (SSUtils)

@dynamic ss_x, ss_y, ss_width, ss_height, ss_origin, ss_size;
@dynamic boundsWidth, boundsHeight, boundsX, boundsY;

- (void)addSubviews:(NSArray <UIView *> *)views
{
    for (UIView *view in views)
    {
        [self addSubview:view];
    }
}

- (void)removeSubviews
{
    if (self.subviews.count <= 0)
    {
        return;
    }
    
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
}

- (void)setSs_x:(CGFloat)x
{
    self.frame      = CGRectMake(PIXEL_INTEGRAL(x), self.ss_y, self.ss_width, self.ss_height);
}

- (void)setSs_y:(CGFloat)y
{
    self.frame      = CGRectMake(self.ss_x, PIXEL_INTEGRAL(y), self.ss_width, self.ss_height);
}

- (void)setSs_width:(CGFloat)width
{
    self.frame      = CGRectMake(self.ss_x, self.ss_y, PIXEL_INTEGRAL(width), self.ss_height);
}

- (void)setSs_height:(CGFloat)height
{
    self.frame      = CGRectMake(self.ss_x, self.ss_y, self.ss_width, PIXEL_INTEGRAL(height));
}

- (void)setSs_origin:(CGPoint)origin
{
    self.ss_x          = origin.x;
    self.ss_y          = origin.y;
}

- (void)setSs_size:(CGSize)size
{
    self.ss_width      = size.width;
    self.ss_height     = size.height;
}

- (void)setRight:(CGFloat)right
{
    self.ss_x          = right - self.ss_width;
}

- (void)setBottom:(CGFloat)bottom
{
    self.ss_y          = bottom - self.ss_height;
}

- (void)setLeft:(CGFloat)left
{
    self.ss_x          = left;
}

- (void)setTop:(CGFloat)top
{
    self.ss_y          = top;
}

- (void)setCenterX:(CGFloat)centerX
{
    self.center     = CGPointMake(PIXEL_INTEGRAL(centerX), self.center.y);
}

- (void)setCenterY:(CGFloat)centerY
{
    self.center     = CGPointMake(self.center.x, PIXEL_INTEGRAL(centerY));
}

- (void)setBoundsX:(CGFloat)boundsX
{
    self.bounds     = CGRectMake(PIXEL_INTEGRAL(boundsX), self.boundsY, self.boundsWidth, self.boundsHeight);
}

- (void)setBoundsY:(CGFloat)boundsY
{
    self.bounds     = CGRectMake(self.boundsX, PIXEL_INTEGRAL(boundsY), self.boundsWidth, self.boundsHeight);
}

- (void)setBoundsWidth:(CGFloat)boundsWidth
{
    self.bounds     = CGRectMake(self.boundsX, self.boundsY, PIXEL_INTEGRAL(boundsWidth), self.boundsHeight);
}

- (void)setBoundsHeight:(CGFloat)boundsHeight
{
    self.bounds     = CGRectMake(self.boundsX, self.boundsY, self.boundsWidth, PIXEL_INTEGRAL(boundsHeight));
}

// Getters
- (CGFloat)ss_x
{
    return self.frame.origin.x;
}

- (CGFloat)ss_y
{
    return self.frame.origin.y;
}

- (CGFloat)ss_width
{
    return self.frame.size.width;
}

- (CGFloat)ss_height
{
    return self.frame.size.height;
}

- (CGPoint)ss_origin
{
    return CGPointMake(self.ss_x, self.ss_y);
}

- (CGSize)ss_size
{
    return CGSizeMake(self.ss_width, self.ss_height);
}

- (CGFloat)right
{
    return self.frame.origin.x + self.frame.size.width;
}

- (CGFloat)bottom
{
    return self.frame.origin.y + self.frame.size.height;
}

- (CGFloat)left
{
    return self.ss_x;
}

- (CGFloat)top
{
    return self.ss_y;
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (UIView *)lastSubviewOnX
{
    if (self.subviews.count > 0)
    {
        UIView *outView = self.subviews[0];
        
        for(UIView *v in self.subviews)
            if(v.ss_x > outView.ss_x)
                outView = v;
        
        return outView;
    }
    
    return nil;
}

- (UIView *)lastSubviewOnY
{
    if (self.subviews.count > 0)
    {
        UIView *outView = self.subviews[0];
        
        for(UIView *v in self.subviews)
            if(v.ss_y > outView.ss_y)
                outView = v;
        
        return outView;
    }
    
    return nil;
}

- (CGFloat)boundsX
{
    return self.bounds.origin.x;
}

- (CGFloat)boundsY
{
    return self.bounds.origin.y;
}

- (CGFloat)boundsWidth
{
    return self.bounds.size.width;
}

- (CGFloat)boundsHeight
{
    return self.bounds.size.height;
}

- (BOOL)isLandscape
{
    return self.boundsWidth > self.boundsHeight;
}

- (void)centerToParent
{
    if(self.superview)
    {
        self.ss_origin = CGPointMake((self.superview.ss_width / 2.0) - (self.ss_width / 2.0), (self.superview.ss_height / 2.0) - (self.ss_height / 2.0));
    }
}

+ (void)applyStandardCornerMaskToView:(UIView *)view withRect:(CGRect)rect
{
    UIBezierPath *rounded = [UIBezierPath bezierPathWithRoundedRect:rect
                                                  byRoundingCorners:UIRectCornerAllCorners
                                                        cornerRadii:CGSizeMake(SSSpacingMargin, SSSpacingMargin)];
    CAShapeLayer *shape = [CAShapeLayer new];
    [shape setPath:rounded.CGPath];
    view.layer.mask = shape;
}

- (void)notchifyCornerRadius
{
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 40;
    self.layer.cornerCurve = kCACornerCurveContinuous;
}

- (NSArray *)allSubViews
{
    __block NSArray* allSubviews = [NSArray arrayWithObject:self];
    
    [self.subviews enumerateObjectsUsingBlock:^( UIView* view, NSUInteger idx, BOOL*stop) {
        allSubviews = [allSubviews arrayByAddingObjectsFromArray:[view allSubViews]];
    }];
    
    return allSubviews;
}

#pragma mark - Finding View Controller

- (UIViewController *)closestViewController
{
    return (UIViewController *)[self traverseResponderChainForUIViewController];
}

- (id)traverseResponderChainForUIViewController
{
    id nextResponder = [self nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
    {
        return nextResponder;
    }
    else if ([nextResponder isKindOfClass:[UIView class]])
    {
        return [nextResponder traverseResponderChainForUIViewController];
    }
    else
    {
        return nil;
    }
}

#pragma mark - NSLayoutAnchor Helpers

- (void)anchorToEdges:(UIView * _Nonnull)view
{
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];
}

- (void)anchorToEdges:(UIView * _Nonnull)view withTopLayoutGuide:(UILayoutGuide * _Nonnull)topGuide bottomLayoutGuide:(UILayoutGuide * _Nonnull)bottomGuide
{
    [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    [self.topAnchor constraintEqualToAnchor:topGuide.topAnchor].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:bottomGuide.bottomAnchor].active = YES;

}

- (void)anchorToEdgesWithoutLeadingTrailing:(UIView * _Nonnull)view
{
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];
}

- (void)removeAllConstraints
{
    UIView *superview = self.superview;
    while (superview != nil)
    {
        for (NSLayoutConstraint *c in superview.constraints)
        {
            if (c.firstItem == self || c.secondItem == self)
            {
                [superview removeConstraint:c];
            }
        }
        superview = superview.superview;
    }
    
    [self removeConstraints:self.constraints];
}

- (MASViewAttribute *)mas_readableContentGuideLeft
{
    return [[MASViewAttribute alloc] initWithView:self item:self.readableContentGuide layoutAttribute:NSLayoutAttributeLeft];
}

- (MASViewAttribute *)mas_readableContentGuideRight
{
    return[[MASViewAttribute alloc] initWithView:self item:self.readableContentGuide layoutAttribute:NSLayoutAttributeRight];
}

#pragma mark - Common Views

+ (NSNumber *)tagViewDotHeightWidth
{
    NSNumber *tagSize = [SSCitizenship accessibilityFontsEnabled] ?@(TAG_HEIGHT_WIDTH_ACCESSIBILITY) :@(TAG_HEIGHT_WIDTH_REGULAR);
    
    return tagSize;
}

#pragma mark - Cursor

- (void)addPointerInteractionWithDelegate:(id<UIPointerInteractionDelegate>)delly
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    
    UIPointerInteraction *pointerInteraction = [[UIPointerInteraction alloc] initWithDelegate:delly];
    [self addInteraction:pointerInteraction];
}

@end
