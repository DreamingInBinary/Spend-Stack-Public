//
//  SSCloudKitDatabase.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/14/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSCloudKitDatabase.h"
#import "SSConstants.h"

@interface SSCloudKitDatabase()

@property (weak, nonatomic, nullable) id <SSCloudKitDatabaseDelegate> delegate;
@property (strong, nonatomic, nonnull) CKDatabase *db;
@property (strong, nonatomic, nonnull) CKRecordZone *customZone;
@property (strong, nonatomic, nullable) NSMutableDictionary <CKRecordZoneID *, CKServerChangeToken *> *listZoneChangeTokens;
@property (strong, nonatomic, nullable) CKServerChangeToken *databaseChangeToken;
@property (strong, nonatomic, nonnull) NSString *subscriptionName;

// Used to query NSUserDefaults for cached values. If you change this from the previously set value, if effectively resets all cached data.
// This is used so that this can be subsclassed and still store relevant data for each instance uniquely.
@property (strong, nonatomic, nonnull) NSString *dbCacheID;
@property (strong, nonatomic, readonly, nonnull) NSString *privateZoneChangeTokenCacheID;
@property (strong, nonatomic, readonly, nonnull) NSString *databaseChangeTokenCacheID;
@property (strong, nonatomic, readonly, nonnull) NSString *zoneCreatedCacheID;
@property (strong, nonatomic, readonly, nonnull) NSString *zoneSubscriptionCreatedCacheID;
@property (strong, nonatomic, readonly, nonnull) NSString *databaseSubscriptionCreatedCacheID;

@end

@implementation SSCloudKitDatabase

#pragma mark - Customer Getters

- (NSError *)notSignedInError
{
    return [NSError errorWithDomain:@"spendStack.CloudKitDatabase"
                               code:0101
                           userInfo:@{NSLocalizedDescriptionKey:@"The user isn't signed into iCloud, skipping network request."}];
}

- (NSMutableDictionary <CKRecordZoneID *, CKServerChangeToken *> *)listZoneChangeTokens
{
    NSData *changeTokenData = [ss_defaults() dataForKey:self.privateZoneChangeTokenCacheID];
    if (!changeTokenData) return nil;
    
    NSMutableDictionary <CKRecordZoneID *, CKServerChangeToken *> *changeTokens = [NSKeyedUnarchiver ss_unarchiveClassTypes:@[NSMutableDictionary.class, CKServerChangeToken.class, CKRecordZoneID.class] fromData:changeTokenData];
    
    return changeTokens;
}

- (CKServerChangeToken *)databaseChangeToken
{
    NSData *changeTokenData = [ss_defaults() dataForKey:self.databaseChangeTokenCacheID];
    if (!changeTokenData) return nil;
    
    CKServerChangeToken *changeToken = [NSKeyedUnarchiver ss_unarchiveClass:CKServerChangeToken.class fromData:changeTokenData];
    
    return changeToken;
}

- (BOOL)hasCreatedCustomZone
{
    return [ss_defaults() boolForKey:self.zoneCreatedCacheID];
}

- (BOOL)hasCreatedCustomZoneSubscription
{
    return [ss_defaults() boolForKey:self.zoneSubscriptionCreatedCacheID];
}

- (BOOL)hasCreatedDatabaseSubscription
{
    return [ss_defaults() boolForKey:self.databaseSubscriptionCreatedCacheID];
}

- (BOOL)hasSetupDatabaseStack
{
    if (self.db.databaseScope == CKDatabaseScopeShared) return self.hasCreatedDatabaseSubscription;
    return (self.hasCreatedCustomZone && self.hasCreatedDatabaseSubscription);
}

- (NSString *)privateZoneChangeTokenCacheID
{
    return [self.dbCacheID stringByAppendingString:@"zoneServerChangeTokens"];
}

- (NSString *)databaseChangeTokenCacheID
{
    return [self.dbCacheID stringByAppendingString:@"databaseServerChangeToken"];
}

- (NSString *)zoneCreatedCacheID
{
    return [self.dbCacheID stringByAppendingString:@"zoneCreated"];
}

- (NSString *)zoneSubscriptionCreatedCacheID
{
    return [self.dbCacheID stringByAppendingString:@"zoneSubscriptionCreated"];
}

- (NSString *)databaseSubscriptionCreatedCacheID
{
    return [self.dbCacheID stringByAppendingString:@"databaseSubscriptionCreated"];
}

- (CKDatabaseScope)dbScope
{
    return _db.databaseScope;
}

#pragma mark - Customer Getters/Setters

