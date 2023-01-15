//
//  BottomModalCardAnimator.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AnimationType) {
    AnimationTypePresent,
    AnimationTypeDismiss
};

@interface BottomModalCardAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) CGFloat fixedHeight;
@property (nonatomic) AnimationType animationType;

@end
