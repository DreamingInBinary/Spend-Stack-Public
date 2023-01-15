//
//  NSKeyedArchiver+SSArchiving.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "NSKeyedArchiver+SSArchiving.h"

@implementation NSKeyedArchiver (SSArchiving)

+ (NSData *)ss_secureArchive:(NSObject *)obj
{
    NSError *e;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:YES error:&e];
    NSAssert(e == nil, @"Spend Stack - Error archiving data.");
    return data;
}

+ (NSData *)ss_archive:(NSObject *)obj
{
    NSError *e;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:&e];
    NSAssert(e == nil, @"Spend Stack - Error archiving data.");
    return data;
}

@end
