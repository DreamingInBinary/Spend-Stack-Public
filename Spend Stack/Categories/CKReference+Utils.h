//
//  CKReference+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/21/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <CloudKit/CloudKit.h>
@class SSCloudKitDatabase;

@interface CKReference (Utils)

- (BOOL)isSharedFromMe;
- (BOOL)isSharedWithMe;
- (CKDatabase * _Nonnull)databaseForMe;
- (SSCloudKitDatabase * _Nonnull)ssDatabaseForMe;

@end
