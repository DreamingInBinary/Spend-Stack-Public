//
//  SSCustomModelPresentationController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/7/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SSPopupModalPresentationController : UIPresentationController <UIViewControllerTransitioningDelegate>

// No dark blurring will occur if this is set to YES
@property (nonatomic, getter=shouldPreventDimming) BOOL preventDimming;

// If set to YES, the presenting controller will fade in and out with the presentation and dismissal
@property (nonatomic, getter=shouldAlphaFadePresentingController) BOOL alphaFadePresentingController;

+ (void)presentPresentationControllerFromController:(UIViewController * _Nonnull)presenting presentedController:(UIViewController * _Nonnull)presented;

@end
