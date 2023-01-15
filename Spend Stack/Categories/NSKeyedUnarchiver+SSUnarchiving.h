//
//  NSKeyedUnarchiver+SSUnarchiving.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SSObject;

@interface NSKeyedUnarchiver (SSUnarchiving)

+ (__kindof SSObject * _Nullable)ss_unarchiveSSClassFromData:(NSData * _Nonnull)data;
+ (__kindof NSObject * _Nullable)ss_unarchiveClass:(Class _Nonnull)class fromData:(NSData * _Nonnull)data;
+ (__kindof NSObject * _Nullable)ss_unarchiveClassTypes:(NSArray <Class> * _Nonnull)classes fromData:(NSData * _Nonnull)data;

@end
