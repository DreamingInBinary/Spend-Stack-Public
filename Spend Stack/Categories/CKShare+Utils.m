//
//  CKShare+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/29/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "CKShare+Utils.h"

@implementation CKShare (Utils)

- (BOOL)isSharedFromMe
{
    if (@available(iOS 12.0, *))
    {
        return self.currentUserParticipant.role == CKShareParticipantRoleOwner;
    }
    else
    {
        // Fallback on earlier versions
        return [self.recordID.zoneID.ownerName localizedCaseInsensitiveContainsString:@"defaultOwner"];
    }
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
