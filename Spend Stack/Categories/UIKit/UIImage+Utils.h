//
//  UIImage+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

+ (UIImage * _Nonnull)downsampledImageFromData:(NSData * _Nonnull)data scale:(CGFloat)scale maxPixelSize:(CGFloat)maxPixelSize;
+ (UIImage * _Nonnull)imageFromColor:(UIColor * _Nonnull)color;
+ (CGRect)scaleImage:(UIImage * _Nonnull)image toView:(UIView * _Nonnull)view;
- (UIImage * _Nonnull)squareIconTemplateImageFromImage;
- (UIImage * _Nonnull)imageScaledToSize:(CGSize)newSize;
- (UIImage * _Nonnull)imageScaledToSize:(CGSize)newSize withInsets:(UIEdgeInsets)insets;
- (UIImage * _Nonnull)fixOrientation;
- (UIImage * _Nonnull)imageWithCornerRadius:(CGFloat)radius;

@end
