//
//  SSCloudKitManager.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/14/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSCloudKitManager.h"
#import "Reachability.h"
#import "SSCloudKitDatabase.h"
#import "CKShare+Utils.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface SSCloudKitManager()

@property (strong, nonatomic, readwrite, nonnull) SSCloudKitDatabase *privateDB;
@property (strong, nonatomic, readwrite, nonnull) SSCloudKitDatabase *publicDB;
@property (strong, nonatomic, readwrite, nonnull) SSCloudKitDatabase *sharedDB;
@property (strong, nonatomic, readwrite, nullable) CKRecordID *currentUserCKID;
@property (strong, nonatomic, nonnull) Reachability *reachability;
@property (nonatomic, assign, readwrite) CKAccountStatus accountStatus;
@property (nonatomic, weak, nullable) id <SSCloudKitManagerDelegate> delegate;
@property (strong, nonatomic, nonnull) NSOperationQueue *operationQueue;
@property (atomic) dispatch_group_t group;

@end

@implementation SSCloudKitManager

#pragma mark - Initializer

- (instancetype)initWithDelegate:(id<SSCloudKitManagerDelegate>)delegate
{
    self = [super init];
    
    if (self)
    {
        self.privateDB = [[SSCloudKitDatabase alloc] initWithDatabase:[CKContainer defaultContainer].privateCloudDatabase
                                                       customZoneName:SS_Private_User_Lists_Zone
                                                     subscriptionName:SS_Private_User_Lists_Zone_Subscription_ID
                                                             delegate:self];
        self.publicDB = [[SSCloudKitDatabase alloc] initWithDatabase:[CKContainer defaultContainer].publicCloudDatabase
                                                      customZoneName:nil
                                                    subscriptionName:nil
                                                            delegate:self];
        self.sharedDB = [[SSCloudKitDatabase alloc] initWithDatabase:[CKContainer defaultContainer].sharedCloudDatabase
                                                       customZoneName:nil
                                                     subscriptionName:nil
                                                            delegate:self];
        
        self.delegate = delegate;
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleReachabilityChangedNotification:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkAccountStatus)
                                                     name:CKAccountChangedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processChangeNotification:)
                                                     name:SS_CK_MANAGER_HANDLE_CHANGE_NOTIFICATION
                                                   object:nil];
        
        self.operationQueue = [NSOperationQueue new];
        [self checkAccountStatus];
    }
    
    return self;
}

#pragma mark - Account Check

- (void)checkAccountStatus
{
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^ (CKAccountStatus status, NSError *error) {
        self.accountStatus = status;
        
        if (self.accountStatus == CKAccountStatusAvailable)
        {
            NSLog(@"Spend Stack - User is signed into iCloud. Fetching user ID.");
            [[CKContainer defaultContainer] fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
                if (error != nil)
                {
                    NSLog(@"Spend Stack - Unable to fetch User ID: %@", error.localizedDescription);
                }
                else if (recordID)
                {
                    NSLog(@"Spend Stack - Fetched and set User ID: %@", recordID);
                    self.currentUserCKID = recordID;
                }
            }];
            
            [self.delegate ss_userSignedIntoiCloud];
        }
        else if (error)
        {
            NSLog(@"Spend Stack - Fetching account status - %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"Spend Stack - User isn't signed into iCloud: %ld", (long)self.accountStatus);
        }
    }];
}

#pragma mark - Cloudkit Database Delegate

- (void)dataShouldRequeueForSync:(NSArray <__kindof SSObject *> *)addOrEdits deletions:(NSArray <__kindof SSObject *> *)deletions
{
    [self.delegate ss_recordsShouldAttemptSyncAgain:addOrEdits deletions:deletions];
}

- (void)dataRequeuedSuccessfully:(NSArray<__kindof CKRecord *> *)data
{
    [self.delegate ss_dataRequeuedSuccessfully:data];
}

- (void)recordsSuccessfullySaved:(NSArray<__kindof CKRecord *> *)data
{
    [self.delegate ss_recordsWereSavedToCloudKit:data];
}