- (void)setListZoneChangeTokens:(NSMutableDictionary<CKRecordZoneID *,CKServerChangeToken *> *)listZoneChangeTokens
{
    if (listZoneChangeTokens == nil)
    {
        [ss_defaults() removeObjectForKey:self.privateZoneChangeTokenCacheID];
    }
    else
    {
        NSData *changeTokenData = [NSKeyedArchiver ss_secureArchive:listZoneChangeTokens];
        [ss_defaults() setObject:changeTokenData forKey:self.privateZoneChangeTokenCacheID];
    }
    
    [ss_defaults() synchronize];
}

- (void)setDatabaseChangeToken:(CKServerChangeToken *)databaseChangeToken
{
    if (databaseChangeToken == nil)
    {
        [ss_defaults() removeObjectForKey:self.databaseChangeTokenCacheID];
    }
    else
    {
        NSData *changeTokenData = [NSKeyedArchiver ss_secureArchive:databaseChangeToken];
        [ss_defaults() setObject:changeTokenData forKey:self.databaseChangeTokenCacheID];
    }
    
    [ss_defaults() synchronize];
}

- (void)setRecordZoneChangeToken:(CKServerChangeToken *)token forZoneID:(CKRecordZoneID *)zoneID
{
    NSMutableDictionary *mutableZoneTokens = [self.listZoneChangeTokens mutableCopy];
    if (mutableZoneTokens == nil) mutableZoneTokens = [NSMutableDictionary new];
    
    if (token == nil)
    {
        [mutableZoneTokens removeObjectForKey:zoneID];
    }
    else
    {
        NSAssert([token isKindOfClass:[CKServerChangeToken class]] && [zoneID isKindOfClass:[CKRecordZoneID class]], @"Spend Stack - Unexpected types for tokens.");
        mutableZoneTokens[zoneID] = token;
    }

    self.listZoneChangeTokens = mutableZoneTokens;
}

#pragma mark - Initializers

- (instancetype)initWithDatabase:(CKDatabase *)database customZoneName:(NSString *)customZoneName subscriptionName:(NSString *)subscriptionName delegate:(id <SSCloudKitDatabaseDelegate>)delegate
{
    self = [super init];
    
    if (self)
    {
        self.delegate = delegate;
        self.db = database;

        if (customZoneName && subscriptionName)
        {
            // Custom user's zone
            self.customZone = [[CKRecordZone alloc] initWithZoneName:customZoneName];
            self.subscriptionName = subscriptionName;
            self.dbCacheID = customZoneName;
        }
        else if (self.dbScope == CKDatabaseScopeShared)
        {
            // Shared
            self.subscriptionName = @"ss_sharedDatabaseSubscription";
            self.dbCacheID = @"ss_sharedDatabase";
        }
        else
        {
            // Public
            self.subscriptionName = @"ss_PublicDatabaseSubscription";
            self.dbCacheID = @"ss_publicDatabase";
        }
    }
    
    return self;
}

#pragma mark - Zone

- (CKFetchRecordZonesOperation * _Nonnull)fetchRecordZonesOperation
{
    CKFetchRecordZonesOperation *op = [[CKFetchRecordZonesOperation alloc] initWithRecordZoneIDs:@[self.customZone.zoneID]];
    op.database = self.db;
    op.qualityOfService = NSQualityOfServiceUserInitiated;
    op.fetchRecordZonesCompletionBlock = ^(NSDictionary <CKRecordZoneID *, CKRecordZone *> *recordZonesByZoneID, NSError * _Nullable operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error fetching db %@ zones: %@", self.dbCacheID, operationError.localizedDescription);
            return;
        }
        
        if (recordZonesByZoneID[self.customZone.zoneID] != nil)
        {
            NSLog(@"Spend Stack - db %@ zone has been previously created.", self.dbCacheID);
            [ss_defaults() setBool:YES forKey:self.zoneCreatedCacheID];
            [ss_defaults() synchronize];
        }
    };
    
    return op;
}

- (CKModifyRecordZonesOperation *)createZoneOperation
{
    CKModifyRecordZonesOperation *op = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:@[self.customZone]
                                                                                           recordZoneIDsToDelete:@[]];
    op.qualityOfService = NSQualityOfServiceUserInitiated;
    op.database = self.db;
    op.modifyRecordZonesCompletionBlock = ^(NSArray<CKRecordZone *> *savedRecordZones, NSArray<CKRecordZoneID *> * deletedRecordZoneIDs, NSError * operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error creating user's private list zone: %@ - %@", operationError.localizedDescription, operationError.userInfo[CKPartialErrorsByItemIDKey]);
            return;
        }

        NSLog(@"Spend Stack - db %@ has created its custom zone", self.dbCacheID);
        [ss_defaults() setBool:YES forKey:self.zoneCreatedCacheID];
        [ss_defaults() synchronize];
    };
    
    return op;
}

