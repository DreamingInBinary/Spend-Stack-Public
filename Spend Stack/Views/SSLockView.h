//
//  SSLockView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 7/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSLockView : UIView

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithContainingController:(__kindof UIViewController * _Nonnull)controller;

@property (copy) void (^ _Nullable onDismiss)(void); // Executes after a successful auth challenge

- (void)performAuthChallenge;

@end