- (void)handleRecordMergeConflict:(CKRecord *)updateRecord database:(SSCloudKitDatabase *)database
{
    [self.delegate ss_database:database fetchedChangedRecords:@[updateRecord] deletions:@[] deletedZones:@[]];
}

- (BOOL)userIsSignedIn
{
    return self.accountStatus == CKAccountStatusAvailable;
}

- (BOOL)dataIsAvailable
{
    return self.dataConnectionIsAvailable;
}

#pragma mark - Reachability

- (BOOL)dataConnectionIsAvailable
{
    return [self.reachability currentReachabilityStatus] != NotReachable;
}

- (void)handleReachabilityChangedNotification:(NSNotification *)notification
{
    Reachability *newReachabilityData = notification.object;
    if ([newReachabilityData isKindOfClass:[Reachability class]] == NO) return;
    
    if (newReachabilityData.currentReachabilityStatus != NotReachable)
    {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.delegate ss_deviceEnteredReachableState];
        });
    }
}

#pragma mark - Networking Stack

- (void)createPrivateUsersCloudKitStackWithCompletion:(void(^)(void))completion
{
    if (self.privateDB.hasSetupDatabaseStack && self.sharedDB.hasSetupDatabaseStack)
    {
        NSLog(@"Spend Stack - CloudKit schemas already in place.");
        completion();
        return;
    }
    
    // Check if zone is created locally
    // If not, fetch zones from server
    // If it doesn't exist, create custom zone
    
    // Check if subscription was made locally
    // If it doesn't exist, create subscription to custom zone
    NSMutableArray <NSOperation *> *stackSetupOperations = [NSMutableArray new];
    
    CKOperation *fetchZoneOp = [self.privateDB fetchRecordZonesOperation];
    CKOperation *createZoneOp = [self.privateDB createZoneOperation];
    [createZoneOp addDependency:fetchZoneOp];
    CKOperation *createDatabaseSubscription = [self.privateDB createDatabaseSubscriptionOperation];
    [createDatabaseSubscription addDependency:createZoneOp];
    CKOperation *createSharedDatabaseSubscription = [self.sharedDB createDatabaseSubscriptionOperation];
    [createSharedDatabaseSubscription addDependency:createDatabaseSubscription];

    [stackSetupOperations addObjectsFromArray:@[fetchZoneOp,
                                                createZoneOp,
                                                createDatabaseSubscription,
                                                createSharedDatabaseSubscription]];
    
    NSBlockOperation *completionBlockOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Spend Stack - Private DB and shared DB stack configured.");
        completion();
    }];
    [completionBlockOp addDependency:stackSetupOperations.lastObject];
    [stackSetupOperations addObject:completionBlockOp];
    
    [self.operationQueue addOperations:stackSetupOperations waitUntilFinished:NO];
}

- (void)ss_debugDeleteEntireStackWithCompletion:(void (^)(void))completion
{
    NSArray <NSOperation *> *stackTeardownOperations;
    
    CKOperation *deleteZoneOp = [self.privateDB deleteZoneOperation];
    CKOperation *deleteSubscriptionOp = [self.privateDB deleteZoneSubcriptionOperation];
    CKOperation *deleteShareZoneOp = [self.sharedDB deleteZoneOperation];
    CKOperation *deleteSharedSubscriptionOp = [self.sharedDB deleteZoneSubcriptionOperation];
    
    NSBlockOperation *completionBlockOp = [NSBlockOperation blockOperationWithBlock:^{
        completion();
    }];
    
    [deleteSubscriptionOp addDependency:deleteZoneOp];
    [deleteShareZoneOp addDependency:deleteSubscriptionOp];
    [deleteSharedSubscriptionOp addDependency:deleteShareZoneOp];
    [completionBlockOp addDependency:deleteSharedSubscriptionOp];
    
    stackTeardownOperations = @[deleteZoneOp, deleteSubscriptionOp, deleteShareZoneOp, deleteSharedSubscriptionOp, completionBlockOp];
    [self.operationQueue addOperations:stackTeardownOperations waitUntilFinished:NO];
}

