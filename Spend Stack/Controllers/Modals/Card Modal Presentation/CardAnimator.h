//
//  CardAnimator.h
//  CardTransition
//
//  Created by Jordan Morgan on 10/13/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AnimationType) {
    AnimationTypePresent,
    AnimationTypeDismiss
};

@interface CardAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) AnimationType animationType;

- (void)setPresentedViewForSmallerTraitSize:(UIViewController * _Nonnull)presentedController containerView:(UIView * _Nonnull)containerView;
- (void)setPresentedViewForRegularTraitSize:(UIViewController * _Nonnull)presentedController containerView:(UIView * _Nonnull)containerView;

@end
