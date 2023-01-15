//
//  FMDatabase+SSCRUD.h
//  Spend Stack
//
//  Created by Jordan Morgan on 12/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "FMDatabase.h"
@class SSObject;

@interface FMDatabase (SSCRUD)

// Lists

- (BOOL)insertListIntoDB:(SSList * _Nonnull)list;
- (BOOL)insertListIntoDBWithRecord:(CKRecord * _Nonnull)listRecord;
- (BOOL)updateListInDB:(SSList * _Nonnull)list;
- (BOOL)updateListInDBWithRecord:(CKRecord * _Nonnull)listRecord;
- (BOOL)updateListRecord:(CKRecord * _Nonnull)listRecord;
- (BOOL)deleteListInDB:(SSList * _Nonnull)list;
- (BOOL)deleteListsInDB:(NSArray <NSString *> * _Nonnull)listIDs;
- (BOOL)listExistsForID:(NSString * _Nonnull)dbID;

// Tax Info

- (BOOL)insertTaxRateInfoIntoDB:(SSTaxRateInfo * _Nonnull)taxRateInfo;
- (BOOL)insertTaxRateInfoIntoDBWithRecord:(CKRecord * _Nonnull)taxRateInfoRecord;
- (BOOL)updateTaxRateInfoInDB:(SSTaxRateInfo * _Nonnull)taxRateInfo;
- (BOOL)updateTaxRateInfoInDBWithRecord:(CKRecord * _Nonnull)taxRateInfoRecord;
- (BOOL)updateTaxRateInfoRecord:(CKRecord * _Nonnull)taxRateInfoRecord;
- (BOOL)deleteTaxRateInfoInDB:(SSTaxRateInfo * _Nonnull)taxRateInfo;
- (BOOL)deleteTaxRatesInDB:(NSArray <NSString *> * _Nonnull)taxRateIDs;
- (BOOL)taxRateExistsForID:(NSString * _Nonnull)dbID;

// Tags

- (BOOL)insertTagIntoDB:(SSTag * _Nonnull)tag;
- (BOOL)insertTagIntoDBWithRecord:(CKRecord * _Nonnull)tagRecord;
- (BOOL)updateTagInDB:(SSTag * _Nonnull)taxRateInfo;
- (BOOL)updateTagInDBWithRecord:(CKRecord * _Nonnull)tagRecord;
- (BOOL)updateTagRecord:(CKRecord * _Nonnull)tagRecord;
- (BOOL)deleteTagInDB:(SSTag * _Nonnull)taxRateInfo;
- (BOOL)deleteTagsInDB:(NSArray <NSString *> * _Nonnull)tagIDs;
- (BOOL)tagExistsForID:(NSString * _Nonnull)dbID;

// List Tags

- (BOOL)insertListTagIntoDB:(SSListTag * _Nonnull)tag;
- (BOOL)insertListTagIntoDBWithRecord:(CKRecord * _Nonnull)tagRecord;
- (BOOL)updateListTagInDB:(SSListTag * _Nonnull)taxRateInfo;
- (BOOL)updateListTagInDBWithRecord:(CKRecord * _Nonnull)tagRecord;
- (BOOL)updateListTagRecord:(CKRecord * _Nonnull)tagRecord;
- (BOOL)deleteListTagInDB:(SSListTag * _Nonnull)taxRateInfo;
- (BOOL)deleteListTagsInDB:(NSArray <NSString *> * _Nonnull)tagIDs;
- (BOOL)listTagExistsForID:(NSString * _Nonnull)dbID;
- (BOOL)listTagExistsForListID:(NSString * _Nonnull)listDBID masterTag:(SSTag * _Nonnull)masterTag;

// List Items

- (BOOL)insertListItemIntoDB:(SSListItem * _Nonnull)listItem taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (BOOL)insertListItemIntoDBWithRecord:(CKRecord * _Nonnull)listItemRecord;
- (BOOL)updateListItemInDB:(SSListItem * _Nonnull)listItem taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (BOOL)updateListItemInDBWithRecord:(CKRecord * _Nonnull)listItemRecord;
- (BOOL)updateListItemRecord:(CKRecord * _Nonnull)listItemRecord;
- (BOOL)deleteListItemInDB:(SSListItem * _Nonnull)listItem;
- (BOOL)deleteListItemInDBWithRecord:(CKRecord * _Nonnull)listItemRecord;
- (BOOL)deleteListItemsInDB:(NSArray <NSString *> * _Nonnull)listItemIDs;
- (BOOL)listItemExistsForID:(NSString * _Nonnull)dbID;

// Awaiting Sync

- (BOOL)insertAwaitingSyncObject:(__kindof SSObject * _Nonnull)obj;
- (BOOL)insertAwaitingDeleteSyncObject:(__kindof SSObject * _Nonnull)obj;
- (BOOL)deleteAwaitingSyncObjectWithSyncIDs:(NSArray <NSString *> * _Nonnull)dbIDs;
- (BOOL)deleteAllAwaitingSyncObjects;
- (BOOL)resyncRecordExistsForID:(NSString * _Nonnull)dbID;
- (BOOL)awaitingSyncHasData;

// Utils

- (NSInteger)mostRecentOrderingIndexForLists;
- (NSInteger)mostRecentOrderingIndexForTags;
- (NSArray <NSString *> * _Nonnull)recordsToDatabaseIDArray:(NSArray <CKRecord *> * _Nonnull)records;
- (NSString * _Nonnull)stringifyArrayOfIDs:(NSArray * _Nonnull)deletionIDs;
- (NSString * _Nonnull)stringifyArrayOfRecordToDatabaseIDs:(NSArray <CKRecord *> * _Nonnull)records;

@end

