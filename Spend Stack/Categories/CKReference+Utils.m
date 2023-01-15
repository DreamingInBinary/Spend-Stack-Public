//
//  CKReference+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/21/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "CKReference+Utils.h"
#import <Foundation/Foundation.h>

@implementation CKReference (Utils)

- (BOOL)isSharedFromMe
{
    return [self.recordID.zoneID.ownerName localizedCaseInsensitiveContainsString:@"defaultOwner"];
}

- (BOOL)isSharedWithMe
{
    return [self isSharedFromMe] == NO;
}

- (CKDatabase *)databaseForMe
{
    if ([self isSharedFromMe])
    {
        return [CKContainer defaultContainer].privateCloudDatabase;
    }
    else
    {
        return [CKContainer defaultContainer].sharedCloudDatabase;
    }
}

- (SSCloudKitDatabase *)ssDatabaseForMe
{
    if ([self isSharedFromMe])
    {
        return [SSDataStore sharedInstance].ckManager.privateDB;
    }
    else
    {
        return [SSDataStore sharedInstance].ckManager.sharedDB;
    }
}

@end
