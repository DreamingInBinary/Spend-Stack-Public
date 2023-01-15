//
//  SSImageCache.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSImageCache : NSObject
// NOTE: The image cache is busted. It doesn't save properly, so I use it I need to debug this.
+ (instancetype _Nullable)new NS_UNAVAILABLE;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nullable)initWithName:(NSString * _Nonnull)name NS_DESIGNATED_INITIALIZER;
- (void)setImage:(UIImage * _Nonnull)image forKey:(NSString * _Nonnull)key;
- (void)setData:(NSData * _Nonnull)data forKey:(NSString * _Nonnull)key;
- (UIImage * _Nullable)imageForKey:(NSString * _Nonnull)key;
- (NSData * _Nullable)dataForKey:(NSString * _Nonnull)key;
- (void)resetCache;

@end