#pragma mark - Change Notification and Zone Fetch Handling

- (void)processChangeNotification:(NSNotification *)note
{
    CKNotification *changeToken = note.object;
    
    if ([changeToken isKindOfClass:[CKNotification class]] == NO)
    {
        return;
    }
    
    if (changeToken.notificationType == CKNotificationTypeRecordZone)
    {
        CKRecordZoneNotification *zoneNotification = (CKRecordZoneNotification *)changeToken;
        
        if ([zoneNotification.subscriptionID isEqualToString:SS_Private_User_Lists_Zone_Subscription_ID])
        {
            [self fetchPrivateUsersZoneChangesWithNotification:zoneNotification];
        }
    }
    
    if (changeToken.notificationType == CKNotificationTypeDatabase)
    {
        CKDatabaseNotification *databaseNotification = (CKDatabaseNotification *)changeToken;
        [self fetchDatabaseChangesWithNotification:databaseNotification];
    }
}

- (void)fetchDatabaseChangesWithNotification:(CKDatabaseNotification *)databaseNotification
{
    if (self.privateDB.hasSetupDatabaseStack == NO)
    {
        NSLog(@"Spend Stack - Private DB stack not configured. Skipping network call.");
        dispatch_async(dispatch_get_main_queue(), ^ {
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_CK_MANAGER_CLEAN_FETCH_ERROR object:nil];
        });
        return;
    }
    
    // Now fetch from private and shared db
    __weak typeof(self)weakSelf = self;
    
    if (databaseNotification.databaseScope == CKDatabaseScopePublic)
    {
        NSAssert(NO, @"Spend Stack - Received a change token for data that's in the public database.");
    }
    
    if (databaseNotification.databaseScope == CKDatabaseScopePrivate)
    {
        [self.privateDB fetchDatabaseChanges:databaseNotification withCompletion:^(NSArray<CKRecord *> * _Nonnull changedRecords, NSArray<CKRecordID *> * _Nonnull deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
            [weakSelf.delegate ss_database:weakSelf.privateDB
                     fetchedChangedRecords:changedRecords
                                 deletions:deletedRecords
                              deletedZones:deletedZoneIDs];
        }];
    }
    
    if (databaseNotification.databaseScope == CKDatabaseScopeShared)
    {
        [self.sharedDB fetchDatabaseChanges:databaseNotification withCompletion:^(NSArray<CKRecord *> * _Nonnull changedRecords, NSArray<CKRecordID *> * _Nonnull deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
            [weakSelf.delegate ss_database:weakSelf.privateDB
                     fetchedChangedRecords:changedRecords
                                 deletions:deletedRecords
                              deletedZones:deletedZoneIDs];
        }];
    }
    
    // Clean fetch
    if (databaseNotification == nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (!self.group) self.group = dispatch_group_create();
            
            dispatch_group_enter(self.group);
            [self.privateDB fetchDatabaseChanges:databaseNotification withCompletion:^(NSArray<CKRecord *> * _Nonnull changedRecords, NSArray<CKRecordID *> * _Nonnull deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
                [weakSelf.delegate ss_database:weakSelf.privateDB
                         fetchedChangedRecords:changedRecords
                                     deletions:deletedRecords
                                  deletedZones:deletedZoneIDs];
                dispatch_group_leave(self.group);
            }];
            
            dispatch_group_enter(self.group);
            [self.sharedDB fetchDatabaseChanges:databaseNotification withCompletion:^(NSArray<CKRecord *> * _Nonnull changedRecords, NSArray<CKRecordID *> * _Nonnull deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
                [weakSelf.delegate ss_database:weakSelf.sharedDB
                         fetchedChangedRecords:changedRecords
                                     deletions:deletedRecords
                                  deletedZones:deletedZoneIDs];
                dispatch_group_leave(self.group);
            }];
            
            // All fetch operations completed
            dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SS_CK_MANAGER_CLEAN_FETCH_COMPLETE object:nil];
                self.group = nil;
            });
        });
    }
}

