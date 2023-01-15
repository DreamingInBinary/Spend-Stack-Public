//
//  SSListTotalHeaderView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSListTotalHeaderView : UIView

@property (strong, nonatomic, nullable) SSList *list;

- (CGFloat)estimatedHeightForListTotalHeaderInView:(UIView * _Nullable)view;
- (void)updateUIForList:(SSList * _Nonnull)list;
- (void)updateSizeWithView:(UIView * _Nullable)view;

@end
