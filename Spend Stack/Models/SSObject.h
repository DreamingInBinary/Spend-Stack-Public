//
//  SSObject.h
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>
@class FMResultSet;

static inline BOOL isSafe(id _Nullable val) { return val != nil && ![val isKindOfClass:[NSNull class]]; }
static inline BOOL isSafeAndKindOfClass(id _Nullable val, Class _Nonnull classType) { return val != nil && ![val isKindOfClass:[NSNull class]] && [val isKindOfClass:classType]; }
static inline __kindof NSObject * _Nonnull safeDefaultValue(id _Nullable obj, Class _Nonnull classType) {
    if (obj == nil || [obj isKindOfClass:[NSNull class]])
    {
        if ([obj isKindOfClass:[NSMeasurement class]])
        {
            return [NSMeasurement measurementWithValue:0];
        }
        else
        {
            return [obj new];
        }
    }
    else
    {
        return obj;
    }
}

static NSString * _Nonnull const sql_AwaitingSyncCreateTable = @""
"CREATE TABLE IF NOT EXISTS AwaitingSyncData ( "
"objectSyncID INTEGER PRIMARY KEY AUTOINCREMENT, "
"syncID TEXT NOT NULL, "
"objectType TEXT NOT NULL, "
"deletionRecordID BLOB NULLABLE "
");";

static NSString * _Nonnull const sql_AwaitingSyncSelectAll = @""
"SELECT "
"* "
"FROM "
"AwaitingSyncData;";

static NSString * _Nonnull const sql_AwaitingSyncInsert = @""
"INSERT INTO "
"AwaitingSyncData (syncID, objectType, deletionRecordID) "
"VALUES "
"(?, ?, ?);";

static NSString * _Nonnull const sql_AwaitingSyncIDsDelete = @""
"DELETE FROM AwaitingSyncData "
"WHERE syncID IN ";

static NSString * _Nonnull const sql_AwaitingSyncIDsDeleteAll = @""
"DELETE FROM AwaitingSyncData";

static NSString * _Nonnull const sql_AwaitingSyncCount = @""
"SELECT COUNT(*) as count FROM AwaitingSyncData";

/*
 Use this as a the baseline interface for any new objects that should be persisted and saved to the cloud.
 If an item requires a back reference, have an initWithParentRecordID: initializer.
 Each item is saved, encoded, decoded and sent to the cloud according to its nullability annotation.
 As such, to reduce boilerplate code, default values (if needed) should be set in dictionaryRepresentation.
 
 If you wish to add a new property, as of now there a few steps to take:
 
 1) Be sure to assign the correct nullability annotation to it 
 2) Implement it in NSCoding
 3) Implement it in NSCopying
 4) Add it to isEqual (or hash if needed) for IGListKitDiffing
 5) Return it in dictionaryReprentation: to save it to CloudKit
 6) Set it within updateFieldsFromRecord: if the object is initialized with a CKRecord
 
 */
@interface SSObject : NSObject <NSCopying, NSSecureCoding>

@property (strong, nonatomic, nonnull) CKRecord *objCKRecord;
@property (strong, nonatomic, readonly, nonnull) NSString *recordType;
@property (strong, nonatomic, readonly, nonnull) NSString *dbID;

- (NSDictionary * _Nonnull)dictionaryRepresentation;
- (void)updateRecord:(CKRecord * _Nonnull)record fromDictionary:(NSDictionary * _Nonnull)dictionaryRepresentation;
- (NSData * _Nullable)dataForRecord;
- (void)setObjectForNoPersistencyOrSync;
- (void)initializeNewRecordsForRedoWithZoneID:(CKRecordZoneID * _Nullable)zoneID;

- (instancetype _Nonnull)initForTesting;
- (instancetype _Nonnull)initWithResultSet:(FMResultSet * _Nonnull)result;
- (instancetype _Nonnull)initWithZoneID:(CKRecordZoneID * _Nonnull)zoneID;

@end
