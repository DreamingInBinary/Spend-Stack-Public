//
//  SSTaxRateInfo.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/31/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSTaxRateInfo.h"
#import "FMResultSet.h"

@interface SSTaxRateInfo()

@property (strong, nonatomic, readwrite, nonnull) CKReference *reference;

@end

@implementation SSTaxRateInfo

#pragma mark - Custom Getters

- (BOOL)wasManuallySet
{
    if (self.didManuallySet == nil) return NO;
    return self.didManuallySet.boolValue;
}

#pragma mark - Initializers

- (instancetype)initWithParentListRecordID:(CKRecordID *)parentListRecordID
{
    // Due to shares, we need to ensure we save either in our private zone or the shared one
    self = [super initWithZoneID:parentListRecordID.zoneID];
    
    if (self)
    {
        self.reference = [[CKReference alloc] initWithRecordID:parentListRecordID action:CKReferenceActionDeleteSelf];
        [self.objCKRecord setParent:[[CKReference alloc] initWithRecordID:parentListRecordID action:CKReferenceActionNone]];
    }
    
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)result
{
    self = [super initWithResultSet:result];
    
    if (self)
    {
        self.fkListID = [result stringForColumn:@"listID"];
        self.taxRate = [NSDecimalNumber decimalNumberWithString:[result stringForColumn:@"taxRate"]];
        self.taxEnabled = @([result intForColumn:@"taxEnabled"]).boolValue;
        self.localSalesTaxLocation = [result stringForColumn:@"localSalesTaxLocation"];
        self.didManuallySet = [result intForColumn:@"didManuallySet"] ? @([result intForColumn:@"didManuallySet"]) : nil;
        self.reference = (CKReference *)[NSKeyedUnarchiver ss_unarchiveClass:CKReference.class fromData:[result dataForColumn:@"taxInfoReference"]];
    }
    
    return self;
}

- (instancetype)initWithExistingTaxInfo:(SSTaxRateInfo *)taxInfo withParentListRecordID:(CKRecordID *)parentListRecordID
{
    self = [self initWithParentListRecordID:parentListRecordID];
    
    if (self)
    {
        self.taxRate = taxInfo.taxRate;
        self.taxEnabled = taxInfo.taxEnabled;
        self.localSalesTaxLocation = taxInfo.localSalesTaxLocation;
        self.didManuallySet = taxInfo.didManuallySet;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.fkListID = [aDecoder decodeObjectForKey:@"fkListID"];
        self.taxRate = [aDecoder decodeObjectForKey:@"taxRate"];
        self.taxEnabled = [aDecoder decodeBoolForKey:@"taxEnabled"];
        self.localSalesTaxLocation = [aDecoder decodeObjectForKey:@"localSalesTaxLocation"];
        self.didManuallySet = [aDecoder decodeObjectForKey:@"didManuallySet"];
        self.reference = [aDecoder decodeObjectForKey:@"reference"];
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
    NSAssert(self.reference != nil, @"You cannot save an tax info without a parent list for a CloudKit back reference.");
    [aCoder encodeObject:self.fkListID forKey:@"fkListID"];
    [aCoder encodeObject:self.taxRate forKey:@"taxRate"];
    [aCoder encodeBool:self.taxEnabled forKey:@"taxEnabled"];
    [aCoder encodeObject:self.localSalesTaxLocation forKey:@"localSalesTaxLocation"];
    [aCoder encodeObject:self.didManuallySet forKey:@"didManuallySet"];
    [aCoder encodeObject:self.reference forKey:@"reference"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSTaxRateInfo *newTaxInfo = [super copyWithZone:zone];

    if (newTaxInfo)
    {
        newTaxInfo.fkListID = [_fkListID copyWithZone:zone];
        newTaxInfo.taxRate = [_taxRate copyWithZone:zone];
        newTaxInfo.taxEnabled = _taxEnabled;
        newTaxInfo.localSalesTaxLocation = [_localSalesTaxLocation copyWithZone:zone];
        newTaxInfo.didManuallySet = _didManuallySet;
        newTaxInfo.reference = [_reference copyWithZone:zone];
    }
    
    return newTaxInfo;
}

#pragma mark - Public Methods

- (void)setTaxRateManuallySet:(BOOL)manuallySet
{
    self.didManuallySet = [NSNumber numberWithBool:manuallySet];
}

- (void)resetReferenceForRedo:(SSList *)list
{
    self.reference = [[CKReference alloc] initWithRecordID:list.objCKRecord.recordID action:CKReferenceActionDeleteSelf];
    [self.objCKRecord setParent:[[CKReference alloc] initWithRecordID:list.objCKRecord.recordID action:CKReferenceActionNone]];
    self.fkListID = list.dbID;
}

#pragma mark - Overrides

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *guranteedData =  @{@"taxEnabled":@(self.taxEnabled),
                                     @"reference":self.reference};
    
    NSMutableDictionary *data = [[super dictionaryRepresentation] mutableCopy];
    [data addEntriesFromDictionary:guranteedData];
    if (self.taxRate) [data setObject:self.taxRate forKey:@"taxRate"];
    if (self.localSalesTaxLocation) [data setObject:self.localSalesTaxLocation forKey:@"localSalesTaxLocation"];
    if (self.didManuallySet) [data setObject:self.didManuallySet forKey:@"didManuallySet"];
    
    return [NSDictionary dictionaryWithDictionary:data];
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

- (BOOL)isEqual:(SSTaxRateInfo *)otherTaxInfo {
    if (self == otherTaxInfo)
    {
        return YES;
    }
    
    if (otherTaxInfo == nil || ![otherTaxInfo isKindOfClass:[SSTaxRateInfo class]])
    {
        return NO;
    }
    
    return self.taxRate.floatValue == otherTaxInfo.taxRate.floatValue &&
           self.taxIsEnabled == otherTaxInfo.taxIsEnabled &&
            self.didManuallySet == otherTaxInfo.didManuallySet &&
           (self.fkListID == otherTaxInfo.fkListID || [self.fkListID isEqualToString:otherTaxInfo.fkListID]) &&
           (self.localSalesTaxLocation == otherTaxInfo.localSalesTaxLocation || [self.localSalesTaxLocation isEqualToString:otherTaxInfo.localSalesTaxLocation]) &&
           (self.dbID == otherTaxInfo.dbID || [self.dbID isEqualToString:otherTaxInfo.dbID]) &&
           (self.localSalesTaxLocation == otherTaxInfo.localSalesTaxLocation || [self.localSalesTaxLocation isEqualToString:otherTaxInfo.localSalesTaxLocation]) &&
           (self.reference == otherTaxInfo.reference || [self.reference isEqual:otherTaxInfo.reference]);
}

@end
