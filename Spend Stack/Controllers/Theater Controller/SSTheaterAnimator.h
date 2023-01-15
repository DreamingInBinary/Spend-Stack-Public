//
//  SSTheaterAnimator.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AnimationType) {
    AnimationTypePresent,
    AnimationTypeDismiss
};

@interface SSTheaterAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) AnimationType animationType;
@property (weak, nonatomic, nullable) UIImageView *presentedControllerImageView;
@property (weak, nonatomic, nullable) UIImageView *presentingControllerImageView;
@property (nonatomic) CGRect destinationRectForAnimatingImageView;
@property (nonatomic) CGRect beginningRectForAnimatingImageView;
@property (weak, nonatomic, nullable) UIView *viewToDim;

@end
