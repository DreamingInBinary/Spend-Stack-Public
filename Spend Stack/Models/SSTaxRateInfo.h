//
//  SSTaxRateInfo.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/31/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGListDiffKit.h"
#import "SSObject.h"
@class SSList;

@interface SSTaxRateInfo : SSObject <NSSecureCoding, NSCopying>

@property (strong, nonatomic, nonnull) NSString *fkListID;
@property (strong, nonatomic, nullable) NSDecimalNumber *taxRate;
@property (nonatomic, getter=taxIsEnabled) BOOL taxEnabled;
@property (strong, nonatomic, nullable) NSString *localSalesTaxLocation;
@property (strong, nonatomic, nullable) NSNumber *didManuallySet;
@property (nonatomic, getter=wasManuallySet, readonly) BOOL manuallySet;
@property (strong, nonatomic, readonly, nonnull) CKReference *reference;

- (instancetype _Nonnull)initWithExistingTaxInfo:(SSTaxRateInfo * _Nonnull)taxInfo withParentListRecordID:(CKRecordID * _Nonnull)parentListRecordID;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithParentListRecordID:(CKRecordID * _Nullable)parentListRecordID;
- (void)setTaxRateManuallySet:(BOOL)manuallySet;
- (void)resetReferenceForRedo:(SSList * _Nonnull)list;

@end
