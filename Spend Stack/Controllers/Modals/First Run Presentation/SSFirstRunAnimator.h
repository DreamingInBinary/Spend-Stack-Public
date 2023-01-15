//
//  SSFirstRunAnimator.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SSFirstRunAnimationType) {
    SSFirstRunAnimationTypePresent,
    SSFirstRunAnimationTypeDismiss
};

@interface SSFirstRunAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) SSFirstRunAnimationType animationType;

@end
