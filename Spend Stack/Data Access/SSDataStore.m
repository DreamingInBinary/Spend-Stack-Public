//
//  SSDataStore.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/15/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSDataStore.h"
#import "SSCloudKitManager.h"
#import "SSCloudKitDatabase.h"
#import "SSConstants.h"
#import "SSListDataSourceAdapter.h"
#import "CKShare+Utils.h"
#import "CKRecordZoneID+Utils.h"
#import "Spend_Stack_2-Swift.h"
#import <CloudKit/CloudKit.h>

@interface SSDataStore() <SSCloudKitManagerDelegate>

@property (strong, nonatomic, readwrite, nonnull) SSCloudKitManager *ckManager;
@property (strong, nonatomic, readwrite, nonnull) FMDatabaseQueue *readWriteQueue;
@property (nonatomic) dispatch_queue_t serverFetchQueue;
@property (nonatomic) dispatch_queue_t synchrousDBFetchQueue; // For querying lists and tags synchronously

@end

@implementation SSDataStore

#pragma mark - Initializer

+ (instancetype)sharedInstance {
    static SSDataStore *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
        sharedManager.serverFetchQueue = dispatch_queue_create("serverFetchQueue", NULL);
        sharedManager.synchrousDBFetchQueue = dispatch_queue_create("synchrousDBFetchQueue", NULL);
        sharedManager.ckManager = [[SSCloudKitManager alloc] initWithDelegate:sharedManager];
    });
    
    return sharedManager;
}

#pragma mark - FMDB

+ (NSString *)oldDatabaseFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directories = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *documentPath = [directories.firstObject URLByAppendingPathComponent:@"spendStack.db"].path;
    
    return documentPath;
}

+ (NSString *)databaseFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *sharedURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:SS_APP_GROUP_NAME];
    return [sharedURL URLByAppendingPathComponent:@"spendStack.db"].path;
}

