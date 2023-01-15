//
//  BottomModalCardTransitioningDelegate.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/26/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BottomModalCardAnimator.h"

@interface BottomModalCardTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) BottomModalCardAnimator *animator;

@end