- (CKModifyRecordZonesOperation *)deleteZoneOperation
{
    CKModifyRecordZonesOperation *op = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:@[]
                                                                                 recordZoneIDsToDelete:self.listZoneChangeTokens.allKeys];
    op.qualityOfService = NSQualityOfServiceUserInitiated;
    op.database = self.db;
    op.modifyRecordZonesCompletionBlock = ^(NSArray<CKRecordZone *> *savedRecordZones, NSArray<CKRecordZoneID *> * deletedRecordZoneIDs, NSError * operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error deleting user's zone in %@: %@", self.dbCacheID, operationError.localizedDescription);
            return;
        }
        
        NSLog(@"Spend Stack - db %@ has deleted its custom zone(s)", self.dbCacheID);
        [ss_defaults() setBool:NO forKey:self.zoneCreatedCacheID];
        [ss_defaults() synchronize];
    };
    
    return op;
}

#pragma mark - Subscription

- (CKModifySubscriptionsOperation *)createDatabaseSubscriptionOperation
{
    CKDatabaseSubscription *databaseSubscription = [[CKDatabaseSubscription alloc] initWithSubscriptionID:self.subscriptionName];
    
    // Notification payload params
    CKNotificationInfo *notificationInfo = [CKNotificationInfo new];
    notificationInfo.shouldSendContentAvailable = YES;
    databaseSubscription.notificationInfo = notificationInfo;
    
    // Op to add it
    CKModifySubscriptionsOperation *op = [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:@[databaseSubscription] subscriptionIDsToDelete:@[]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.database = self.db;
    op.modifySubscriptionsCompletionBlock = ^(NSArray<CKSubscription *> *savedSubscriptions, NSArray<NSString *> * deletedSubscriptionIDs, NSError *operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error creating subscription for db %@: %@", operationError.localizedDescription, self.dbCacheID);
        }
        else
        {
            NSLog(@"Spend Stack - db %@ has been subscribed to its database changes", self.dbCacheID);
            [ss_defaults() setBool:YES forKey:self.databaseSubscriptionCreatedCacheID];
            [ss_defaults() synchronize];
        }
    };
    
    return op;
}

- (CKFetchSubscriptionsOperation *)fetchZoneSubscriptionsOperation
{
    CKFetchSubscriptionsOperation *op = [CKFetchSubscriptionsOperation fetchAllSubscriptionsOperation];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.database = self.db;
    op.fetchSubscriptionCompletionBlock = ^(NSDictionary<NSString *,CKSubscription *> *subscriptionsBySubscriptionID, NSError *operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error fetching subscription for %@ db: %@", operationError.localizedDescription, self.dbCacheID);
            return;
        }
        
        for (CKSubscription *existingSub in subscriptionsBySubscriptionID.allValues)
        {
            if ([existingSub.subscriptionID isEqual:self.subscriptionName])
            {
                NSLog(@"Spend Stack - db %@ subscription has been previously created.", self.dbCacheID);
                [ss_defaults() setBool:YES forKey:self.zoneSubscriptionCreatedCacheID];
                [ss_defaults() synchronize];
            }
        }
    };
    
    return op;
}

- (CKModifySubscriptionsOperation *)createZoneSubcriptionOperation
{
    // Create the subscription
    CKRecordZoneSubscription *customZoneSubscription = [[CKRecordZoneSubscription alloc] initWithZoneID:self.customZone.zoneID
                                                                                         subscriptionID:self.subscriptionName];
    
    // Notification payload params
    CKNotificationInfo *notificationInfo = [CKNotificationInfo new];
    notificationInfo.shouldSendContentAvailable = YES;
    customZoneSubscription.notificationInfo = notificationInfo;
    
    // Op to add it
    CKModifySubscriptionsOperation *op = [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:@[customZoneSubscription] subscriptionIDsToDelete:@[]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.database = self.db;
    op.modifySubscriptionsCompletionBlock = ^(NSArray<CKSubscription *> *savedSubscriptions, NSArray<NSString *> * deletedSubscriptionIDs, NSError *operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error creating subscription for db %@: %@", operationError.localizedDescription, self.dbCacheID);
        }
        else
        {
            NSLog(@"Spend Stack - db %@ has been subscribed to its custom zone changes", self.dbCacheID);
            [ss_defaults() setBool:YES forKey:self.zoneSubscriptionCreatedCacheID];
            [ss_defaults() synchronize];
        }
    };
    
    return op;
}

