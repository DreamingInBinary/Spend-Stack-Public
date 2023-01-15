//
//  SSImageCache.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSImageCache.h"

@interface SSImageCache()

@property (strong, nonatomic, nonnull) NSURL *location;

@end

@implementation SSImageCache

#pragma mark - Initializer

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        NSURL *cachesDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                                         inDomains:NSUserDomainMask] firstObject];
        
        self.location = [cachesDirectory URLByAppendingPathComponent:name];
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)setImage:(UIImage *)image forKey:(NSString *)key
{
    NSData *data = UIImageJPEGRepresentation(image, 0.9);
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:self.location.relativePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    
    NSURL *url = [self.location URLByAppendingPathComponent:[key stringByAppendingPathExtension:@"cache"]];
    
    [data writeToURL:url options:NSDataWritingAtomic error:&error];
    
    if (error)
    {
        NSLog(@"Spend Stack - Error writing image to cache: %@", error);
    }
}

- (void)setData:(NSData * _Nonnull)data forKey:(NSString * _Nonnull)key
{
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:self.location.relativePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    
    NSURL *url = [self.location URLByAppendingPathComponent:[key stringByAppendingPathExtension:@"cache"]];
    
    [data writeToURL:url options:NSDataWritingAtomic error:&error];
    
    if (error)
    {
        NSLog(@"Spend Stack - Error writing image data to cache: %@", error);
    }
}

- (UIImage *)imageForKey:(NSString *)key
{
    NSURL *url = [self.location URLByAppendingPathComponent:[key stringByAppendingPathExtension:@"cache"]];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
    
    if (imageData == nil) return nil;
    
    return [UIImage imageWithData:imageData];
}

- (NSData *)dataForKey:(NSString *)key
{
    NSURL *url = [self.location URLByAppendingPathComponent:[key stringByAppendingPathExtension:@"cache"]];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    
    if (data == nil) return nil;
    
    return data;
}

- (void)resetCache
{
    [[NSFileManager defaultManager] removeItemAtPath:self.location.relativePath error:nil];
}

@end
