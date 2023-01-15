//
//  NSData+OrientationExifFix.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/30/18.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "NSData+OrientationExifFix.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSData (OrientationExifFix)

+ (NSData * _Nonnull)generateImageDataRespectingOrientation:(NSData * _Nonnull)imageData savedItemURL:(NSURL **)saveItemURL{
    NSString *mimeType = [self contentTypeFromImageData:imageData];
    if ([mimeType isEqualToString:@"image/gif"])
    {
        return imageData;
    }
    
    UIImage *imageFixedOrientation = [UIImage imageWithData:imageData];
    imageFixedOrientation = [imageFixedOrientation fixOrientation];
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    NSMutableDictionary *imageMetaData = [(__bridge NSMutableDictionary *)CGImageSourceCopyPropertiesAtIndex(source,0,NULL) mutableCopy];
    
    if(imageMetaData[@"Orientation"])
    {
        [imageMetaData removeObjectForKey:@"Orientation"];
    }
    
    if(imageMetaData[@"{TIFF}"] && [imageMetaData[@"{TIFF}"] isKindOfClass:[NSDictionary class]] && imageMetaData[@"{TIFF}"][@"Orientation"])
    {
        [imageMetaData[@"{TIFF}"] removeObjectForKey:@"Orientation"];
    }
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *docsURL = [[defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *outputURL = [docsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"imageOrientated%@.png", [NSUUID UUID]]];
    
    if([mimeType isEqualToString:@"image/jpeg"])
    {
        outputURL = [docsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"imageOrientated%@.png", [NSUUID UUID]]];
    }
    
    // Set compression quuality (0.0 to 1.0).
    NSMutableDictionary *mutableMetadata = [imageMetaData mutableCopy];
    [mutableMetadata setObject:@(1.0) forKey:(__bridge NSString *)kCGImageDestinationLossyCompressionQuality];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)outputURL, kUTTypeJPEG , 1, NULL);
    if (imageDestination == NULL )
    {
        // Handle failure.
        NSLog(@"Spend Stack - Failed to create image destination.");
        return imageData;
    }
    
    *saveItemURL = outputURL;
    
    // Add image to the destination.
    CGImageDestinationAddImage(imageDestination, imageFixedOrientation.CGImage, (__bridge CFDictionaryRef)mutableMetadata);
    
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO)
    {
        // Handle failure.
        NSLog(@"Spend Stack - Failed to finalize the image.");
    }
    
    CFRelease(imageDestination);
    
    NSData *proposedData = [NSData dataWithContentsOfURL:outputURL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputURL.path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputURL.path error:nil];
    }
    
    return proposedData ? proposedData : imageData;
}

+ (NSString *)contentTypeFromImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c)
    {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
            return nil;
            break;
        case 0x42:
            return @"image/bmp";
        case 0x4D:
            return @"image/tiff";
    }
    
    return nil;
}

@end
