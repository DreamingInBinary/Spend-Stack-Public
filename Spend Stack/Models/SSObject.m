//
//  SSObject.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/13/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSObject.h"
#import "SSCloudKitManager.h"
#import <CloudKit/CloudKit.h>

@interface SSObject()

@property (strong, nonatomic, readwrite, nonnull) NSString *dbID;

@end

@implementation SSObject

#pragma mark - Custom Getters

- (NSString *)recordType
{
    return NSStringFromClass([self class]);
}

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:[NSUUID UUID].UUIDString
                                                               zoneID:[self customRecordZone]];
        self.objCKRecord = [[CKRecord alloc] initWithRecordType:self.recordType recordID:recordID];
        self.dbID = recordID.recordName;
    }
    
    return self;
}

- (instancetype)initForTesting
{
    self = [super init];
    
    if (self)
    {
        self.dbID = [NSUUID UUID].UUIDString;
    }
    
    return self;
}

- (instancetype)initWithZoneID:(CKRecordZoneID *)zoneID
{
    self = [super init];
    
    if (self)
    {
        self.objCKRecord = [[CKRecord alloc] initWithRecordType:self.recordType zoneID:zoneID];
        self.dbID = self.objCKRecord.recordID.recordName;
    }
    
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)result
{
    self = [super init];
    
    if (self)
    {
        self.dbID = [result stringForColumn:[self dbIDKey]];
        self.objCKRecord = (CKRecord *)[NSKeyedUnarchiver ss_unarchiveClass:CKRecord.class fromData:[result dataForColumn:[self recordKey]]];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.dbID = [aDecoder decodeObjectForKey:[self dbIDKey]];
        self.objCKRecord = [aDecoder decodeObjectForKey:[self recordKey]];
    }
    
    return self;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dbID forKey:[self dbIDKey]];
    [aCoder encodeObject:self.objCKRecord forKey:[self recordKey]];
}

- (CKRecordZoneID *)customRecordZone
{
    CKRecordZone *customZone = [[CKRecordZone alloc] initWithZoneName:SS_Private_User_Lists_Zone];
    return customZone.zoneID;
}

- (CKRecordZoneID *)sharedRecordZone
{
    CKRecordZone *customZone = [[CKRecordZone alloc] initWithZoneName:@""];
    return customZone.zoneID;
}

- (NSString *)dbIDKey
{
    NSString *key = @"";
    
    if ([self.recordType isEqualToString:@"SSList"])
    {
        key = @"listID";
    }
    else if ([self.recordType isEqualToString:@"SSTaxRateInfo"])
    {
        key = @"taxRateInfoID";
    }
    else if ([self.recordType isEqualToString:@"SSTag"])
    {
        key = @"tagID";
    }
    else if ([self.recordType isEqualToString:@"SSListTag"])
    {
        key = @"listTagID";
    }
    else if ([self.recordType isEqualToString:@"SSListItem"])
    {
        key = @"listItemID";
    }
    
    NSAssert([key isEqualToString:@""] == NO, @"Spend Stack - DB ID was an empty string.");
    return key;
}

- (NSString *)recordKey
{
    NSString *key = @"";
    
    if ([self.recordType isEqualToString:@"SSList"])
    {
        key = @"listRecord";
    }
    else if ([self.recordType isEqualToString:@"SSTaxRateInfo"])
    {
        key = @"taxInfoRecord";
    }
    else if ([self.recordType isEqualToString:@"SSTag"])
    {
        key = @"tagRecord";
    }
    else if ([self.recordType isEqualToString:@"SSListTag"])
    {
        key = @"listTagRecord";
    }
    else if ([self.recordType isEqualToString:@"SSListItem"])
    {
        key = @"listItemRecord";
    }
    
    NSAssert([key isEqualToString:@""] == NO, @"Spend Stack - Record key was an empty string.");
    return key;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSObject *newObject = [[[self class] allocWithZone:zone] init];
    
    if (newObject)
    {
        newObject.dbID = [_dbID copyWithZone:zone];
        newObject.objCKRecord = [_objCKRecord copyWithZone:zone];
    }
    
    return newObject;
}

#pragma mark - Public Methods

- (NSDictionary *)dictionaryRepresentation
{
    return @{};
}

- (void)updateRecord:(CKRecord *)record fromDictionary:(NSDictionary *)dictionaryRepresentation
{
    for (NSString *propertyKey in dictionaryRepresentation.allKeys)
    {
        if ([dictionaryRepresentation[propertyKey] isKindOfClass:[NSNull class]])
        {
            record[propertyKey] = nil;
        }
        else
        {
            record[propertyKey] = dictionaryRepresentation[propertyKey];
        }
    }
}

- (NSData *)dataForRecord
{
    return [NSKeyedArchiver ss_secureArchive:self.objCKRecord];
}

- (void)setObjectForNoPersistencyOrSync
{
    self.dbID = @"";
}

// Typically used for undo actions. When you delete a record, you can't then save
// That object with a record that was deleted. You need a new one.
- (void)initializeNewRecordsForRedoWithZoneID:(CKRecordZoneID *)zoneID
{
    // Is it part of a share, or just my own private zone?
    CKRecordZoneID *recycledZoneID = zoneID ? zoneID : [self customRecordZone];
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:[NSUUID UUID].UUIDString
                                                           zoneID:recycledZoneID];
    self.objCKRecord = [[CKRecord alloc] initWithRecordType:self.recordType recordID:recordID];
    self.dbID = recordID.recordName;
}

@end
