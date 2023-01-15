//
//  SSCardAnimatoriPhone.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, iPhoneAnimationType) {
    iPhoneAnimationTypePresent,
    iPhoneAnimationTypeDismiss
};

@interface SSCardAnimatoriPhone : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) iPhoneAnimationType animationType;

- (void)setPresentedViewFrame:(UIViewController * _Nonnull)presentedController containerView:(UIView * _Nonnull)containerView;

@end