- (void)createDatabaseSchemaIfNeeded
{
    // Copy over old db first?
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[SSDataStore oldDatabaseFilePath]])
    {
        NSError *e;
        [fileManager removeItemAtPath:[SSDataStore databaseFilePath] error:&e];
        [fileManager moveItemAtPath:[SSDataStore oldDatabaseFilePath]
                             toPath:[SSDataStore databaseFilePath]
                              error:&e];
        
        NSLog(@"Spend Stack - Moved old database with error: %@", e);
    }
    
    // Do the same for user defaults
    [self migrateUserDefaultsIfNeeded];
    
    self.readWriteQueue = [FMDatabaseQueue databaseQueueWithPath:[SSDataStore databaseFilePath]];
    
    [self.readWriteQueue inDatabase:^(FMDatabase *db) {
        __unused BOOL activatedWALMode = [db executeStatements:@"PRAGMA journal_mode=WAL;"];
        __unused BOOL listTableCreated = [db executeStatements:sql_ListCreateTable];
        __unused BOOL listTaxRateInfoTableCreated = [db executeStatements:sql_ListTaxRateInfoCreateTable];
        __unused BOOL tagsTableCreated = [db executeStatements:sql_TagsCreateTable];
        __unused BOOL listTagsTableCreated = [db executeStatements:sql_ListTagsCreateTable];
        __unused BOOL listItemsTableCreated = [db executeStatements:sql_ListItemCreateTable];
        __unused BOOL awaitingSyncTableCreated = [db executeStatements:sql_AwaitingSyncCreateTable];
        
        // Triggers
        __unused BOOL listCountUpdateTriggerCreated = [db executeStatements:sql_ListItemCountInsertTrigger];
        __unused BOOL listCountDeleteTriggerCreated = [db executeStatements:sql_ListItemCountDeleteTrigger];
        __unused BOOL listTotalAmountListItemDeletedTriggerCreated = [db executeStatements:sql_ListItemDeleteUpdateListTotalPriceTrigger];
        __unused BOOL listTotalAmountListItemInsertedTriggerCreated = [db executeStatements:sql_ListItemInsertUpdateListTotalPriceTrigger];
        __unused BOOL listTotalAmountListItemUpdatedTriggerCreated = [db executeStatements:sql_ListItemUpdatedUpdateListTotalPriceTrigger];
        __unused BOOL listItemRemoveTagAfterDeleteTriggerCreated = [db executeStatements:sql_TagRemoveFromListItemsDeleteTrigger];
        __unused BOOL listTagEditsWhenMasterTagIsEditedTriggerCreated = [db executeStatements:sql_TagEditListTagsWhenMasterTagEditedTrigger];
        __unused BOOL listItemRemoveTagIfMasterTagDeletedTriggerCreated = [db executeStatements:sql_ListItemRemoveTagWhenMasterTagDeletesTrigger];
        
        NSAssert(activatedWALMode &&
                 listTableCreated &&
                 listTaxRateInfoTableCreated &&
                 tagsTableCreated &&
                 listTagsTableCreated &&
                 listItemsTableCreated &&
                 awaitingSyncTableCreated &&
                 listCountUpdateTriggerCreated &&
                 listCountDeleteTriggerCreated &&
                 listTotalAmountListItemDeletedTriggerCreated &&
                 listTotalAmountListItemInsertedTriggerCreated &&
                 listTotalAmountListItemUpdatedTriggerCreated &&
                 listItemRemoveTagAfterDeleteTriggerCreated &&
                 listTagEditsWhenMasterTagIsEditedTriggerCreated &&
                 listItemRemoveTagIfMasterTagDeletedTriggerCreated, @"Spend Stack - Error creating database schema.");
        NSLog(@"Spend Stack - Schema created.");
        
        // Alter scripts
        BOOL successAlter;
        if ([db columnExists:@"showingCheckboxes" inTableWithName:@"Lists"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE Lists ADD COLUMN showingCheckboxes INTEGER NOT NULL DEFAULT 0"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"totalDisplayType" inTableWithName:@"Lists"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE Lists ADD COLUMN totalDisplayType INTEGER NOT NULL DEFAULT 0"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"currencyIdentifier" inTableWithName:@"Lists"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE Lists ADD COLUMN currencyIdentifier TEXT"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"recurringPricingCycle" inTableWithName:@"ListItems"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE ListItems ADD COLUMN recurringPricingCycle INTEGER DEFAULT 0"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"recurringPricingFrequency" inTableWithName:@"ListItems"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE ListItems ADD COLUMN recurringPricingFrequency INTEGER DEFAULT 1"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"linkAttachment" inTableWithName:@"ListItems"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE ListItems ADD COLUMN linkAttachment TEXT"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"customDate" inTableWithName:@"ListItems"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE ListItems ADD COLUMN customDate REAL"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        } 
        
        if ([db columnExists:@"linkMetadata" inTableWithName:@"ListItems"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE ListItems ADD COLUMN linkMetadata BLOB"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
        
        if ([db columnExists:@"cardImportName" inTableWithName:@"ListItems"] == NO)
        {
            successAlter = [db executeUpdate:@"ALTER TABLE ListItems ADD COLUMN cardImportName TEXT"];
            NSAssert(successAlter, @"Alter table failed: %@", [db lastErrorMessage]);
        }
    }];
}

#pragma mark - Fetch to Model Queries

- (NSArray <SSList *> *)queryAllLists
{
    __block NSArray <SSList *> *allLists;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(self.synchrousDBFetchQueue, ^{
        [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            NSMutableArray <SSList *> *lists = [NSMutableArray new];
            FMResultSet *res = [db executeQuery:sql_ListWithTaxRateInfoSelectAll];
            
            while ([res next])
            {
                [lists addObject:[[SSList alloc] initWithResultSet:res]];
            }
            
            allLists = [NSArray arrayWithArray:lists];
            dispatch_semaphore_signal(sem);
        }];
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return allLists;
}

- (NSArray <SSTag *> *)queryAllMasterTags
{
    __block NSArray <SSTag *> *allTags;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(self.synchrousDBFetchQueue, ^{
        [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            NSMutableArray <SSTag *> *tags = [NSMutableArray new];
            FMResultSet *res = [db executeQuery:sql_TagSelectAll];
            
            while ([res next])
            {
                [tags addObject:[[SSTag alloc] initWithResultSet:res]];
            }
            
            allTags = [NSArray arrayWithArray:tags];
            dispatch_semaphore_signal(sem);
        }];
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return allTags;
}

- (NSArray <SSListTag *> *)queryListTagsSharedToMeForListID:(NSString *)dbID
{
    __block NSArray <SSListTag *> *allListTags;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(self.synchrousDBFetchQueue, ^{
        [self.readWriteQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray <SSListTag *> *tags = [NSMutableArray new];
            FMResultSet *res = [db executeQuery:sql_ListTagSelectTagsSharedWithMeByListTagID, dbID];
            
            while ([res next])
            {
                [tags addObject:[[SSListTag alloc] initWithResultSet:res]];
            }

            allListTags = [NSArray arrayWithArray:tags];
            dispatch_semaphore_signal(sem);
        }];
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return allListTags;
}

- (SSList *)queryListByID:(NSString *)dbID
{
    __block SSList *list;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    dispatch_async(self.synchrousDBFetchQueue, ^{
        [self.readWriteQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *res = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, dbID];
            
            while ([res next])
            {
                list = [[SSList alloc] initWithResultSet:res];
            }

            dispatch_semaphore_signal(sem);
        }];
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return list;
}

#pragma mark - CloudKitManager Delegate

- (void)ss_userSignedIntoiCloud
{
    // Setup stack
    // Offline data? Upload
    // Then fetch changes
    __weak typeof(self) weakSelf = self;
    [self.ckManager createPrivateUsersCloudKitStackWithCompletion:^{
        if (self.ckManager.dataConnectionIsAvailable)
        {
            [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
                if ([db awaitingSyncHasData])
                {
                    [weakSelf processAwaitingSyncOperations:db withCompletion:^(NSError * _Nullable possibleError) {
                        [weakSelf.ckManager fetchDatabaseChangesWithNotification:nil];
                    }];
                }
                else
                {
                    NSLog(@"Spend Stack - No data awaiting sync. Performing fetch.");
                    [weakSelf.ckManager fetchDatabaseChangesWithNotification:nil];
                }
            }];
        }
        else
        {
            [weakSelf.ckManager fetchDatabaseChangesWithNotification:nil];
        }
    }];
}

- (void)ss_deviceEnteredReachableState
{
    [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([db awaitingSyncHasData])
        {
            [self processAwaitingSyncOperations:db withCompletion:^(NSError * _Nullable possibleError) {
                NSLog(@"Spend Stack - Finished processing resyncs with error: %@", possibleError);
            }];
        }
    }];
}

- (void)ss_database:(SSCloudKitDatabase *)db fetchedChangedRecords:(NSArray <CKRecord *> *)changes deletions:(NSArray <CKRecordID *> *)deletions deletedZones:(NSArray<CKRecordZoneID *> *)deletedZoneIDs
{
    dispatch_async(self.serverFetchQueue, ^{
        if (changes.count == 0 && deletions.count == 0 && deletedZoneIDs.count == 0)
        {
            NSLog(@"Spend Stack - No changes after latest fetch from the server for %@.", db.dbScope == 2 ? @"private DB" : @"shared DB");
            return;
        }
        
        NSMutableArray <NSString *> *deletionIDs = [NSMutableArray new];
        
        NSPredicate *listPredicate = [NSPredicate predicateWithFormat:@"SELF.recordType == 'SSList'"];
        NSPredicate *taxInfoPredicate = [NSPredicate predicateWithFormat:@"SELF.recordType == 'SSTaxRateInfo'"];
        NSPredicate *tagPredicate = [NSPredicate predicateWithFormat:@"SELF.recordType == 'SSTag'"];
        NSPredicate *listTagPredicate = [NSPredicate predicateWithFormat:@"SELF.recordType == 'SSListTag'"];
        NSPredicate *listItemPredicate = [NSPredicate predicateWithFormat:@"SELF.recordType == 'SSListItem'"];
        
        NSArray *addOrEditedListsRecords = [changes filteredArrayUsingPredicate:listPredicate];
        NSArray *addOrEditedTaxRatesRecords = [changes filteredArrayUsingPredicate:taxInfoPredicate];
        NSArray *addOrEditedTagsRecords = [changes filteredArrayUsingPredicate:tagPredicate];
        NSArray *addOrEditedListTagRecords = [changes filteredArrayUsingPredicate:listTagPredicate];
        NSArray *addOrEditedListItemsRecords = [changes filteredArrayUsingPredicate:listItemPredicate];
        
        [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            // Entire zone deleted? Remove any lists first in those zones
            if (deletedZoneIDs.count > 0)
            {
                // First, get all list records to match their zoneIDs to the deleted zones
                FMResultSet *result = [db executeQuery:sql_ListSelectAllListRecords];
                NSMutableArray <CKRecord *> *listRecords = [NSMutableArray new];

                while ([result next])
                {
                    CKRecord *listRecord = (CKRecord *)[NSKeyedUnarchiver ss_unarchiveSSClassFromData:[result dataForColumn:@"listRecord"]];
                    [listRecords addObject:listRecord];
                }
                
                // Now figure out which ones need to be deleted
                for (CKRecordZoneID *zoneID in deletedZoneIDs)
                {
                    if ([zoneID isSharedFromMe]) continue;
                    
                    for (CKRecord *record in listRecords)
                    {
                        // Test for a match by seeing if the record's zoneID matches
                        // A deleted zoneID.
                        if ([record.recordID.zoneID isEqual:zoneID])
                        {
                            [deletionIDs addObject:record.recordID.recordName];
                        }
                    }
                }
            }
            
            // Now move on to per item deletions, adds and edits
            for (CKRecordID *deletion in deletions)
            {
                [deletionIDs addObject:deletion.recordName];
            }
            
            if (deletionIDs.count > 0)
            {
                [db deleteListsInDB:deletionIDs];
                [db deleteTaxRatesInDB:deletionIDs];
                [db deleteTagsInDB:deletionIDs];
                [db deleteListTagsInDB:deletionIDs];
                [db deleteListItemsInDB:deletionIDs];
            }
            
            // We need to process add or edits in this order: Lists -> Tax Rates -> Tags -> ListTags -> List Items
            for (CKRecord *record in addOrEditedListsRecords)
            {
                BOOL isEdit = [db listExistsForID:record.recordID.recordName];
                if (isEdit)
                {
                    [db updateListInDBWithRecord:record];
                }
                else
                {
                    [db insertListIntoDBWithRecord:record];
                }
            }
            
            for (CKRecord *record in addOrEditedTaxRatesRecords)
            {
                BOOL isEdit = [db taxRateExistsForID:record.recordID.recordName];
                if (isEdit)
                {
                    [db updateTaxRateInfoInDBWithRecord:record];
                }
                else
                {
                    [db insertTaxRateInfoIntoDBWithRecord:record];
                }
            }
            
            for (CKRecord *record in addOrEditedTagsRecords)
            {
                BOOL isEdit = [db tagExistsForID:record.recordID.recordName];
                if (isEdit)
                {
                    [db updateTagInDBWithRecord:record];
                }
                else
                {
                    [db insertTagIntoDBWithRecord:record];
                }
            }
            
            for (CKRecord *record in addOrEditedListTagRecords)
            {
                BOOL isEdit = [db listTagExistsForID:record.recordID.recordName];
                if (isEdit)
                {
                    [db updateListTagInDBWithRecord:record];
                }
                else
                {
                    [db insertListTagIntoDBWithRecord:record];
                }
            }
            
            for (CKRecord *record in addOrEditedListItemsRecords)
            {
                BOOL isEdit = [db listItemExistsForID:record.recordID.recordName];
                if (isEdit)
                {
                    [db updateListItemInDBWithRecord:record];
                }
                else
                {
                    [db insertListItemIntoDBWithRecord:record];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                NSLog(@"Spend Stack - Finished processing changes from server.");
                [[NSNotificationCenter defaultCenter] postNotificationName:SS_NOTE_DATA_CHANGED
                                                                    object:nil];
            });
        }];
    });
}

- (void)ss_database:(SSCloudKitDatabase *)db fetchedChangedRecords:(NSArray<CKRecord *> *)changes
{
    [self ss_database:db fetchedChangedRecords:changes deletions:@[] deletedZones:@[]];
}

- (void)ss_recordsShouldAttemptSyncAgain:(NSArray<__kindof SSObject *> *)addOrEdits deletions:(NSArray<__kindof SSObject *> *)deletions
{
    [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        for (SSObject *obj in addOrEdits)
        {
            BOOL isExisting = [db resyncRecordExistsForID:obj.objCKRecord.recordID.recordName];
            if (isExisting)
            {
                // They don't need to be updated at all, this strictly just tracks the object in other tables by their ID.
                continue;
            }
            else
            {
                [db insertAwaitingSyncObject:obj];
            }
        }
        
        for (SSObject *delete in deletions)
        {
            BOOL isExisting = [db resyncRecordExistsForID:delete.objCKRecord.recordID.recordName];
            if (isExisting)
            {
                // They don't need to be updated at all, this strictly just tracks the object in other tables by their ID.
                continue;
            }
            else
            {
                [db insertAwaitingDeleteSyncObject:delete];
            }
        }
    }];
}

- (void)ss_dataRequeuedSuccessfully:(NSArray<__kindof CKRecord *> *)data
{
    // Drop successful requeues from the table
    [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        // If it's zero, it's offline data that was tagged to upload, but then
        // The user already deleted them before it had a chance to hit the server.
        // So it won't be found in the cache, so remove them.
        if (data.count == 0)
        {
            // sql_AwaitingSyncIDsDeleteAll
            __unused BOOL success = [db deleteAllAwaitingSyncObjects];
            NSLog(@"Spend Stack - Successfully deleted all items awaiting sync: %@", @(success));
        }
        else
        {
            NSMutableArray <NSString *> *syncIDs = [NSMutableArray new];
            
            for (CKRecord *record in data)
            {
                [syncIDs addObject:record.recordID.recordName];
            }
            
            __unused BOOL success = [db deleteAwaitingSyncObjectWithSyncIDs:syncIDs];
            NSLog(@"Spend Stack - Successfully deleted items awaiting sync: %@", @(success));
        }
    }];
}

- (void)ss_recordsWereSavedToCloudKit:(NSArray<CKRecord *> *)records
{
    [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        for (CKRecord *record in records)
        {
            if ([record.recordType isEqualToString:@"SSList"])
            {
                [db updateListRecord:record];
            }
            else if ([record.recordType isEqualToString:@"SSTaxRateInfo"])
            {
                [db updateTaxRateInfoRecord:record];
            }
            else if ([record.recordType isEqualToString:@"SSTag"])
            {
                [db updateTagRecord:record];
            }
            else if ([record.recordType isEqualToString:@"SSListTag"])
            {
                [db updateListTagRecord:record];
            }
            else if ([record.recordType isEqualToString:@"SSListItem"])
            {
                [db updateListItemRecord:record];
            }
        }
    }];
}

