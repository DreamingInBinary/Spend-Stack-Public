//
//  CKRecordZoneID+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <CloudKit/CloudKit.h>

@interface CKRecordZoneID (Utils)

- (BOOL)isSharedFromMe;
- (BOOL)isSharedWithMe;

@end
