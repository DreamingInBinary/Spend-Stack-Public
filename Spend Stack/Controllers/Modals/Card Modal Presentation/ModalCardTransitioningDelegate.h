//
//  ModalCardTransitioningDelegate.h
//  CardTransition
//
//  Created by Jordan Morgan on 10/17/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CardAnimator;
@class SSCardAnimatoriPhone;

@interface ModalCardTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

/// Interaction controller
///
/// If gesture triggers transition, it will set and will manage its own
/// `UIPercentDrivenInteractiveTransition`, but it must set this
/// reference to that interaction controller here, so that this
/// knows whether it's interactive or not.
@property (weak, nonatomic, readwrite, nullable) UIPercentDrivenInteractiveTransition *percentDriver;
@property (strong, nonatomic, readonly, nonnull) CardAnimator *animator;
@property (strong, nonatomic, readonly, nonnull) SSCardAnimatoriPhone *iPhoneAnimator;

@end
