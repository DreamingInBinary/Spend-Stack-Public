//
//  SSImageDownloader.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSImageDownloader.h"
#import "SSImageCache.h"

@interface SSImageDownloader()

@property (strong, nonatomic, nonnull) SSImageCache *cache;

@end

@implementation SSImageDownloader

#pragma mark - Initializer

+ (instancetype)sharedInstance {
    static SSImageDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [SSImageDownloader new];
        sharedInstance.cache = [[SSImageCache alloc] initWithName:@"ss_image_cache"];
    });
    
    return sharedInstance;
}

#pragma mark - Image Retrieval

- (void)imageAtURL:(NSURL *)url completion:(void (^)(UIImage *image))completion
{
    // Check cache first
//    UIImage *img = [self.cache imageForKey:url.absoluteString];
//
//    if (img)
//    {
//        completion(img);
//        return;
//    }
    
    // Hit network
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (error)
            {
                completion(nil);
            }
            else
            {
                UIImage *img = [UIImage imageWithData:data];
                
                if (img)
                {
                    //[self.cache setImage:img forKey:url.absoluteString];
                    completion(img);
                }
                else
                {
                    completion(nil);
                }
            }
        });
    }] resume];
}

- (void)dataAtURL:(NSURL *)url completion:(void (^)(NSData *))completion
{
    // Check cache first
//    NSData *data = [self.cache dataForKey:url.absoluteString];
//
//    if (data)
//    {
//        completion(data);
//        return;
//    }
    
    // Hit network
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (error)
            {
                completion(nil);
            }
            else
            {
                //[self.cache setData:data forKey:url.absoluteString];
                completion(data);
            }
        });
    }] resume];
}

@end
