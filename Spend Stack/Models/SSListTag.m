//
//  SSListTag.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListTag.h"

@interface SSListTag()

@property (strong, nonatomic, readwrite, nonnull) NSString *fkListID;
@property (strong, nonatomic, readwrite, nonnull) NSString *fkTagID;
@property (strong, nonatomic, readwrite, nonnull) CKReference *listReference;
@property (strong, nonatomic, readwrite, nonnull) CKReference *listTagReference;

@end

@implementation SSListTag

#pragma mark - Initializers

- (instancetype)initWithParentListRecordID:(CKRecordID *)parentListRecordID masterTag:(SSTag *)masterTag
{
    // Due to shares, we need to ensure we save either in our private zone or the shared one
    self = [super initWithZoneID:parentListRecordID.zoneID];
    
    if (self)
    {
        self.name = masterTag.name;
        self.color = masterTag.color;
        self.orderingIndex = masterTag.orderingIndex;
        self.fkListID = parentListRecordID.recordName;
        self.fkTagID = masterTag.dbID;
        self.listReference = [[CKReference alloc] initWithRecordID:parentListRecordID
                                                            action:CKReferenceActionDeleteSelf];
        self.listTagReference = [[CKReference alloc] initWithRecordID:masterTag.objCKRecord.recordID
                                                               action:CKReferenceActionDeleteSelf];
        [self.objCKRecord setParent:[[CKReference alloc] initWithRecordID:parentListRecordID
                                                                   action:CKReferenceActionNone]];
    }
    
    return self;
}

- (instancetype)initForMiscTag
{
    self = [super init];
    
    if (self)
    {
        self.name = @"Miscellaneous";
        self.color = @"clear";
        self.orderingIndex = @(-100);
        [self setObjectForNoPersistencyOrSync];
    }
    
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)result
{
    self = [super initWithResultSet:result];
    
    if (self)
    {
        self.color = [result stringForColumn:@"color"];
        self.name = [result stringForColumn:@"name"];
        self.orderingIndex = @([result intForColumn:@"listTagOrderingIndex"]);
        self.fkListID = [result stringForColumn:@"listTagListID"];
        self.fkTagID = [result stringForColumn:@"listTagMasterTagID"];
        NSAssert(self.fkListID, @"Spend Stack - Cannot have a List Tag without a list ID.");
        self.listReference = (CKReference *)[NSKeyedUnarchiver ss_unarchiveClass:CKReference.class fromData:[result dataForColumn:@"listReference"]];
        self.listTagReference = (CKReference *)[NSKeyedUnarchiver ss_unarchiveClass:CKReference.class fromData:[result dataForColumn:@"listTagReference"]];
        NSAssert(self.objCKRecord != nil, @"Spend Stack - Query resulted in no record ID for a list tag.");
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.color = [aDecoder decodeObjectForKey:@"color"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.orderingIndex = [aDecoder decodeObjectForKey:@"listTagOrderingIndex"];
        self.fkListID = [aDecoder decodeObjectForKey:@"listID"];
        self.fkTagID = [aDecoder decodeObjectForKey:@"tagID"];
        self.listReference = [aDecoder decodeObjectForKey:@"listReference"];
        self.listTagReference = [aDecoder decodeObjectForKey:@"listTagReference"];
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
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.color forKey:@"color"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.orderingIndex forKey:@"listTagOrderingIndex"];
    [aCoder encodeObject:self.fkListID forKey:@"listID"];
    [aCoder encodeObject:self.fkTagID forKey:@"tagID"];
    [aCoder encodeObject:self.listReference forKey:@"listReference"];
    [aCoder encodeObject:self.listTagReference forKey:@"listTagReference"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSListTag *newTag = [super copyWithZone:zone];
    
    if (newTag)
    {
        newTag.color = [_color copyWithZone:zone];
        newTag.name = [_name copyWithZone:zone];
        newTag.orderingIndex = [_orderingIndex copyWithZone:zone];
        newTag.fkListID = [_fkListID copyWithZone:zone];
        newTag.fkTagID = [_fkTagID copyWithZone:zone];
        newTag.listReference = [_listReference copyWithZone:zone];
        newTag.listTagReference = [_listTagReference copyWithZone:zone];
    }
    
    return newTag;
}

#pragma mark - Overrides

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *guranteedData = @{@"color":self.color,
                                    @"name":self.name,
                                    @"listTagOrderingIndex":self.orderingIndex,
                                    @"listReference":self.listReference,
                                    @"listTagReference":self.listTagReference
                                    };
    NSMutableDictionary *data = [[super dictionaryRepresentation] mutableCopy];
    [data addEntriesFromDictionary:guranteedData];
    
    return guranteedData;
}

#pragma mark - Diffing

- (id<NSObject>)diffIdentifier
{
    return self.dbID;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object
{
    return [self isEqual:object];
}

- (NSUInteger)hash
{
    return [self.dbID hash];
}

- (BOOL)isEqual:(SSListTag *)otherTag
{
    if (self == otherTag)
    {
        return YES;
    }
    
    if (otherTag == nil || ![otherTag isKindOfClass:[SSListTag class]])
    {
        return NO;
    }
    
    return self.orderingIndex.integerValue == otherTag.orderingIndex.integerValue &&
    (self.dbID == otherTag.dbID || [self.dbID isEqualToString:otherTag.dbID]) &&
    (self.name == otherTag.name || [self.name isEqualToString:otherTag.name]) &&
    (self.color == otherTag.color || [self.color isEqualToString:otherTag.color]) &&
    (self.fkListID == otherTag.fkListID || [self.fkListID isEqualToString:otherTag.fkListID]) &&
    (self.fkTagID == otherTag.fkTagID || [self.fkTagID isEqualToString:otherTag.fkTagID]) &&
    (self.listReference == otherTag.listReference || [self.listReference isEqual:otherTag.listReference]) &&
    (self.listTagReference == otherTag.listTagReference || [self.listTagReference isEqual:otherTag.listTagReference]);
}

@end