- (void)fetchPrivateUsersZoneChangesWithNotification:(CKRecordZoneNotification *)zoneNotification
{
    if (self.privateDB.hasSetupDatabaseStack == NO)
    {
        NSLog(@"Spend Stack - Private DB stack not configured. Skipping network call.");
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    
    // Now fetch from the db
    if (zoneNotification.databaseScope == CKDatabaseScopeShared)
    {
        [self.sharedDB fetchZoneChanges:zoneNotification zoneIDs:nil deletedZones:@[] withCompletion:^(NSArray<CKRecord *> * _Nonnull changedRecords, NSArray<CKRecordID *> * _Nonnull deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
            [weakSelf.delegate ss_database:weakSelf.privateDB
                     fetchedChangedRecords:changedRecords
                                 deletions:deletedRecords
                              deletedZones:deletedZoneIDs];
        }];
    }
    else
    {
        [self.privateDB fetchZoneChanges:zoneNotification zoneIDs:nil deletedZones:@[] withCompletion:^(NSArray<CKRecord *> *changedRecords, NSArray<CKRecordID *> *deletedRecords, NSArray <CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
            [weakSelf.delegate ss_database:weakSelf.privateDB
                     fetchedChangedRecords:changedRecords
                                 deletions:deletedRecords
                              deletedZones:deletedZoneIDs];
        }];
    }
}

- (void)fetchRecords:(NSArray<CKRecord *> *)records inDatabase:(SSCloudKitDatabase *)db withCompletion:(void (^)(NSError * _Nullable))completion
{
    if (db.hasSetupDatabaseStack == NO)
    {
        NSLog(@"Spend Stack - %@ stack not configured. Skipping network call.", db);
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    
    // Now fetch from the db
    [db forceFetchRecords:records withCompletion:^(NSArray<CKRecord *> *edits, NSError *error) {
        [weakSelf.delegate ss_database:db fetchedChangedRecords:edits];
        completion(error);
    }];
}

- (void)cleanFetchAllData
{
    [self.privateDB resetServerChangeToken];
    [self.sharedDB resetServerChangeToken];
    [self fetchDatabaseChangesWithNotification:nil];
}

#pragma mark - Sharing

- (void)presentShareWithController:(__kindof SSBaseViewController *)controller list:(SSList *)list anchorBarItem:(UIBarButtonItem *)barItem sourceView:(UIView *)soureView
{
    if (self.accountStatus != CKAccountStatusAvailable)
    {
        [controller showAlertControllerWithTitle:ss_Localized(@"advList.vc.signIn")
                                         message:ss_Localized(@"advList.vc.singInExplain")];
        return;
    }
    else if (controller.connectionIsAvailable == NO)
    {
        [controller showAlertControllerWithTitle:ss_Localized(@"ck.manager.noData")
                                         message:ss_Localized(@"ck.manager.noDataPrompt")];
        return;
    }
    
    // Has it been shared already?
    if (list.objCKRecord.share)
    {
        // Fetch the share (this should be privateDB for owner and sharedDB for participants)
        [[list.objCKRecord.share ssDatabaseForMe] fetchShareRecord:list.objCKRecord.share.recordID withCompletion:^(CKShare *shareRecord, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                // Dismissed in the middle of fetching the share
                if (controller == nil)
                {
                    return;
                }
                else if (error && error.code == CKErrorUnknownItem)
                {
                    // The share has been deleted but the cache wasn't updated to reflect it.
                    // Trigger a refetch.
                    [self fetchDatabaseChangesWithNotification:nil];
                    
                    NSString *errorText = [NSString stringWithFormat:@"This list is no longer being shared with anyone. If you'd like to share it again, please tap the share icon on the top right."];
                    [controller showAlertControllerWithTitle:@"Error Fetching Shared List"
                                                     message:errorText];
                    return;
                }
                else if (error)
                {
                    NSString *errorText = [NSString stringWithFormat:@"We encountered an issue retrieving the shared list. Please contact support with this error if this continues:\n\n%@", error.localizedDescription];
                    [controller showAlertControllerWithTitle:@"Error Fetching Shared List"
                                                     message:errorText];
                    return;
                }
                else if (shareRecord == nil)
                {
                    // Trigger a refetch.
                    [self fetchDatabaseChangesWithNotification:nil];
                    
                    [controller showAlertControllerWithTitle:@"Error Fetching Shared List"
                                                     message:@"We encountered an issue retrieving the shared list. Please contact support if this continues."];
                    return;
                }
                
                UICloudSharingController *shareController = [[UICloudSharingController alloc] initWithShare:shareRecord container:[CKContainer defaultContainer]];
                if (barItem) shareController.popoverPresentationController.barButtonItem = barItem;
                if (soureView) shareController.popoverPresentationController.sourceView = soureView;
                shareController.delegate = self;
                [controller presentViewController:shareController animated:YES completion:nil];
            });
        }];
    }
    else
    {
        UICloudSharingController *shareController = [[UICloudSharingController alloc] initWithPreparationHandler:^(UICloudSharingController * controller, void (^preparationCompletionHandler)(CKShare *share, CKContainer *container, NSError *error)) {
            // Create the share with the base record
            [self shareRootRecord:list completion:preparationCompletionHandler];
        }];
        
        if (barItem) shareController.popoverPresentationController.barButtonItem = barItem;
        if (soureView) shareController.popoverPresentationController.sourceView = soureView;
        shareController.delegate = self;
        [controller presentViewController:shareController animated:YES completion:nil];
    }
}

