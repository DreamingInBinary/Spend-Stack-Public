//
//  NSData+OrientationExifFix.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/30/18.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (OrientationExifFix)

+ (NSData * _Nonnull)generateImageDataRespectingOrientation:(NSData * _Nonnull)imageData savedItemURL:(NSURL * _Nonnull * _Nullable)saveItemURL;
+ (NSString * _Nullable)contentTypeFromImageData:(NSData * _Nonnull)data;

@end
