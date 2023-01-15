//
//  UITraitCollection+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITraitCollection (Utils)

- (BOOL)isInRegularTraitCollection;
- (BOOL)isDifferentThanTraitCollection:(UITraitCollection * _Nullable)otherTraitCollection;

@end
