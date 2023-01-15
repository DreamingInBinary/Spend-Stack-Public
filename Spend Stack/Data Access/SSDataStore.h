//
//  SSDataStore.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/15/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SSCloudKitManager;
@class FMDatabaseQueue;

static NSString * _Nonnull const sql_DropAllTables = @"drop table lists; drop table tags; drop table ListTaxRateInfo; drop table listitems; drop table listtags;";

@interface SSDataStore : NSObject

@property (strong, nonatomic, readonly, nonnull) SSCloudKitManager *ckManager;
@property (strong, nonatomic, readonly, nonnull) FMDatabaseQueue *readWriteQueue;
+ (instancetype _Nonnull)sharedInstance;
+ (NSString * _Nonnull)databaseFilePath;

- (NSArray <SSList *> * _Nullable)queryAllLists;
- (NSArray <SSTag *> * _Nullable)queryAllMasterTags;
- (NSArray <SSListTag *> * _Nullable)queryListTagsSharedToMeForListID:(NSString * _Nonnull)dbID;
- (SSList * _Nullable)queryListByID:(NSString * _Nullable)dbID;

- (void)createDatabaseSchemaIfNeeded;
- (void)debugDeleteEverything; // Deletes iCloud user zones too and local defaults keys
- (void)debugDeleteData; // Just deletes cache and all records in iCloud
- (void)debugDeleteUserDefaults;
- (void)deleteListLocallyAndFromServer:(SSList * _Nonnull)listToDelete inQueue:(FMDatabaseQueue * _Nonnull)queue completion:(void (^ _Nonnull)(FMDatabase *_Nonnull db))completion;
- (void)presentSharingController:(__kindof SSBaseViewController * _Nonnull)controller forList:(SSList * _Nonnull)list anchorBarItem:(UIBarButtonItem * _Nullable)barItem sourceView:(UIView * _Nullable)sourceView;

@end
