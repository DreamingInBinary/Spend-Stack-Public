//
//  UIView+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"

@interface UIView (SSUtils)

/**
 *  Adds the collection of views to the view hierarchy of the view instance.
 *
 *  @param views The views to be added as a subview to this view.
 */
- (void)addSubviews:(NSArray <UIView *> * _Nonnull)views;

/**
 *  Removes all of the receiver's subviews.
 */
- (void)removeSubviews;

/** View's X Position */
@property (nonatomic, assign) CGFloat   ss_x;

/** View's Y Position */
@property (nonatomic, assign) CGFloat   ss_y;

/** View's width */
@property (nonatomic, assign) CGFloat   ss_width;

/** View's height */
@property (nonatomic, assign) CGFloat   ss_height;

/** View's origin - Sets X and Y Positions */
@property (nonatomic, assign) CGPoint   ss_origin;

/** View's size - Sets Width and Height */
@property (nonatomic, assign) CGSize    ss_size;

/** Y value representing the bottom of the view **/
@property (nonatomic, assign) CGFloat   bottom;

/** X Value representing the right side of the view **/
@property (nonatomic, assign) CGFloat   right;

/** X Value representing the top of the view (alias of x) **/
@property (nonatomic, assign) CGFloat   left;

/** Y Value representing the top of the view (alias of y) **/
@property (nonatomic, assign) CGFloat   top;

/** X value of the object's center **/
@property (nonatomic, assign) CGFloat   centerX;

/** Y value of the object's center **/
@property (nonatomic, assign) CGFloat   centerY;

/** Returns the Subview with the highest X value **/
@property (nonatomic, strong, readonly) UIView *_Nullable lastSubviewOnX;

/** Returns the Subview with the highest Y value **/
@property (nonatomic, strong, readonly) UIView *_Nullable lastSubviewOnY;

/** View's bounds X value **/
@property (nonatomic, assign) CGFloat   boundsX;

/** View's bounds Y value **/
@property (nonatomic, assign) CGFloat   boundsY;

/** View's bounds width **/
@property (nonatomic, assign) CGFloat   boundsWidth;

/** View's bounds height **/
@property (nonatomic, assign) CGFloat   boundsHeight;

/** Returns YES if the view's bound width is greater than its height **/
@property (nonatomic, readonly) BOOL   isLandscape;

/**
 Centers the view to its parent view (if exists)
 */
-(void) centerToParent;

/**
 Puts a mask in all fours corners of the view set to SSSpacingMargin
 */
+ (void)applyStandardCornerMaskToView:(UIView * _Nonnull)view withRect:(CGRect)rect;

/**
 Puts a mask in all fours corners of the view set notched edges.
 */
- (void)notchifyCornerRadius;

/**
 Recursively traverses the entire view hierarchy of the receiver.
 */
- (NSArray * _Nonnull)allSubViews;

#pragma mark - Finding View Controller

- (UIViewController * _Nullable)closestViewController;

#pragma mark - NSLayoutAnchor & Auto Layout Helpers

- (void)anchorToEdges:(UIView * _Nonnull)view;
- (void)anchorToEdges:(UIView * _Nonnull)view withTopLayoutGuide:(UILayoutGuide * _Nonnull)topGuide bottomLayoutGuide:(UILayoutGuide * _Nonnull)bottomGuide;
- (void)anchorToEdgesWithoutLeadingTrailing:(UIView * _Nonnull)view;
- (void)removeAllConstraints;
- (MASViewAttribute * _Nonnull)mas_readableContentGuideLeft;
- (MASViewAttribute * _Nonnull)mas_readableContentGuideRight;

#pragma mark - Common Views

+ (NSNumber * _Nonnull)tagViewDotHeightWidth;

#pragma mark - Cursor

- (void)addPointerInteractionWithDelegate:(id<UIPointerInteractionDelegate> _Nonnull)delly API_AVAILABLE(ios(13.4));

@end
