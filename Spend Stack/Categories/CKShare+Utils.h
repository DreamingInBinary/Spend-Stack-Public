//
//  CKShare+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/29/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <CloudKit/CloudKit.h>

@interface CKShare (Utils)

- (BOOL)isSharedFromMe;
- (BOOL)isSharedWithMe;
- (CKDatabase * _Nonnull)databaseForMe;
- (SSCloudKitDatabase * _Nonnull)ssDatabaseForMe;

@end
