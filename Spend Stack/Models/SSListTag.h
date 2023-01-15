//
//  SSListTag.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSListTag : SSObject <IGListDiffable, NSSecureCoding>

@property (strong, nonatomic, readonly, nonnull) NSString *fkListID;
@property (strong, nonatomic, readonly, nonnull) NSString *fkTagID;
@property (strong, nonatomic, nonnull) NSString *color;
@property (strong, nonatomic, nonnull) NSString *name;
@property (strong, nonatomic, nonnull) NSNumber *orderingIndex;
@property (strong, nonatomic, readonly, nonnull) CKReference *listReference;
@property (strong, nonatomic, readonly, nonnull) CKReference *listTagReference;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithParentListRecordID:(CKRecordID * _Nullable)parentListRecordID masterTag:(SSTag * _Nonnull)masterTag;
- (instancetype _Nonnull)initForMiscTag;

@end

NS_ASSUME_NONNULL_END
