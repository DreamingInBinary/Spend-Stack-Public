//
//  NSKeyedUnarchiver+SSUnarchiving.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "NSKeyedUnarchiver+SSUnarchiving.h"
#import <LinkPresentation/LinkPresentation.h>

@implementation NSKeyedUnarchiver (SSUnarchiving)

+ (__kindof SSObject *)ss_unarchiveSSClassFromData:(NSData *)data
{
    NSError *decodingError;
    NSArray <Class> *expectedTypes = [NSKeyedUnarchiver expectedClassesForSSObject];
    __kindof SSObject *obj = (SSObject *)[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:expectedTypes]
                                                                             fromData:data
                                                                                error:&decodingError];
    [NSKeyedUnarchiver commonAssert:decodingError debugData:@"Spend Stack object"];
    return obj;
}

+ (__kindof NSObject * _Nullable)ss_unarchiveClass:(Class _Nonnull)class fromData:(NSData * _Nonnull)data
{
    NSError *decodingError;
    __kindof NSObject *obj = (NSObject *)[NSKeyedUnarchiver unarchivedObjectOfClass:class fromData:data error:&decodingError];
   [NSKeyedUnarchiver commonAssert:decodingError debugData:NSStringFromClass(class)];
    return obj;
}

+ (__kindof NSObject * _Nullable)ss_unarchiveClassTypes:(NSArray <Class> * _Nonnull)classes fromData:(NSData * _Nonnull)data
{
    NSError *decodingError;
    __kindof NSObject *obj = (NSObject *)[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:classes] fromData:data error:&decodingError];
    [NSKeyedUnarchiver commonAssert:decodingError debugData:classes];
    return obj;
}

#pragma mark - Private Methods

+ (NSArray <Class> *)expectedClassesForSSObject
{
    return @[CKRecord.class,
             SSList.class,
             SSListItem.class,
             SSTag.class,
             SSTaxRateInfo.class,
             SSListDataSourceAdapter.class,
             SSListTag.class,
             NSDate.class,
             NSString.class,
             NSNumber.class,
             CKReference.class,
             CKAsset.class,
             NSDictionary.class,
             NSArray.class,
             NSMeasurement.class,
             NSData.class,
             LPLinkMetadata.class];
}

+ (void)commonAssert:(NSError *)decodingError debugData:(id)stringOrObj
{
    if (decodingError == nil) return;
    // If there's an error, ensure it's a null unarchive, those are fine.
    // Ensure, though, that it's not an unexpected class type because those return the same error codes :-/
    NSString *debugDescription = decodingError.userInfo[NSDebugDescriptionErrorKey];
    BOOL isUnexpectedClassError = NO;
    if (debugDescription)
    {
        isUnexpectedClassError = [debugDescription containsString:@"unexpected class"];
    }
    NSAssert(decodingError.code == 4864 && isUnexpectedClassError == NO, @"Spend Stack - Error decoding object types %@", stringOrObj);
}

@end