- (CKModifySubscriptionsOperation *)deleteZoneSubcriptionOperation
{
    // Op to add it
    CKModifySubscriptionsOperation *op = [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:@[] subscriptionIDsToDelete:@[self.subscriptionName]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.database = self.db;
    op.modifySubscriptionsCompletionBlock = ^(NSArray<CKSubscription *> *savedSubscriptions, NSArray<NSString *> * deletedSubscriptionIDs, NSError *operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Error deleting subscription for db %@: %@", operationError.localizedDescription, self.dbCacheID);
        }
        else
        {
            NSLog(@"Spend Stack - db %@ has deleted its subscription to custom zone changes", self.dbCacheID);
            [ss_defaults() setBool:NO forKey:self.zoneSubscriptionCreatedCacheID];
            [ss_defaults() synchronize];
        }
    };
    
    return op;
}

#pragma mark - Data Fetch

- (void)resetServerChangeToken
{
    self.listZoneChangeTokens = nil;
    self.databaseChangeToken = nil;
}

- (void)fetchDatabaseChanges:(CKDatabaseNotification *)databaseNotification withCompletion:(CloudKitFetchHandler)completion
{
    NSMutableArray <CKRecordZoneID *> *recordZonesChanges = [NSMutableArray new];
    NSMutableArray <CKRecordZoneID *> *recordZonesDeleted = [NSMutableArray new];
    
    // Get the zoneIDs to pass off to the recordZoneOp
    CKFetchDatabaseChangesOperation *op = [[CKFetchDatabaseChangesOperation alloc] initWithPreviousServerChangeToken:self.databaseChangeToken];
    op.fetchAllChanges = YES;
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.database = self.db;
    
    // Track change token
    op.changeTokenUpdatedBlock = ^(CKServerChangeToken *serverChangeToken) {
        self.databaseChangeToken = serverChangeToken;
    };
    
    // Shares that were stopped or user nuked all iCloud data
    op.recordZoneWithIDWasDeletedBlock = ^(CKRecordZoneID *zoneID) {
        [self setRecordZoneChangeToken:nil forZoneID:zoneID];
        [recordZonesDeleted addObject:zoneID];
    };
    
    // Basically all CRUD from shares and user's own stuff
    op.recordZoneWithIDChangedBlock = ^(CKRecordZoneID *zoneID) {
        [recordZonesChanges addObject:zoneID];
    };
    
    // Completion, and pass off to fetch zone changes
    op.fetchDatabaseChangesCompletionBlock = ^(CKServerChangeToken * serverChangeToken, BOOL moreComing, NSError *operationError) {
        self.databaseChangeToken = serverChangeToken;
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - All database fetches completed for db %@ with error: %@", self.dbCacheID, operationError.localizedDescription);
            
        }
        else
        {
            NSLog(@"Spend Stack - All database fetches are completed for db %@ - fetching zone changes now.", self.dbCacheID);
            [self fetchZoneChanges:nil
                           zoneIDs:recordZonesChanges
                      deletedZones:recordZonesDeleted
                    withCompletion:completion];
        }
    };
    
    [self.db addOperation:op];
}

