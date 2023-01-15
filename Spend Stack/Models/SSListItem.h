//
//  SSListItem.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/15/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "IGListDiffKit.h"
#import <Foundation/Foundation.h>
@class PHAsset;
@class FMDatabase;
@class SSListTag;

typedef NS_ENUM(NSUInteger, ListItemRecurringPricingChoice) {
    ListItemRecurringPricingChoiceUnset,
    ListItemRecurringPricingChoiceDay,
    ListItemRecurringPricingChoiceWeek,
    ListItemRecurringPricingChoiceMonth,
    ListItemRecurringPricingChoiceYear
};

@interface SSListItem : SSObject <NSSecureCoding, NSCopying, IGListDiffable>

@property (strong, nonatomic, nonnull) NSString *fkListID;
@property (strong, nonatomic, nullable) NSString *fkTagID;
@property (strong, nonatomic, nonnull) NSString *title;
@property (nonatomic) BOOL checkedOff;
@property (strong, nonatomic, nonnull) NSNumber *orderingIndex;
@property (nonatomic) BOOL hasTaxApplied;
@property (strong, nonatomic, nonnull) NSDecimalNumber *baseAmount;
@property (strong, nonatomic, nullable) NSDecimalNumber *discountAmount;
@property (strong, nonatomic, nullable) NSDecimalNumber *discountPercentage;
@property (strong, nonatomic, nullable) NSMeasurement *weight;
@property (nonatomic) NSInteger quantity;
@property (strong, nonatomic, nonnull) NSString *notes;
@property (strong, nonatomic, readonly, nullable) CKAsset *mediaAttachment;
@property (nonatomic) ListItemRecurringPricingChoice recurringPricingCycle;
@property (strong, nonatomic, nonnull) NSNumber *recurringPricingFrequency;
@property (strong, nonatomic, nullable) NSString *linkAttachment;
@property (strong, nonatomic, nullable) NSDate *customDate;
@property (strong, nonatomic, nullable) NSString *cardImportName;
@property (strong, nonatomic, readonly, nullable) NSData *mediaAssetData; // Local Only
@property (weak, nonatomic, nullable) UIImage *downsampledMediaImage; // Local Only
@property (strong, nonatomic, readonly, nullable) LPLinkMetadata *linkMetadata; // Local only
@property (strong, nonatomic, nullable) NSNumber *proposedInsertionIndex; // Local Only, used for drag and dropping from list to list to ensure it goes to the index path it was dropped at.
@property (strong, nonatomic, readonly, nullable) SSListTag *tag;
@property (strong, nonatomic, readonly, nonnull) CKReference *reference;
@property (strong, nonatomic, readonly, nullable) CKReference *tagReference;
@property (copy) void (^ _Nullable onListTagSet)(SSListTag * _Nonnull tag);

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithParentListRecordID:(CKRecordID * _Nullable)parentListRecordID;
// This does *NOT* carry over tags or media. You need to do those manually.
- (instancetype _Nonnull)initWithExistingItem:(SSListItem * _Nonnull)listItem withParentListRecordID:(CKRecordID * _Nonnull)parentListRecordID;

- (SSListItem * _Nonnull)deepCopy;
- (void)addTag:(SSListTag * _Nonnull)listTag withList:(SSList * _Nonnull)list;
- (void)addListTag:(SSTag * _Nonnull)tag withList:(SSList * _Nonnull)list;
- (void)addListTag:(SSTag * _Nonnull)tag withList:(SSList * _Nonnull)list withDB:(FMDatabase * _Nonnull)db;
- (void)addSharedListTag:(SSListTag * _Nonnull)listTag withList:(SSList * _Nonnull)list;
- (SSListTag * _Nonnull)listTagFromMasterTagInDatabase:(FMDatabase * _Nonnull)db list:(SSList * _Nonnull)list tag:(SSTag * _Nonnull)tag;
- (void)deleteTag;
- (void)removeDiscounts;
- (void)removeWeightedPricing;

// For adding a new media asset to the item via a PHAsset
- (void)addMediaToItem:(PHAsset * _Nonnull)asset completion:(void (^ _Nonnull)(void))completion;
// For adding a new media asset to the item via raw NSData
- (void)attachNewMediaDataToInstanceWithData:(NSData * _Nonnull)data completion:(void (^ _Nonnull)(void))completion;
// Same as above, not async and can block main.ui
- (void)attachNewMediaDataToInstanceWithData:(NSData * _Nonnull)data;
// For updating the cache of an existing media asset to the item
- (void)attachMediaDataToInstanceWithData:(NSData * _Nonnull)data;
- (void)removeMediaFromItem;
// Assumes link was already validated.
- (void)attachLink:(NSString * _Nonnull)link metaData:(LPLinkMetadata * _Nonnull)metadata;
- (void)removeLinkFromItem;

- (void)resetReferenceForRedo:(SSList * _Nonnull)list;
+ (NSArray <SSListItem *> * _Nonnull)testItems;

@end
