//
//  SSApperanceProxy.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSAppearanceProxy.h"
#import <UIKit/UIKit.h>

@implementation SSAppearanceProxy

+ (void)setTintThemeForUIKitControls
{
    [[UITextField appearance] setTintColor:[UIColor ssPrimaryColor]];
    [[UITextView appearance] setTintColor:[UIColor ssPrimaryColor]];
    [[UISegmentedControl appearance] setTintColor:[UIColor ssPrimaryColor]];
}

@end