- (void)fetchZoneChanges:(CKRecordZoneNotification *)zoneNotification zoneIDs:(NSMutableArray <CKRecordZoneID *> *)zoneIDs deletedZones:(NSArray <CKRecordZoneID *> *)deletedZoneIDs withCompletion:(CloudKitFetchHandler)completion
{
    // Return values
    NSMutableArray <CKRecord *> *changes = [NSMutableArray new];
    NSMutableArray <CKRecordID *> *deletes = [NSMutableArray new];
    
    // Early out if things are current
    if (zoneIDs.count == 0 && zoneNotification == nil)
    {
        completion(changes, deletes, deletedZoneIDs);
        return;
    }
    
    // Set Zone ID(s)
    if (zoneNotification)
    {
        NSMutableArray <CKRecordZoneID *> *mutableZoneIDs = [zoneIDs mutableCopy];
        [mutableZoneIDs addObject:zoneNotification.recordZoneID];
        zoneIDs = [mutableZoneIDs copy];
    }
    
    // Include latest server change tokens
    NSMutableDictionary <CKRecordZoneID *, CKFetchRecordZoneChangesConfiguration *> *fetchOptions = [NSMutableDictionary new];
    for (CKRecordZoneID *existingZoneID in self.listZoneChangeTokens)
    {
        CKFetchRecordZoneChangesConfiguration *zoneFetchOptions = [CKFetchRecordZoneChangesConfiguration new];
        zoneFetchOptions.previousServerChangeToken = self.listZoneChangeTokens[existingZoneID];
        fetchOptions[existingZoneID] = zoneFetchOptions;
    }

    // Fire off the actual request for changes
    CKFetchRecordZoneChangesOperation *op = [[CKFetchRecordZoneChangesOperation alloc] initWithRecordZoneIDs:zoneIDs configurationsByRecordZoneID:fetchOptions];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.fetchAllChanges = YES;
    op.database = self.db;
    
    // Edits and Adds
    op.recordChangedBlock = ^(CKRecord *record) {
        [changes addObject:record];
    };
    
    // Deletes
    op.recordWithIDWasDeletedBlock = ^(CKRecordID *recordID, NSString *recordType) {
        [deletes addObject:recordID];
    };
    
    // Change tokens per zone
    op.recordZoneChangeTokensUpdatedBlock = ^(CKRecordZoneID *recordZoneID, CKServerChangeToken *serverChangeToken, NSData *clientChangeTokenData) {
        [self setRecordZoneChangeToken:serverChangeToken forZoneID:recordZoneID];
    };
    
    // Completion per zone
    op.recordZoneFetchCompletionBlock = ^(CKRecordZoneID *recordZoneID, CKServerChangeToken *serverChangeToken, NSData *clientChangeTokenData, BOOL moreComing, NSError *recordZoneError) {
        if (recordZoneError != nil)
        {
            NSLog(@"Spend Stack - Error fetching record zone changes for record zone %@: %@", recordZoneError.localizedDescription, recordZoneID.zoneName);
        }
        else
        {
            [self setRecordZoneChangeToken:serverChangeToken forZoneID:recordZoneID];
            NSLog(@"Spend Stack - Change fetch completed for record zone %@", recordZoneID.zoneName);
        }
    };
    
    // Completion for all zones
    op.fetchRecordZoneChangesCompletionBlock = ^(NSError *operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - All change fetches completed for db %@ with error: %@", self.dbCacheID, operationError.localizedDescription);
            if (operationError.userInfo[CKPartialErrorsByItemIDKey])
            {
                NSDictionary <CKRecordZoneID *, NSError *> *errors = operationError.userInfo[CKPartialErrorsByItemIDKey];
                BOOL requireCleanFetch = NO;
                for (CKRecordZoneID *recordZoneID in errors.allKeys)
                {
                    NSError *error = errors[recordZoneID];
                    if (error.code == CKErrorChangeTokenExpired)
                    {
                        // Need to do a clean fetch
                        NSLog(@"Spend Stack - Error fetching record zone changes. Change token is too old, nilling it out and refetching. (%@ - %@)", error.localizedDescription, self.dbCacheID);
                        [self setRecordZoneChangeToken:nil forZoneID:recordZoneID];
                        requireCleanFetch = YES;
                    }
                    
                    if (requireCleanFetch)
                    {
                        [self fetchZoneChanges:nil zoneIDs:nil deletedZones:@[] withCompletion:completion];
                        return;
                    }
                }
            }
            completion(changes, deletes, deletedZoneIDs);
        }
        else
        {
            NSLog(@"Spend Stack - All change fetches are completed for db %@.", self.dbCacheID);
            completion(changes, deletes, deletedZoneIDs);
        }
    };
    
    [self.db addOperation:op];
}

- (void)forceFetchRecords:(NSArray<CKRecord *> *)records withCompletion:(void (^)(NSArray<CKRecord *> * _Nonnull, NSError * _Nullable))completion
{
    [self forceFetchRecords:records desiredKeys:@[] withCompletion:completion];
}

- (void)forceFetchRecords:(NSArray<CKRecord *> *)records desiredKeys:(NSArray<NSString *> *)keys withCompletion:(void (^)(NSArray<CKRecord *> * _Nonnull, NSError * _Nullable))completion
{
    NSMutableArray <CKRecordID *> *recordIDs = [NSMutableArray new];
    for (CKRecord *record in records)
    {
        [recordIDs addObject:record.recordID];
    }
    
    // Fire off the actual request for changes
    CKFetchRecordsOperation *op = [[CKFetchRecordsOperation alloc] initWithRecordIDs:recordIDs];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.database = self.db;
    if (keys && keys.count > 0)
    {
        op.desiredKeys = keys;
    }
    
    // Completion
    op.fetchRecordsCompletionBlock = ^(NSDictionary<CKRecordID *,CKRecord *> * _Nullable recordsByRecordID, NSError * _Nullable operationError) {
        if (operationError != nil)
        {
            NSLog(@"Spend Stack - Single record fetch completed for db %@ with error: %@", self.dbCacheID, operationError.localizedDescription);
            completion(recordsByRecordID.allValues, operationError);
        }
        else
        {
            NSLog(@"Spend Stack - Single record fetch completed for db %@.", self.dbCacheID);
            completion(recordsByRecordID.allValues, operationError);
        }
    };
    
    [self.db addOperation:op];
}

#pragma mark - Create/Update/Delete