- (void)acceptShareMetaData:(CKShareMetadata *)metaData withCompletion:(void (^)(NSError * _Nullable))completion
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_CK_MANAGER_ACCEPTING_SHARE object:0];
    
    __weak typeof(self) weakSelf = self;
    CKAcceptSharesOperation *acceptShareOp = [[CKAcceptSharesOperation alloc] initWithShareMetadatas:@[metaData]];
    acceptShareOp.qualityOfService = NSQualityOfServiceUserInitiated;
    acceptShareOp.acceptSharesCompletionBlock = ^(NSError *operationError) {
        [self.sharedDB fetchDatabaseChanges:nil withCompletion:^(NSArray<CKRecord *> * _Nonnull changedRecords, NSArray<CKRecordID *> * _Nonnull deletedRecords, NSArray<CKRecordZoneID *> * _Nonnull deletedZoneIDs) {
            [weakSelf.delegate ss_database:weakSelf.privateDB
                     fetchedChangedRecords:changedRecords
                                 deletions:deletedRecords
                              deletedZones:deletedZoneIDs];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SS_CK_MANAGER_ACCEPTED_SHARE
                object:metaData.rootRecordID.recordName];
            });
        }];
        completion(operationError);
    };
    
    [[CKContainer defaultContainer] addOperation:acceptShareOp];
}

- (void)shareRootRecord:(SSList *)rootRecordList completion:(void (^)(CKShare * share, CKContainer * container, NSError * error))completion
{
    [rootRecordList updateRecord:rootRecordList.objCKRecord fromDictionary:[rootRecordList dictionaryRepresentation]];
    
    CKShare *shareRecord = [[CKShare alloc] initWithRootRecord:rootRecordList.objCKRecord];
    shareRecord[CKShareTitleKey] = self.cloudShareTitle;
    shareRecord[CKShareThumbnailImageDataKey] = UIImagePNGRepresentation(self.cloudShareImage);
    shareRecord.publicPermission = CKShareParticipantPermissionReadWrite;
    
    [self.privateDB saveRootRecord:rootRecordList share:shareRecord withCompletion:^(NSError *error) {
        completion(shareRecord, [CKContainer defaultContainer], error);
    }];
}

