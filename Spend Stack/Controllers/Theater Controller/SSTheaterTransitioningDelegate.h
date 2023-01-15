//
//  SSTheaterTransitioningDelegate.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSTheaterAnimator;

@protocol SSTheaterImageViewProvidingDelegate <NSObject>

@optional
- (UIImageView * _Nonnull)ss_presentingControllerImageView;
- (UIImageView * _Nonnull)ss_presentedControllerImageView;
- (CGRect)ss_destinationRectForAnimatingImageView;
- (UIView * _Nonnull)ss_viewForDimissingAnimation;

@end

@interface SSTheaterTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

/// Interaction controller
///
/// If gesture triggers transition, it will set and will manage its own
/// `UIPercentDrivenInteractiveTransition`, but it must set this
/// reference to that interaction controller here, so that this
/// knows whether it's interactive or not.
@property (weak, nonatomic, readwrite, nullable) UIPercentDrivenInteractiveTransition *percentDriver;
@property (strong, nonatomic, readonly, nonnull) SSTheaterAnimator *animator;

@end