- (void)saveObjects:(NSArray <__kindof SSObject *> *)objects withSavePolicy:(CKRecordSavePolicy)policy deleteObjects:(NSArray <__kindof SSObject *> *)deletions withCompletion:(void (^)(NSError * _Nullable))completion
{
    if ([self.delegate userIsSignedIn] == NO || [self.delegate dataIsAvailable] == NO)
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            [self.delegate dataShouldRequeueForSync:objects deletions:deletions];
        });

        completion([self.delegate userIsSignedIn] ? nil : self.notSignedInError);
        
        return;
    }
    
    // Get the records
    NSMutableArray <CKRecord *> *records = [NSMutableArray new];
    NSMutableArray *deletionRecordIDs = [NSMutableArray new];
    
    for (SSObject *deletion in deletions)
    {
        [deletionRecordIDs addObject:deletion.objCKRecord.recordID];
    }
    
    for (SSObject *ssObj in objects)
    {
        [ssObj updateRecord:ssObj.objCKRecord fromDictionary:[ssObj dictionaryRepresentation]];
        [records addObject:ssObj.objCKRecord];
    }
    
    
    // Hit CloudKit
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:records
                                                                         recordIDsToDelete:deletionRecordIDs];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.savePolicy = policy;
    op.perRecordCompletionBlock = ^(CKRecord * _Nonnull record, NSError * _Nullable error) {
        NSError *modificationError = [self checkForRecordModifiedError:error withRecord:record];
        if (modificationError)
        {
            [self handleRecordMergeConflict:modificationError];
        }
        else if (error.code == CKErrorAssetFileNotFound)
        {
            for (SSObject *object in objects)
            {
                if ([object.objCKRecord.recordID.recordName isEqualToString:record.recordID.recordName])
                {
                    [self retrySaveAssetForObject:object];
                    break;
                }
            }
        }
        else if (error.code == CKErrorNetworkFailure ||
                 error.code == CKErrorNetworkUnavailable ||
                 error.code == CKErrorServiceUnavailable)
        {
            for (SSObject *obj in objects)
            {
                if ([obj.dbID isEqualToString:record.recordID.recordName])
                {
                    [self.delegate dataShouldRequeueForSync:@[obj] deletions:@[]];
                    return;
                }
            }
            
            for (SSObject *obj in deletions)
            {
                if ([obj.dbID isEqualToString:record.recordID.recordName])
                {
                    [self.delegate dataShouldRequeueForSync:@[] deletions:@[obj]];
                    return;
                }
            }
        }
    };
    op.modifyRecordsCompletionBlock = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *operationError) {
        double delayVal = [self checkForRetryError:operationError];
        
        if (delayVal != 0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayVal * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self saveObjects:objects
                   withSavePolicy:policy
                    deleteObjects:deletions
                   withCompletion:completion];
            });
        }
        else
        {
            if (self.shouldAssertOnError) NSAssert(operationError == nil, @"Spend Stack - CloudKit Error:(%@)", operationError);
            [self.delegate recordsSuccessfullySaved:savedRecords];
            completion(operationError);
        }
    };
    
    [self.db addOperation:op];
}

- (void)saveAwaitingSyncObjects:(NSArray<__kindof SSObject *> *)objects deleteIds:(NSArray<__kindof CKRecordID *> *)deletionIDs withCompletion:(void (^)(NSError * _Nullable))completion
{
    // Get the records
    NSMutableArray <CKRecord *> *records = [NSMutableArray new];
    for (SSObject *ssObj in objects)
    {
        [ssObj updateRecord:ssObj.objCKRecord fromDictionary:[ssObj dictionaryRepresentation]];
        
        if ([records containsObject:ssObj.objCKRecord] == NO)
        {
            [records addObject:ssObj.objCKRecord];
        }
    }
    
    __block NSMutableArray <CKRecord *> *successfulRequeues = [NSMutableArray new];
    
    // Hit CloudKit
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:records
                                                                         recordIDsToDelete:deletionIDs];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.savePolicy = CKRecordSaveAllKeys;
    op.perRecordCompletionBlock = ^(CKRecord * _Nonnull record, NSError * _Nullable error) {
        if (error == nil || error.code == CKErrorServerRecordChanged || error.code == CKErrorPartialFailure)
        {
            [successfulRequeues addObject:record];
        }
    };
    op.modifyRecordsCompletionBlock = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *operationError) {
        double delayVal = [self checkForRetryError:operationError];
        
        if (delayVal != 0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayVal * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self saveAwaitingSyncObjects:objects deleteIds:deletionIDs withCompletion:completion];
            });
        }
        else
        {
            if (self.shouldAssertOnError) NSAssert(operationError == nil, @"Spend Stack - CloudKit Error:(%@)", operationError);
            [self.delegate dataRequeuedSuccessfully:successfulRequeues];
            completion(operationError);
        }
    };
    
    [self.db addOperation:op];
}