- (void)fetchShareMetadata:(CKShare *)share withCompletion:(void (^)(CKShareMetadata * _Nullable, NSError * _Nullable))completion
{
    CKFetchShareMetadataOperation *fetchOp = [[CKFetchShareMetadataOperation alloc] initWithShareURLs:@[share.URL]];
    fetchOp.qualityOfService = NSQualityOfServiceUserInitiated;
    fetchOp.perShareMetadataBlock = ^(NSURL * _Nonnull shareURL, CKShareMetadata * _Nullable shareMetadata, NSError * _Nullable error) {
        // This assumes I am only fetching one share currently
        completion(shareMetadata, error);
    };
    fetchOp.fetchShareMetadataCompletionBlock = ^(NSError * _Nullable operationError) {
        // Currently unused, but if I fetch multiple shares I might need this
    };
    
    [[CKContainer defaultContainer] addOperation:fetchOp];
}


#pragma mark - Share Controller Delegate

- (NSString *)itemTitleForCloudSharingController:(UICloudSharingController *)csc
{
    return self.cloudShareTitle;
}

- (NSData *)itemThumbnailDataForCloudSharingController:(UICloudSharingController *)csc
{
    return UIImagePNGRepresentation(self.cloudShareImage);
}

- (NSString *)itemTypeForCloudSharingController:(UICloudSharingController *)csc
{
    return (NSString *)kUTTypeContent;
}

- (void)cloudSharingController:(UICloudSharingController *)csc failedToSaveShareWithError:(NSError *)error
{
    // Fetch the root record from server and upate the rootRecord sliently.
    // .fetchChanges doesn't return anything here, so fetch with the recordID.
    NSLog(@"Spend Stack - Failed to share record");
    NSString *errorText = [NSString stringWithFormat:@"We ran into an issue trying to share yout list. Please contact support with the following error if this persists:\n\n%@", error.localizedDescription];
    UIViewController *rootVC = csc.view.window.rootViewController;
    [rootVC showAlertControllerWithTitle:@"Unable to Share List"
                                 message:errorText];
}

- (void)cloudSharingControllerDidSaveShare:(UICloudSharingController *)csc
{
    // When a list is shared successfully, this method is called. The CKShare should have been created,
    // And the whole share hierarchy should have been updated in server side. So fetch the changes and
    // Update the database.
    NSLog(@"Spend Stack - Created a share and updating cache from the server.");
    [self fetchDatabaseChangesWithNotification:nil];
}

- (void)cloudSharingControllerDidStopSharing:(UICloudSharingController *)csc
{
    // When a share is stopped and this method is called, the CKShare record should have been removed and
    // The root record should have been updated server side. So fetch the changes and update
    // The database.
    // Stop sharing can happen on two scenarios: an owner stops a share or a participant removes self from a share.
    // In the former case, no visual things will be changed in the owner side (privateDB).
    // In the latter case, the share will disappear from the sharedDB.
    // If the share is the only item in the current zone, the zone should also be removed.
    //
    // Fetching immediately here may not get all the changes because the server side needs a while to index.
    NSLog(@"Spend Stack - A share was stopped, updating cache from the server. This list was %@", [csc.share isSharedFromMe] ? @"shared by me." : @"shared with me.");

    // If we left it manually on this actual device, no change token is sent. Delete it, other devices get a change
    // From the server to do this.
    if ([csc.share isSharedWithMe] &&
        self.cloudShareActiveListID &&
        [self.cloudShareActiveListID isEqualToString:@""] == NO)
    {
        // We'll also need to delete it locally if this was a share we left
        [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase *db) {
            BOOL success = [db deleteListsInDB:@[self.cloudShareActiveListID]];
            NSLog(@"Spend Stack - Successfully deleted list: %@", @(success));
            self.cloudShareActiveListID = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[NSNotificationCenter defaultCenter] postNotificationName:SS_NOTE_DATA_CHANGED
                                                                    object:nil];
            });
        }];
    }
    else
    {
        // Update the list if needed
        [self fetchDatabaseChangesWithNotification:nil];
    }
}

@end
