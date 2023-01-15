//
//  CKRecordZoneID+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "CKRecordZoneID+Utils.h"

@implementation CKRecordZoneID (Utils)

- (BOOL)isSharedFromMe;
{
    return [self.ownerName localizedCaseInsensitiveContainsString:@"defaultOwner"];
}

- (BOOL)isSharedWithMe
{
    return self.isSharedFromMe == NO;
}

@end