#pragma mark - Sharing

- (void)saveRootRecord:(__kindof SSObject *)ssObj share:(CKShare *)share withCompletion:(void (^)(NSError * _Nullable))completion
{
    // Hit CloudKit. Account status and data connection checks occur in the CloudKitManager instance. 
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[ssObj.objCKRecord, share]
                                                                         recordIDsToDelete:@[]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.savePolicy = CKRecordSaveAllKeys;
    op.perRecordCompletionBlock = ^(CKRecord *record, NSError *error) {
        NSError *modificationError = [self checkForRecordModifiedError:error withRecord:record];
        if (modificationError)
        {
            [self handleRecordMergeConflict:modificationError];
        }
        else if (error.code == CKErrorAssetFileNotFound)
        {
            [self retrySaveAssetForObject:ssObj];
        }
    };
    op.modifyRecordsCompletionBlock = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *operationError) {
        double delayVal = [self checkForRetryError:operationError];
        
        if (delayVal != 0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayVal * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self saveRootRecord:ssObj
                               share:share
                      withCompletion:completion];
            });
        }
        else
        {
            if (self.shouldAssertOnError) NSAssert(operationError == nil, @"Spend Stack - CloudKit Error:(%@)", operationError);
            [self.delegate recordsSuccessfullySaved:savedRecords];
            completion(operationError);
        }
    };
    
    [self.db addOperation:op];
}

- (void)deleteShare:(CKShare *)share withCompletion:(void (^)(NSError * _Nullable))completion
{
    // Hit CloudKit. Account status and data connection checks occur in the CloudKitManager instance.
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[]
                                                                         recordIDsToDelete:@[share.recordID]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.savePolicy = CKRecordSaveAllKeys;
    op.perRecordCompletionBlock = ^(CKRecord *record, NSError *error) {
        if (error)
        {
            NSLog(@"Spend Stack - Error when deleting share in per record completion block:%@", error);
        }
    };
    op.modifyRecordsCompletionBlock = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *operationError) {
        double delayVal = [self checkForRetryError:operationError];
        
        if (delayVal != 0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayVal * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self deleteShare:share
                   withCompletion:completion];
            });
        }
        else
        {
            if (self.shouldAssertOnError) NSAssert(operationError == nil, @"Spend Stack - CloudKit Error:(%@)", operationError);
            [self.delegate recordsSuccessfullySaved:savedRecords];
            completion(operationError);
        }
    };
    
    [self.db addOperation:op];
}

- (void)fetchShareRecord:(CKRecordID *)shareRecordID withCompletion:(void (^)(CKShare * _Nullable, NSError * _Nullable))completion
{
    NSOperationQueue *opQueue = [NSOperationQueue new];
    opQueue.maxConcurrentOperationCount = 1;
    
    __block CKShare *fetchedShare;
    __block NSError *operationError;
    
    CKFetchRecordsOperation *fetchOp = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[shareRecordID]];
    fetchOp.qualityOfService = NSQualityOfServiceUserInitiated;
    fetchOp.database = self.db;
    fetchOp.perRecordCompletionBlock = ^(CKRecord *record, CKRecordID *recordID, NSError *error) {
        operationError = error;
    };
    fetchOp.fetchRecordsCompletionBlock = ^(NSDictionary<CKRecordID *,CKRecord *> *recordsByRecordID, NSError *error) {
        fetchedShare = (CKShare *)recordsByRecordID[shareRecordID];
        if (operationError == nil) operationError = error;
    };
    
    [opQueue addOperation:fetchOp];
    [opQueue waitUntilAllOperationsAreFinished];
    completion(fetchedShare, operationError);
}

#pragma mark - Convienience API

- (void)deleteRootRecordWithID:(CKRecordID *)recordID withCompletion:(void (^)(NSError * _Nullable))completion
{
    if ([self.delegate userIsSignedIn] == NO || [self.delegate dataIsAvailable] == NO)
    {
        // Handle resyncs here
        completion([self.delegate userIsSignedIn] ? nil : self.notSignedInError);
        return;
    }

    // Hit CloudKit
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[]
                                                                         recordIDsToDelete:@[recordID]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.perRecordCompletionBlock = ^(CKRecord * _Nonnull record, NSError * _Nullable error) {
        if (error.code == CKErrorNetworkFailure ||
                 error.code == CKErrorNetworkUnavailable ||
                 error.code == CKErrorServiceUnavailable)
        {
            // Handle resyncs here
        }
    };
    op.modifyRecordsCompletionBlock = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *operationError) {
        double delayVal = [self checkForRetryError:operationError];
        
        if (delayVal != 0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayVal * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self deleteRootRecordWithID:recordID
                              withCompletion:completion];
            });
        }
        else
        {
            if (self.shouldAssertOnError) NSAssert(operationError == nil, @"Spend Stack - CloudKit Error:(%@)", operationError);
            [self.delegate recordsSuccessfullySaved:savedRecords];
            completion(operationError);
        }
    };
    
    [self.db addOperation:op];
}

