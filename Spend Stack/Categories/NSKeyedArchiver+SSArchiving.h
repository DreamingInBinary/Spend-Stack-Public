//
//  NSKeyedArchiver+SSArchiving.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSKeyedArchiver (SSArchiving)

+ (NSData * _Nullable)ss_secureArchive:(NSObject * _Nonnull)obj;
+ (NSData * _Nullable)ss_archive:(NSObject * _Nonnull)obj;

@end

