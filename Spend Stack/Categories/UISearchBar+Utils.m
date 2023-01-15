//
//  UISearchBar+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/5/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "UISearchBar+Utils.h"

@implementation UISearchBar (Utils)

- (void)hideHairLine
{
    // HACK!!!: This could break in any iOS version so keep checking it.
    for (UIView *view in self.superview.subviews)
    {
        if ([view isKindOfClass:NSClassFromString(@"_UIBarBackground")])
        {
            view.hidden = YES;
        }
    }
}

@end