#pragma mark - Base Error Handling

- (double)checkForRetryError:(NSError *)operationError
{
    switch (operationError.code)
    {
        case CKErrorRequestRateLimited:
        case CKErrorServiceUnavailable:
        case CKErrorZoneBusy:
        {
            double delay = 3.0;
            NSNumber *delayVal = operationError.userInfo[CKErrorRetryAfterKey];
            if (delayVal) delay = delayVal.integerValue;
            NSLog(@"Spend Stack - CloudKit is requesting us to reattempt the opertation in %@ seconds.", @(delay));
            return delay;
        }
        default:
        {
            return 0;
        }
    }
}

- (NSError *)checkForRecordModifiedError:(NSError *)operationError withRecord:(CKRecord *)record
{
    if (operationError.code == CKErrorPartialFailure)
    {
        // Check if the partial error was caused by a modification error
        NSError *error = operationError.userInfo[CKPartialErrorsByItemIDKey][record.recordID];
        
        if (error.code == CKErrorServerRecordChanged)
        {
            return error;
        }
    }
    else if (operationError.code == CKErrorServerRecordChanged)
    {
        return operationError;
    }
    
    return nil;
}

- (void)handleRecordMergeConflict:(NSError *)operationError
{
    NSLog(@"Spend Stack - Detected merge conflict. Merging records.");
    
    __unused CKRecord *clientRecord = operationError.userInfo[CKRecordChangedErrorClientRecordKey];
    __unused CKRecord *serverRecord = operationError.userInfo[CKRecordChangedErrorServerRecordKey];
    __unused CKRecord *localRecord = operationError.userInfo[CKRecordChangedErrorAncestorRecordKey];
    
    __weak typeof(self) weakSelf = self;
    
    if (serverRecord == nil || serverRecord.recordID == nil)
    {
        NSLog(@"Spend Stack - Merge conflict resolution backing out because there's no server ID.");
        return;
    }
    
    [self.db fetchRecordWithID:serverRecord.recordID completionHandler:^(CKRecord * record, NSError *error) {
        NSLog(@"Spend Stack - Merge conflict resolution completed with error:(%@)", error);
        
        if (record)
        {
            NSLog(@"Spend Stack - Merge occuring...\n**********\nClient Values:\n");
            for (NSString *key in clientRecord.allKeys)
            {
                NSLog(@"%@ - %@\n", key, clientRecord[key]);
            }
            NSLog(@"Client Record Change Token - %@", clientRecord.recordChangeTag);
            NSLog(@"**********\nServer Values:\n");
            for (NSString *key in serverRecord.allKeys)
            {
                NSLog(@"%@ - %@\n", key, serverRecord[key]);
            }
            NSLog(@"Server Record Change Token - %@", serverRecord.recordChangeTag);
            NSLog(@"**********\nLocal Values:\n");
            for (NSString *key in localRecord.allKeys)
            {
                NSLog(@"%@ - %@\n", key, localRecord[key]);
            }
            NSLog(@"Local Record Change Token - %@", localRecord.recordChangeTag);
            NSLog(@"**********");
            
            // Copy over server edits
            for (NSString *key in serverRecord.allKeys)
            {
                record[key] = serverRecord[key];
            }
            
            [weakSelf.delegate handleRecordMergeConflict:record database:self];
        }
    }];
}

- (void)retrySaveAssetForObject:(SSObject *)object
{
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[object.objCKRecord]
                                                                         recordIDsToDelete:@[]];
    op.qualityOfService = NSQualityOfServiceUserInteractive;
    op.savePolicy = CKRecordSaveChangedKeys;
    op.perRecordCompletionBlock = ^(CKRecord * _Nonnull record, NSError * _Nullable error) {
        NSLog(@"Spend Stack - Finished reattaching missing media with error:(%@)", error);
    };
    
    NSAssert([object isKindOfClass:[SSListItem class]], @"Spend Stack - Trying to resave an asset that's not a list item.");
    
    SSListItem *listItem = (SSListItem *)object;
    
    if (listItem.mediaAssetData == nil)
    {
        NSLog(@"Spend Stack - Tried to resave the asset's media but it had no data.");
        return;
    }
    
    SSListItemMediaAttachResult *attachResult = [listItem generateNewMediaItemResultFromData:listItem.mediaAssetData];
    
    object.objCKRecord[@"mediaAttachment"] = attachResult.asset;
    [self.db addOperation:op];
}

@end
