//
//  UIView+SSEmptyView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SSEmptyDataViewDataSource <NSObject>

- (UIView * _Nullable)viewForEmptyData;

@optional
- (CGFloat)offsetForEmptyView;
- (void (^ _Nonnull)(MASConstraintMaker * _Nonnull))constraintsBlockForEmptyView;

@end

@interface UIView (SSEmptyView) <UIGestureRecognizerDelegate>

@property (nonatomic, weak, nullable) id <SSEmptyDataViewDataSource> emptyDataViewDataSourceDelegate;
- (void)showEmptyViewIfNeeded;

@end
