//
//  UITraitCollection+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "UITraitCollection+Utils.h"

@implementation UITraitCollection (Utils)

- (BOOL)isInRegularTraitCollection
{
    return self.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
           self.verticalSizeClass == UIUserInterfaceSizeClassRegular;
}

- (BOOL)isDifferentThanTraitCollection:(UITraitCollection *)otherTraitCollection
{
    return ((self.verticalSizeClass != otherTraitCollection.verticalSizeClass) ||
            (self.horizontalSizeClass != otherTraitCollection.horizontalSizeClass));
}

@end
