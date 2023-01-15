//
//  UIAlertController+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "UIAlertController+Utils.h"

@implementation UIAlertController (Utils)

- (void)addActions:(NSArray<UIAlertAction *> *)actions
{
    for (UIAlertAction *action in actions)
    {
        if ([action isKindOfClass:[UIAlertAction class]])
        {
            [self addAction:action];
        }
    }
}

@end
