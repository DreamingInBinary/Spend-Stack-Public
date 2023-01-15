//
//  SSEmptyStateView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSEmptyStateView : UIView

- (instancetype _Nonnull)initWithStateText:(NSString * _Nonnull)text;
- (instancetype _Nonnull)initWithStateText:(NSString * _Nonnull)text performAnimaton:(BOOL)animate;
- (instancetype _Nonnull)initWithStateText:(NSString * _Nonnull)text buttonText:(NSString * _Nonnull)buttonText handler:(void (^ _Nonnull)(void))handler;
- (void)performAnimation;

@end
