//
//  UIImage+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "UIImage+Utils.h"

@implementation UIImage (Utils)

#pragma mark - Class Methods

+ (UIImage *)downsampledImageFromData:(NSData *)data scale:(CGFloat)scale maxPixelSize:(CGFloat)maxPixelSize
{
    // Downsample
    NSMutableDictionary *imageSourceOptions = [NSMutableDictionary new];
    [imageSourceOptions setObject:@(NO) forKey:(__bridge NSString *)kCGImageSourceShouldCache];
    
    CGImageSourceRef imageRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)imageSourceOptions);
    
    NSMutableDictionary *downSampleOptions = [NSMutableDictionary new];
    [downSampleOptions setObject:@(YES) forKey:(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways];
    [downSampleOptions setObject:@(YES) forKey:(__bridge NSString *)kCGImageSourceShouldCacheImmediately];
    [downSampleOptions setObject:@(YES) forKey:(__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform];
    [downSampleOptions setObject:@(maxPixelSize) forKey:(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize];
    
    CGImageRef downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageRef, 0, (__bridge CFDictionaryRef)downSampleOptions);
    
    return [UIImage imageWithCGImage:downSampledImage];
}

+ (UIImage *)imageFromColor:(UIColor *)color
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        CGContextSetFillColorWithColor(rendererContext.CGContext, [color CGColor]);
        CGContextFillRect(rendererContext.CGContext, rendererContext.format.bounds);
    }];
}

+ (CGRect)scaleImage:(UIImage *)image toView:(UIView *)view
{
    //Set the aspect ratio of the image
    float hfactor = image.size.width / view.bounds.size.width;
    float vfactor = image.size.height / view.bounds.size.height;
    float factor = fmax(hfactor, vfactor);
    
    //Divide the size by the greater of the vertical or horizontal shrinkage factor
    float newWidth = image.size.width / factor;
    float newHeight = image.size.height / factor;
    
    //Then figure out offset to center vertically or horizontally
    float leftOffset = (view.bounds.size.width - newWidth) / 2;
    float topOffset = (view.bounds.size.height - newHeight) / 2;
    
    //Reposition image view
    CGRect newRect = CGRectMake(leftOffset, topOffset, newWidth, newHeight);
    
    //Check for any NaNs, which should get corrected in the next drawing cycle
    BOOL isInvalidRect = (isnan(leftOffset) || isnan(topOffset) || isnan(newWidth) || isnan(newHeight));
    return isInvalidRect ? CGRectZero : newRect;
}

#pragma mark - Instance Methods

- (UIImage *)squareIconTemplateImageFromImage
{
    return [[self imageScaledToSize:CGSizeMake(20, 20)]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)imageScaledToSize:(CGSize)newSize
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(newSize.width, newSize.height)];
    
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }];
}

- (UIImage *)imageScaledToSize:(CGSize)newSize withInsets:(UIEdgeInsets)insets
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(newSize.width, newSize.height)];
    
    UIImage *img = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }];
    
    return [img imageWithAlignmentRectInsets:insets];
}

- (UIImage *)fixOrientation
{
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (UIImage *)imageWithCornerRadius:(CGFloat)radius
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(self.size.width, self.size.height)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        CALayer *imageLayer = [CALayer layer];
        imageLayer.frame = CGRectMake(0, 0, self.size.width, self.size.height);
        imageLayer.contents = (id)self.CGImage;
        
        imageLayer.masksToBounds = YES;
        imageLayer.cornerRadius = radius;
        [imageLayer renderInContext:rendererContext.CGContext];
    }];
}

@end
