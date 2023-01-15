//
//  SSNavigationController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSNavigationController : UINavigationController

@property (nonatomic) BOOL preferBlackStatusBar;

- (instancetype _Nonnull)initForDynamicStlyingWithRootViewController:(UIViewController * _Nonnull)rootViewController;
- (void)setHairlineVisibility:(BOOL)setVisible;
- (void)styleNavigationBarAsPlainWhiteWithBoldText;
- (void)addTappableNavbarLabel:(UIViewController * _Nonnull)sender onTap:(void (^ _Nonnull)(void))onTap;
- (void)configureStyling;

@end
