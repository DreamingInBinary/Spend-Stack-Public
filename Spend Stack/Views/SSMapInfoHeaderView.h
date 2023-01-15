//
//  SSMapInfoHeaderView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 8/7/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSMapInfoHeaderView : UICollectionReusableView

- (void)setConstraints;
- (CGFloat)estimatedHeightForMapHeaderInView:(UIView * _Nullable)view;
- (void)updateSizeWithView:(UIView * _Nullable)view;
- (void)forceUpdateUI;
- (void)updateTaxRateForLocation;

@end