#pragma mark - Deletion

- (void)debugDeleteEverything
{
    // CloudKit Data
    [self.ckManager ss_debugDeleteEntireStackWithCompletion:^{
        NSLog(@"Spend Stack - Finished deleting iCloud private data.");
        
        // Database
        [self.readWriteQueue inDatabase:^(FMDatabase *db) {
            __unused BOOL droppedTables = [db executeStatements:sql_DropAllTables];
        }];
        
        // Any defaults set
        [ss_defaults() removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        [ss_defaults() synchronize];
        
        NSLog(@"Spend Stack - Everything is deleted.");
    }];
}

- (void)debugDeleteData
{
    // Database
    [self.readWriteQueue inDatabase:^(FMDatabase *db) {
        __unused BOOL droppedTables = [db executeStatements:sql_DropAllTables];
    }];
    
    [self debugDeleteUserDefaults];
}

- (void)debugDeleteUserDefaults
{
    // Any defaults set
    [ss_defaults() removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [ss_defaults() synchronize];
}

- (void)deleteListLocallyAndFromServer:(SSList *)listToDelete inQueue:(FMDatabaseQueue *)queue completion:(void (^)(FMDatabase * _Nonnull))completion
{
    [queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL success = [db deleteListInDB:listToDelete];
        NSLog(@"Spend Stack - Successfully deleted list: %@", @(success));
        
        BOOL listIsSharedWithMe = [listToDelete listIsSharedWithMe];
        BOOL listIsShared = [listToDelete listIsShared];
        
        if (listIsShared)
        {
            // Fetch the share. Then delete it.
            [[listToDelete.objCKRecord.share ssDatabaseForMe] fetchShareRecord:listToDelete.objCKRecord.share.recordID withCompletion:^(CKShare *shareRecord, NSError *error) {
                NSLog(@"Spend Stack - Fetched share to delete with error: %@", error);
                [[shareRecord ssDatabaseForMe] deleteRootRecordWithID:shareRecord.recordID withCompletion:^(NSError *error) {
                    NSLog(@"Spend Stack - Manually deleted share with error: %@", error);
                    if (listIsSharedWithMe) completion(db);
                }];
            }];
        }
        
        // If it was shared with me, it's not in my DB. The share delete above removed everything.
        if (listIsSharedWithMe == NO)
        {
            [[listToDelete dbForList] saveObjects:@[]
                                   withSavePolicy:0
                                    deleteObjects:@[listToDelete, listToDelete.taxInfo]
                                   withCompletion:^(NSError *possibleError) {
                                       NSLog(@"Spend Stack - Deleted list %@ (Error: %@)", listToDelete, possibleError.localizedDescription);
                                       completion(db);
                                   }];
        }
    }];
}

- (void)presentSharingController:(__kindof SSBaseViewController *)controller forList:(SSList *)list anchorBarItem:(UIBarButtonItem *)barItem sourceView:(UIView *)sourceView
{
    [SSDataStore sharedInstance].ckManager.cloudShareImage = [[UIImage imageNamed:@"AppIconDisplay"] imageWithCornerRadius:SSSpacingMargin];
    [SSDataStore sharedInstance].ckManager.cloudShareTitle = list.name;
    [SSDataStore sharedInstance].ckManager.cloudShareActiveListID = list.dbID;
    [[SSDataStore sharedInstance].ckManager presentShareWithController:controller
                                                                   list:list
                                                          anchorBarItem:barItem
                                                             sourceView:sourceView];
}

#pragma mark - Offline Data Sync

- (void)processAwaitingSyncOperations:(FMDatabase *)database withCompletion:(void (^)(NSError * _Nullable possibleError))completion
{
    
    NSMutableArray <__kindof SSObject *> *awaitingEditObjects = [NSMutableArray new];
    NSMutableArray <__kindof CKRecordID *> *deletionIDs = [NSMutableArray new];
    
    FMResultSet *result = [database executeQuery:sql_AwaitingSyncSelectAll];
    
    while ([result next])
    {
        NSString *syncID = [result stringForColumn:@"syncID"];
        NSString *objType = [result stringForColumn:@"objectType"];
        
        CKRecordID *deletionID = (CKRecordID *)[NSKeyedUnarchiver ss_unarchiveClass:CKRecordID.class fromData:[result dataForColumn:@"deletionRecordID"]];
        
        if (deletionID)
        {
            if ([deletionIDs containsObject:deletionID] == NO)
            {
                [deletionIDs addObject:deletionID];
            }
        }
        else
        {
            FMResultSet *objResult;
            __kindof SSObject *obj;
            
            if ([objType isEqualToString:@"SSList"])
            {
                objResult = [database executeQuery:sql_ListWithTaxRateInfoSelectFromListID, syncID];
                
                while ([objResult next])
                {
                    obj = [[SSList alloc] initWithResultSet:objResult];
                }
            }
            else if ([objType isEqualToString:@"SSTaxRateInfo"])
            {
                objResult = [database executeQuery:sql_TaxRateSelectByTaxRateInfoID, syncID];
                
                while ([objResult next])
                {
                    obj = [[SSTaxRateInfo alloc] initWithResultSet:objResult];
                }
            }
            else if ([objType isEqualToString:@"SSTag"])
            {
                objResult = [database executeQuery:sql_TagSelectByTagID, syncID];
                
                while ([objResult next])
                {
                    obj = [[SSTag alloc] initWithResultSet:objResult];
                }
            }
            else if ([objType isEqualToString:@"SSListTag"])
            {
                objResult = [database executeQuery:sql_ListTagSelectTagsSharedWithMeByListTagID, syncID];
                
                while ([objResult next])
                {
                    obj = [[SSListTag alloc] initWithResultSet:objResult];
                }
            }
            else if ([objType isEqualToString:@"SSListItem"])
            {
                objResult = [database executeQuery:sql_ListItemSelectByListItemID, syncID];
                
                while ([objResult next])
                {
                    obj = [[SSListItem alloc] initWithResultSet:objResult];
                }
            }
            
            // Edit records while offline that were already queued for resync can happen. So don't put
            // Them in twice.
            if (obj && [awaitingEditObjects containsObject:obj] == NO)
            {
                [awaitingEditObjects addObject:obj];
            }
        }
    }

    [self.ckManager.privateDB saveAwaitingSyncObjects:awaitingEditObjects deleteIds:deletionIDs withCompletion:^(NSError *error) {
        NSLog(@"Spend Stack - Awaiting Sync operations finished with error:(%@)", error);
        completion(error);
    }];
}

#pragma mark - Migrate User Defaults

- (void)migrateUserDefaultsIfNeeded
{
    NSUserDefaults *old = [NSUserDefaults standardUserDefaults];
    NSUserDefaults *new = [[NSUserDefaults alloc] initWithSuiteName:SS_APP_GROUP_NAME];
    
    // Key to track if we migrated
    NSString *didMigrateKey = @"ss_didMigrate";
    
    if ([new boolForKey:didMigrateKey] == NO)
    {
        NSDictionary *oldDict = [old dictionaryRepresentation];
        for (NSString *key in oldDict.allKeys)
        {
            [new setValue:oldDict[key] forKey:key];
        }
        
        [new setBool:YES forKey:didMigrateKey];
        [new synchronize];
    }
}

@end
