//
//  SSImageDownloader.h
//  Spend Stack
//
//  Created by Jordan Morgan on 11/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSImageDownloader : NSObject

+ (instancetype _Nonnull)sharedInstance;

- (void)imageAtURL:(NSURL * _Nonnull)url completion:(void (^ _Nonnull)(UIImage * _Nullable image))completion;
- (void)dataAtURL:(NSURL * _Nonnull)url completion:(void (^ _Nonnull)(NSData * _Nullable data))completion;

@end
