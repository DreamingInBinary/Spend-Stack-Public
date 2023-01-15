//
//  UITextField+NegativeInput.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/28/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "UITextField+NegativeInput.h"
#import <objc/runtime.h>

@implementation UITextField (NegativeInput)

#pragma mark - Getters/Setters

static char const * SSNegativeTogglePropertyKey = "SSNegativeTogglePropertyKey";

- (BOOL)enteringNegativeNumber
{
    NSNumber *num = objc_getAssociatedObject(self, SSNegativeTogglePropertyKey);
    return num.boolValue ?: NO;
}

- (void)setEnteringNegativeNumber:(BOOL)enteringNegativeNumber
{
    objc_setAssociatedObject(self, SSNegativeTogglePropertyKey, @(enteringNegativeNumber), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self toggleTextForNegativeInputChange];
}

#pragma mark - Public Methods

- (void)toggleTextForNegativeInputChange
{
    if ([self.text hasPrefix:@"-"])
    {
        if (self.enteringNegativeNumber) return; // Already there
        self.text = [self.text stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
    else if (self.enteringNegativeNumber)
    {
        self.text = [NSString stringWithFormat:@"-%@", self.text];
    }
}

- (void)prefixNegativeSignToText
{
    if ([self.text hasPrefix:@"-"]) return;
    self.text = [NSString stringWithFormat:@"-%@", self.text];
}


@end
