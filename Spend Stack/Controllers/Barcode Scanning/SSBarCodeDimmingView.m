//
//  SSBarCodeDimmingView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/9/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBarCodeDimmingView.h"
#import "SSConstants.h"

@implementation SSBarCodeDimmingView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeDestinationOut);
  
    CGRect cutoOutRect = self.shouldCloseCutOut ? CGRectZero : self.cutOutFrame;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:cutoOutRect cornerRadius:SSSpacingBigMargin];
    [path fill];
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

@end
