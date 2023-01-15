//
//  SSCloudKitDatabase.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/14/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CKServerChangeToken;
@class CKDatabase;
@class SSCloudKitDatabase;


typedef void (^CloudKitFetchHandler)(NSArray <CKRecord *> * _Nonnull changedRecords, NSArray <CKRecordID *> * _Nonnull deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs);

@protocol SSCloudKitDatabaseDelegate <NSObject>

@required
- (void)dataShouldRequeueForSync:(NSArray <__kindof SSObject *> * _Nullable)addOrEdits deletions:(NSArray <__kindof SSObject *> * _Nullable)deletions;
- (void)dataRequeuedSuccessfully:(NSArray <__kindof CKRecord *> * _Nullable)data;
- (void)recordsSuccessfullySaved:(NSArray <__kindof CKRecord *> * _Nullable)data;
- (void)handleRecordMergeConflict:(CKRecord * _Nonnull)updateRecord database:(SSCloudKitDatabase * _Nonnull)database;
- (BOOL)userIsSignedIn;
- (BOOL)dataIsAvailable;

@end

@interface SSCloudKitDatabase : NSObject

@property (nonatomic, getter=shouldAssertOnError) BOOL assertOnError;
@property (nonatomic, readonly, getter=hasCreatedCustomZone) BOOL createdCustomZone;
@property (nonatomic, readonly, getter=hasCreatedCustomZoneSubscription) BOOL createdCustomZoneSubscription;
@property (nonatomic, readonly, getter=hasCreatedDatabaseSubscription) BOOL createdDatabaseSubscription;
@property (nonatomic, readonly, getter=hasSetupDatabaseStack) BOOL setupDatabaseStack;
@property (strong, nonatomic, readonly, nonnull) NSError *notSignedInError;
@property (nonatomic, readonly) CKDatabaseScope dbScope;

- (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithDatabase:(CKDatabase * _Nonnull)database customZoneName:(NSString * _Nullable)customZoneName subscriptionName:(NSString * _Nullable)subscriptionName delegate:(id <SSCloudKitDatabaseDelegate> _Nullable)delegate NS_DESIGNATED_INITIALIZER;

#pragma mark - Zones

- (CKModifyRecordZonesOperation * _Nonnull)fetchRecordZonesOperation;
- (CKModifySubscriptionsOperation * _Nonnull)createZoneOperation;
- (CKModifySubscriptionsOperation * _Nonnull)deleteZoneOperation;

#pragma mark - Subscriptions

- (CKModifySubscriptionsOperation * _Nonnull)createDatabaseSubscriptionOperation;
- (CKFetchSubscriptionsOperation * _Nonnull)fetchZoneSubscriptionsOperation;
- (CKModifySubscriptionsOperation * _Nonnull)createZoneSubcriptionOperation;
- (CKModifySubscriptionsOperation * _Nonnull)deleteZoneSubcriptionOperation;

#pragma mark - Fetch

- (void)resetServerChangeToken;
- (void)fetchDatabaseChanges:(CKDatabaseNotification * _Nullable)databaseNotification withCompletion:(CloudKitFetchHandler _Nonnull)completion;
- (void)fetchZoneChanges:(CKRecordZoneNotification * _Nullable)zoneNotification zoneIDs:(NSMutableArray <CKRecordZoneID *> * _Nullable)zoneIDs deletedZones:(NSArray <CKRecordZoneID *> * _Nonnull)deletedZoneIDs withCompletion:(CloudKitFetchHandler _Nonnull)completion;
- (void)forceFetchRecords:(NSArray <CKRecord *> * _Nonnull)records withCompletion:(void(^ _Nullable)(NSArray <CKRecord *> * _Nonnull, NSError * _Nullable))completion;
- (void)forceFetchRecords:(NSArray <CKRecord *> * _Nonnull)records desiredKeys:(NSArray <NSString *> * _Nonnull)keys withCompletion:(void(^ _Nullable)(NSArray <CKRecord *> * _Nonnull, NSError * _Nullable))completion;

#pragma mark - Save/Update/Delete

- (void)saveObjects:(NSArray <__kindof SSObject *> * _Nonnull)objects withSavePolicy:(CKRecordSavePolicy)policy deleteObjects:(NSArray <__kindof SSObject *> * _Nonnull)deletions withCompletion:(void(^ _Nullable)(NSError * _Nullable))completion;
- (void)saveAwaitingSyncObjects:(NSArray <__kindof SSObject *> * _Nonnull)objects deleteIds:(NSArray <__kindof CKRecordID *> * _Nonnull)deletionIDs withCompletion:(void(^ _Nullable)(NSError * _Nullable))completion;

#pragma mark - Sharing

- (void)saveRootRecord:(__kindof SSObject * _Nonnull)ssObj share:(CKShare * _Nonnull)share withCompletion:(void(^ _Nullable)(NSError * _Nullable))completion;
- (void)deleteShare:(CKShare * _Nonnull)share withCompletion:(void(^ _Nullable)(NSError * _Nullable))completion;
- (void)fetchShareRecord:(CKRecordID * _Nonnull)shareRecordID withCompletion:(void(^ _Nullable)(CKShare * _Nullable shareRecord, NSError * _Nullable))completion;

#pragma mark - Convienience API

- (void)deleteRootRecordWithID:(CKRecordID * _Nonnull)recordID withCompletion:(void(^ _Nullable)(NSError * _Nullable))completion;

@end
