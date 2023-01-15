//
//  SSCloudKitManager.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/14/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSCloudKitDatabase.h"

static NSString * _Nonnull const SS_Private_User_Lists_Zone = @"ss_privateUserListsZone";
static NSString * _Nonnull const SS_Private_User_Lists_Zone_Subscription_ID = @"ss_privateUserListsSubscription";
static NSString * _Nonnull const SS_CK_MANAGER_HANDLE_CHANGE_NOTIFICATION = @"ss_ckChangeNotificationCameIn";
static NSString * _Nonnull const SS_CK_MANAGER_ACCEPTING_SHARE = @"ss_ckAcceptingShare";
static NSString * _Nonnull const SS_CK_MANAGER_ACCEPTED_SHARE = @"ss_ckAcceptedShare";
static NSString * _Nonnull const SS_CK_MANAGER_CLEAN_FETCH_COMPLETE = @"ss_ckCleanFetchComplete";
static NSString * _Nonnull const SS_CK_MANAGER_CLEAN_FETCH_ERROR = @"ss_ckCleanFetchErred";

@protocol SSCloudKitManagerDelegate <NSObject>

@required
// Called when the user wasn't signed in with iCloud, and later signs in.
- (void)ss_userSignedIntoiCloud;

// Called when the state begins as unreachable, and then a connection is reached.
- (void)ss_deviceEnteredReachableState;

// Called when a database has finished fetches its most recent changes.
- (void)ss_database:(SSCloudKitDatabase * _Nonnull)db fetchedChangedRecords:(NSArray <CKRecord *> * _Nonnull)changes deletions:(NSArray <CKRecordID *> * _Nonnull)deletions deletedZones:(NSArray <CKRecordZoneID *> * _Nonnull)deletedZoneIDs;

// Called after a database fetches a particular set of records.
- (void)ss_database:(SSCloudKitDatabase * _Nonnull)db fetchedChangedRecords:(NSArray <CKRecord *> * _Nonnull)changes;

// Called when objects couldn't save for any reason, and need to try again later.
- (void)ss_recordsShouldAttemptSyncAgain:(NSArray <__kindof SSObject *> * _Nullable)addOrEdits deletions:(NSArray <__kindof SSObject *> * _Nullable)deletions;

// Called when objets were successfully requeued and saved to CloudKit.
- (void)ss_dataRequeuedSuccessfully:(NSArray <__kindof CKRecord *> * _Nullable)data;

// Called when objets were successfully saved to CloudKit to do things like updating the records and their server change tags.
- (void)ss_recordsWereSavedToCloudKit:(NSArray <CKRecord *> * _Nonnull)records;

@end

@interface SSCloudKitManager : NSObject <SSCloudKitDatabaseDelegate, UICloudSharingControllerDelegate>

@property (strong, nonatomic, readonly, nonnull) SSCloudKitDatabase *privateDB;
@property (strong, nonatomic, readonly, nonnull) SSCloudKitDatabase *publicDB;
@property (strong, nonatomic, readonly, nonnull) SSCloudKitDatabase *sharedDB;
@property (strong, nonatomic, readonly, nullable) CKRecordID *currentUserCKID;
@property (nonatomic, assign, readonly) CKAccountStatus accountStatus;
@property (nonatomic, assign, readonly) BOOL dataConnectionIsAvailable;
@property (strong, nonatomic, nullable) NSString *cloudShareTitle;
@property (strong, nonatomic, nullable) UIImage *cloudShareImage;
@property (strong, nonatomic, nullable) NSString *cloudShareActiveListID; 

- (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithDelegate:(id <SSCloudKitManagerDelegate> _Nonnull)delegate;

#pragma mark - Stack Setup

- (void)createPrivateUsersCloudKitStackWithCompletion:(void(^ _Nonnull)(void))completion;

#pragma mark - Fetch

- (void)fetchDatabaseChangesWithNotification:(CKDatabaseNotification * _Nullable)databaseNotification;
- (void)fetchRecords:(NSArray <CKRecord *> * _Nonnull)records inDatabase:(SSCloudKitDatabase * _Nonnull)db withCompletion:(void(^ _Nullable)(NSError * _Nullable))completion;

#pragma mark - Sharing

- (void)presentShareWithController:(__kindof SSBaseViewController * _Nonnull)controller list:(SSList * _Nonnull)list anchorBarItem:(UIBarButtonItem * _Nullable)barItem sourceView:(UIView * _Nullable)soureView;
- (void)acceptShareMetaData:(CKShareMetadata * _Nonnull)metaData withCompletion:(void(^ _Nonnull)(NSError * _Nullable))completion;
- (void)fetchShareMetadata:(CKShare * _Nonnull)share withCompletion:(void(^ _Nullable)(CKShareMetadata * _Nullable, NSError * _Nullable))completion;

#pragma mark - Debugging

- (void)cleanFetchAllData;
- (void)ss_debugDeleteEntireStackWithCompletion:(void(^ _Nonnull)(void))completion;

@end
