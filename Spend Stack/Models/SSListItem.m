//
//  SSListItem.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/15/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSListItem.h"
#import "FMResultSet.h"
#import <Photos/Photos.h>
#import <LinkPresentation/LinkPresentation.h>

@interface SSListItem()

@property (strong, nonatomic, readwrite, nullable) SSListTag *tag;
@property (strong, nonatomic, readwrite, nonnull) CKReference *reference;
@property (strong, nonatomic, readwrite, nullable) CKReference *tagReference;
@property (strong, nonatomic, readwrite, nullable) CKAsset *mediaAttachment;
@property (strong, nonatomic, readwrite, nullable) NSData *mediaAssetData; // Local only
@property (strong, nonatomic, readwrite, nullable) LPLinkMetadata *linkMetadata; // Local only

@end

@implementation SSListItem 

#pragma mark - Custom Setters

- (void)setTag:(SSListTag *)tag
{
    _tag = tag;
    if (_onListTagSet != nil) {
        _onListTagSet(_tag);
    }
}

#pragma mark - Custom Getters

- (NSNumber *)orderingIndex
{
    if (!_orderingIndex) {
        _orderingIndex = @0;
    }
    
    return _orderingIndex;
}

- (NSNumber *)recurringPricingFrequency
{
    if (!_recurringPricingFrequency) {
        _recurringPricingFrequency = @1;
    }
    
    return _recurringPricingFrequency;
}

#pragma mark - Initializers

- (instancetype)initWithParentListRecordID:(CKRecordID *)parentListRecordID
{
    // Due to shares, we need to ensure we save either in our private zone or the shared one
    self = [super initWithZoneID:parentListRecordID.zoneID];
    
    if (self)
    {
        self.title = ss_Localized(@"general.untitled");
        self.notes = @"";
        self.quantity = 1;
        self.reference = [[CKReference alloc] initWithRecordID:parentListRecordID
                                                        action:CKReferenceActionDeleteSelf];
        [self.objCKRecord setParent:[[CKReference alloc] initWithRecordID:parentListRecordID action:CKReferenceActionNone]];
        self.baseAmount = [[NSDecimalNumber alloc] initWithDouble:0];
        self.recurringPricingFrequency = @(1);
        self.customDate = [NSDate date];
    }
    
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)result
{
    self = [super initWithResultSet:result];
    
    if (self)
    {
        self.fkListID = [result stringForColumn:@"listID"];
        self.fkTagID = [result stringForColumn:@"tagID"];

        if (self.fkTagID)
        {
            self.tag = [[SSListTag alloc] initWithResultSet:result];
        }
        
        self.checkedOff = [result boolForColumn:@"checkedOff"];
        self.title = [result stringForColumn:@"title"];
        self.orderingIndex = @([result intForColumn:@"listItemorderingIndex"]);
        
        self.hasTaxApplied = @([result intForColumn:@"hasTaxApplied"]).boolValue;
        self.baseAmount = [NSDecimalNumber decimalNumberWithString:[result stringForColumn:@"baseAmount"]];
        
        NSString *discountAmountString = [result stringForColumn:@"discountAmount"];
        if (discountAmountString)
        {
            self.discountAmount = [NSDecimalNumber decimalNumberWithString:discountAmountString];
        }
        
        NSString *discountPercentageString = [result stringForColumn:@"discountPercentage"];
        if (discountPercentageString)
        {
            self.discountPercentage = [NSDecimalNumber decimalNumberWithString:discountPercentageString];
        }
        
        NSString *weightString = [result stringForColumn:@"weight"];
        if (weightString)
        {
            double weightValue = weightString.doubleValue;
            self.weight = [NSMeasurement measurementWithValue:weightValue];
        }
        
        self.quantity = [result intForColumn:@"quantity"];
        self.notes = [result stringForColumn:@"notes"];
        self.recurringPricingCycle = [result intForColumn:@"recurringPricingCycle"];
        self.recurringPricingFrequency = @([result intForColumn:@"recurringPricingFrequency"] ?: 1);
        
        CKAsset *mediaAsset = (CKAsset *)[NSKeyedUnarchiver ss_unarchiveClass:CKAsset.class fromData:[result dataForColumn:@"mediaAttachment"]];
        if (mediaAsset)
        {
            self.mediaAttachment = mediaAsset;
        }
        
        NSData *mediaAssetData = [result dataForColumn:@"mediaAssetData"];
        if (mediaAssetData)
        {
            self.mediaAssetData = mediaAssetData;
        }
        
        NSString *linkAttachment = [result stringForColumn:@"linkAttachment"];
        if (linkAttachment)
        {
            self.linkAttachment = linkAttachment;
        }
        
        NSData *linkMedataBlob = [result dataForColumn:@"linkMetadata"];
        if (linkMedataBlob)
        {
            LPLinkMetadata *linkMetadata = (LPLinkMetadata *)[NSKeyedUnarchiver ss_unarchiveClass:LPLinkMetadata.class fromData:[result dataForColumn:@"linkMetadata"]];
            if (linkMetadata) self.linkMetadata = linkMetadata;
        }
        
        double customDateNum = [result doubleForColumn:@"customDate"];

        if (customDateNum != 0)
        {
            NSDate *customDate = [NSDate dateWithTimeIntervalSince1970:customDateNum];
            self.customDate = customDate;
        }
        
        self.cardImportName = [result stringForColumn:@"cardImportName"];
        
        self.tagReference = (CKReference *)[NSKeyedUnarchiver ss_unarchiveClass:CKReference.class fromData:[result dataForColumn:@"listItemTagReference"]];
        self.reference = (CKReference *)[NSKeyedUnarchiver ss_unarchiveClass:CKReference.class fromData:[result dataForColumn:@"listItemReference"]];
        NSAssert(self.objCKRecord != nil, @"Spend Stack - Query resulted in no record ID for a list item.");
    }
    
    return self;
}

- (instancetype)initWithExistingItem:(SSListItem *)listItem withParentListRecordID:(CKRecordID *)parentListRecordID
{
    self = [self initWithParentListRecordID:parentListRecordID];
    
    if (self)
    {
        self.fkListID = parentListRecordID.recordName;
        self.checkedOff = listItem.checkedOff;
        self.title = listItem.title;
        self.orderingIndex = @(NSIntegerMax);
        self.hasTaxApplied = listItem.hasTaxApplied;
        self.baseAmount = listItem.baseAmount;
        self.discountAmount = listItem.discountAmount;
        self.discountPercentage = listItem.discountPercentage;
        self.weight = listItem.weight;
        self.quantity = listItem.quantity;
        self.notes = listItem.notes;
        self.recurringPricingCycle = listItem.recurringPricingCycle;
        self.recurringPricingFrequency = listItem.recurringPricingFrequency;
        self.linkAttachment = listItem.linkAttachment;
        self.linkMetadata = listItem.linkMetadata;
        self.customDate = listItem.customDate;
        self.cardImportName = listItem.cardImportName;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.fkListID = [aDecoder decodeObjectForKey:@"fkListID"];
        self.fkTagID = [aDecoder decodeObjectForKey:@"fkTagID"];
        self.checkedOff = [aDecoder decodeBoolForKey:@"checkedOff"];
        self.tag = [aDecoder decodeObjectForKey:@"tag"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.orderingIndex = [aDecoder decodeObjectForKey:@"listItemOrderingIndex"];
        self.hasTaxApplied = [aDecoder decodeBoolForKey:@"hasTaxApplied"];
        self.baseAmount = [aDecoder decodeObjectForKey:@"baseAmount"];
        self.discountAmount = [aDecoder decodeObjectForKey:@"discountAmount"];
        self.discountPercentage = [aDecoder decodeObjectForKey:@"discountPercentage"];
        self.weight = [aDecoder decodeObjectForKey:@"weight"];
        self.quantity = [aDecoder decodeIntegerForKey:@"quantity"];
        self.notes = [aDecoder decodeObjectForKey:@"notes"];
        self.recurringPricingCycle = [aDecoder decodeIntegerForKey:@"recurringPricingCycle"];
        self.recurringPricingFrequency = [aDecoder decodeObjectForKey:@"recurringPricingFrequency"];
        self.mediaAttachment = [aDecoder decodeObjectForKey:@"mediaAttachment"];
        self.tagReference = [aDecoder decodeObjectForKey:@"tagReference"];
        self.reference = [aDecoder decodeObjectForKey:@"reference"];
        self.mediaAssetData = [aDecoder decodeObjectForKey:@"mediaAssetData"];
        self.linkAttachment = [aDecoder decodeObjectForKey:@"linkAttachment"];
        self.linkMetadata = [aDecoder decodeObjectForKey:@"linkMetadata"];
        self.customDate = [aDecoder decodeObjectForKey:@"customDate"];
        self.cardImportName = [aDecoder decodeObjectForKey:@"cardImportName"];
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
    NSAssert(self.reference != nil, @"You cannot save a list item without a parent list for a CloudKit back reference.");
    [aCoder encodeObject:self.fkListID forKey:@"fkListID"];
    [aCoder encodeObject:self.fkTagID forKey:@"fkTagID"];
    [aCoder encodeBool:self.checkedOff forKey:@"checkedOff"];
    [aCoder encodeObject:self.tag forKey:@"tag"];
    [aCoder encodeObject:self.orderingIndex forKey:@"listItemOrderingIndex"];
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeBool:self.hasTaxApplied forKey:@"hasTaxApplied"];
    [aCoder encodeObject:self.baseAmount forKey:@"baseAmount"];
    [aCoder encodeObject:self.discountAmount forKey:@"discountAmount"];
    [aCoder encodeObject:self.discountPercentage forKey:@"discountPercentage"];
    [aCoder encodeObject:self.weight forKey:@"weight"];
    [aCoder encodeInteger:self.quantity forKey:@"quantity"];
    [aCoder encodeObject:self.notes forKey:@"notes"];
    [aCoder encodeInteger:self.recurringPricingCycle forKey:@"recurringPricingCycle"];
    [aCoder encodeObject:self.recurringPricingFrequency forKey:@"recurringPricingFrequency"];
    [aCoder encodeObject:self.mediaAttachment forKey:@"mediaAttachment"];
    [aCoder encodeObject:self.tagReference forKey:@"tagReference"];
    [aCoder encodeObject:self.reference forKey:@"reference"];
    [aCoder encodeObject:self.mediaAssetData forKey:@"mediaAssetData"];
    [aCoder encodeObject:self.linkAttachment forKey:@"linkAttachment"];
    [aCoder encodeObject:self.linkMetadata forKey:@"linkMetadata"];
    [aCoder encodeObject:self.customDate forKey:@"customDate"];
    [aCoder encodeObject:self.cardImportName forKey:@"cardImportName"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSListItem *newListItem = [super copyWithZone:zone];
    
    if (newListItem)
    {
        newListItem.fkListID = [_fkListID copyWithZone:zone];
        newListItem.fkTagID = [_fkTagID copyWithZone:zone];
        newListItem.checkedOff = _checkedOff;
        newListItem.tag = [_tag copyWithZone:zone];
        newListItem.title = [_title copyWithZone:zone];
        newListItem.orderingIndex = [_orderingIndex copyWithZone:zone];
        newListItem.hasTaxApplied = _hasTaxApplied;
        newListItem.baseAmount = [_baseAmount copyWithZone:zone];
        newListItem.discountAmount = [_discountAmount copyWithZone:zone];
        newListItem.discountPercentage = [_discountPercentage copyWithZone:zone];
        newListItem.weight = [_weight copyWithZone:zone];
        newListItem.quantity = _quantity;
        newListItem.notes = [_notes copyWithZone:zone];
        newListItem.recurringPricingCycle = _recurringPricingCycle;
        newListItem.recurringPricingFrequency = [_recurringPricingFrequency copyWithZone:zone];
        newListItem.tagReference = [_tagReference copyWithZone:zone];
        newListItem.reference = [_reference copyWithZone:zone];
        newListItem.mediaAssetData = [_mediaAssetData copyWithZone:zone];
        newListItem.linkAttachment = [_linkAttachment copyWithZone:zone];
        newListItem.linkMetadata = [_linkMetadata copyWithZone:zone];
        newListItem.customDate = [_customDate copyWithZone:zone];
        newListItem.cardImportName = [_cardImportName copyWithZone:zone];
    }
    
    return newListItem;
}

#pragma mark - Public Functions

- (SSListItem *)deepCopy
{
    NSData *buffer = [NSKeyedArchiver ss_archive:self];
    SSListItem *copy = (SSListItem *)[NSKeyedUnarchiver ss_unarchiveSSClassFromData:buffer];
    NSAssert(copy != nil, @"Spend Stack - Copying list item failed.");
    return copy;
}

- (void)addTag:(SSListTag *)listTag withList:(SSList *)list
{
    SSTag *masterTag = [SSTag masterTagForListTag:listTag];
    
    if (masterTag)
    {
        [self addListTag:masterTag withList:list];
    }
    else
    {
        [self addSharedListTag:listTag withList:list];
    }
}

- (void)addListTag:(SSTag *)tag withList:(SSList *)list
{
    NSAssert(list != nil, @"Spend Stack - List is nil and that won't fly.");
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        [self addListTag:tag withList:list withDB:db];
    }];
}

- (void)addListTag:(SSTag *)tag withList:(SSList *)list withDB:(FMDatabase *)db
{
    NSAssert(list != nil, @"Spend Stack - List is nil and that won't fly.");
    if (!tag.dbID || [tag.dbID isEqualToString:@""])
    {
        [self deleteTag];
        return;
    }
    
    SSListTag *listTag = [self listTagFromMasterTagInDatabase:db
                                                         list:list
                                                          tag:tag];
    
    self.tagReference = [[CKReference alloc] initWithRecordID:listTag.objCKRecord.recordID
                                                       action:CKReferenceActionNone];
    
    self.fkTagID = listTag.dbID;
    self.tag = [listTag copy];
    
    // Save it off quitely in the background
    [self.tag.objCKRecord setParentReferenceFromRecordID:list.objCKRecord.recordID];
    [[list dbForList] saveObjects:@[self.tag]
                   withSavePolicy:CKRecordSaveChangedKeys
                    deleteObjects:@[]
                   withCompletion:^(NSError * error) {
                       NSLog(@"Spend Stack - Saved ListTag's parent reference with error:(%@)", error);
                   }];
}

- (void)addSharedListTag:(SSListTag *)listTag withList:(SSList *)list
{
    if (!listTag.dbID || [listTag.dbID isEqualToString:@""])
    {
        [self deleteTag];
        return;
    }
    
    self.tagReference = [[CKReference alloc] initWithRecordID:listTag.objCKRecord.recordID
                                                       action:CKReferenceActionNone];
    
    self.fkTagID = listTag.dbID;
    self.tag = [listTag copy];

    // Save it off quitely in the background
    [self.tag.objCKRecord setParentReferenceFromRecordID:list.objCKRecord.recordID];
    [[list dbForList] saveObjects:@[self.tag]
                   withSavePolicy:CKRecordSaveChangedKeys
                    deleteObjects:@[]
                   withCompletion:^(NSError * error) {
                       NSLog(@"Spend Stack - Saved Shared ListTag's parent reference with error:(%@)", error);
                   }];    
}

// Creates the list tag if it doesn't exist for a list.
- (SSListTag *)listTagFromMasterTagInDatabase:(FMDatabase * _Nonnull)db list:(SSList * _Nonnull)list tag:(SSTag * _Nonnull)tag
{
    BOOL tagExistsForList = [db listTagExistsForListID:list.dbID masterTag:tag];
    SSListTag *listTag;
    
    if (tagExistsForList)
    {
        FMResultSet *result = [db executeQuery:sql_ListTagSelectByListAndTagID, list.dbID, tag.dbID];
        while ([result next])
        {
            listTag = [[SSListTag alloc] initWithResultSet:result];
        }
    }
    else
    {
        listTag = [[SSListTag alloc] initWithParentListRecordID:list.objCKRecord.recordID masterTag:tag];
        [db insertListTagIntoDB:listTag];
    }
    return listTag;
}

- (void)deleteTag
{
    self.onListTagSet = nil;
    self.tagReference = nil;
    self.fkTagID = nil;
    self.tag = nil;
}

- (void)removeDiscounts
{
    self.discountAmount = nil;
    self.discountPercentage = nil;
}

- (void)removeWeightedPricing
{
    self.weight = nil;
}

- (void)addMediaToItem:(PHAsset *)asset completion:(void (^ _Nonnull)(void))completion
{
    PHImageRequestOptions *fetchOps = [PHImageRequestOptions new];
    fetchOps.resizeMode = PHImageRequestOptionsResizeModeFast;
    fetchOps.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:asset options:fetchOps resultHandler:^(NSData *imageData, NSString *dataUTI, CGImagePropertyOrientation orientation, NSDictionary *info) {
        [self attachNewMediaDataToInstanceWithData:imageData completion:completion];
    }];
}

- (void)attachNewMediaDataToInstanceWithData:(NSData * _Nonnull)data completion:(void (^ _Nonnull)(void))completion
{
    __block NSData *imgData = data;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        SSListItemMediaAttachResult *attachmentData = [self generateNewMediaItemResultFromData:imgData];
        
        self.mediaAttachment = attachmentData.asset;
        self.mediaAssetData = attachmentData.data;
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            completion();
        });
    });
}

- (void)attachNewMediaDataToInstanceWithData:(NSData *)data
{
    SSListItemMediaAttachResult *attachmentData = [self generateNewMediaItemResultFromData:data];
    self.mediaAttachment = attachmentData.asset;
    self.mediaAssetData = attachmentData.data;
}

- (void)attachMediaDataToInstanceWithData:(NSData *)data
{
     self.mediaAssetData = data;
}

- (void)removeMediaFromItem
{
    self.mediaAttachment = nil;
    self.mediaAssetData = nil;
}

- (void)attachLink:(NSString *)link metaData:(LPLinkMetadata *)metadata
{
    self.linkAttachment = link;
    self.linkMetadata = metadata;
}

- (void)removeLinkFromItem
{
    self.linkAttachment = nil;
    self.linkMetadata = nil;
}

- (void)resetReferenceForRedo:(SSList *)list
{
    self.reference = [[CKReference alloc] initWithRecordID:list.objCKRecord.recordID
                                                    action:CKReferenceActionDeleteSelf];
    [self.objCKRecord setParent:[[CKReference alloc] initWithRecordID:list.objCKRecord.recordID action:CKReferenceActionNone]];
    self.fkListID = list.dbID;
}

#pragma mark - Overrides

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *guranteedData =  @{@"title":self.title,
                                     @"listItemOrderingIndex":self.orderingIndex,
                                     @"checkedOff":@(self.checkedOff),
                                     @"hasTaxApplied":@(self.hasTaxApplied),
                                     @"baseAmount":self.baseAmount ? self.baseAmount : [NSDecimalNumber numberWithDouble:0],
                                     @"quantity":@(self.quantity),
                                     @"notes":self.notes ? self.notes : @"",
                                     @"recurringPricingCycle":@(self.recurringPricingCycle),
                                     @"recurringPricingFrequency":self.recurringPricingFrequency,
                                     @"reference":self.reference};
    
    NSMutableDictionary *data = [[super dictionaryRepresentation] mutableCopy];
    [data addEntriesFromDictionary:guranteedData];
    if (self.discountAmount) [data setObject:self.discountAmount forKey:@"discountAmount"];
    if (self.discountPercentage) [data setObject:self.discountPercentage forKey:@"discountPercentage"];
    [data setObject:self.weight ? @(self.weight.doubleValue) : [NSNull null] forKey:@"weight"];
    [data setObject:self.tagReference ? self.tagReference : [NSNull null] forKey:@"tagReference"];
    [data setObject:self.mediaAttachment ? self.mediaAttachment : [NSNull null] forKey:@"mediaAttachment"];
    [data setObject:self.linkAttachment ?: [NSNull null] forKey:@"linkAttachment"];
    if (self.customDate) [data setObject:self.customDate forKey:@"customDate"];
    if (self.cardImportName) [data setObject:self.cardImportName forKey:@"cardImportName"];
    
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

- (BOOL)isEqual:(SSListItem *)otherItem
{
    if (self == otherItem)
    {
        return YES;
    }
    
    if (otherItem == nil || ![otherItem isKindOfClass:[SSListItem class]])
    {
        return NO;
    }
    
    return self.hasTaxApplied == otherItem.hasTaxApplied &&
           self.checkedOff == otherItem.checkedOff &&
           self.orderingIndex.integerValue == otherItem.orderingIndex.integerValue &&
           self.baseAmount.floatValue == otherItem.baseAmount.floatValue &&
           self.discountAmount.floatValue == otherItem.discountAmount.floatValue &&
           self.discountPercentage.floatValue == otherItem.discountPercentage.floatValue &&
           self.quantity == otherItem.quantity &&
           self.weight.doubleValue == otherItem.weight.doubleValue &&
           self.recurringPricingCycle == otherItem.recurringPricingCycle &&
        (self.recurringPricingFrequency == otherItem.recurringPricingFrequency || [self.recurringPricingFrequency isEqualToNumber:otherItem.recurringPricingFrequency]) &&
           (self.dbID == otherItem.dbID || [self.dbID isEqualToString:otherItem.dbID]) &&
           (self.fkListID == otherItem.fkListID || [self.fkListID isEqualToString:otherItem.fkListID]) &&
           (self.fkTagID == otherItem.fkTagID || [self.fkTagID isEqualToString:otherItem.fkTagID]) &&
           (self.notes == otherItem.notes || [self.notes isEqualToString:otherItem.notes]) &&
           (self.title == otherItem.title || [self.title isEqualToString:otherItem.title]) &&
           (self.tag == otherItem.tag || [self.tag isEqual:otherItem.tag]) &&
           (self.mediaAttachment == otherItem.mediaAttachment || [self.mediaAttachment.fileURL.absoluteString isEqualToString:otherItem.mediaAttachment.fileURL.absoluteString]) &&
           (self.mediaAssetData == otherItem.mediaAssetData || [self.mediaAssetData isEqualToData:otherItem.mediaAssetData]) &&
           (self.linkAttachment == otherItem.linkAttachment || [self.linkAttachment isEqualToString:otherItem.linkAttachment]) &&
    (self.linkMetadata == otherItem.linkMetadata || [self.linkMetadata.URL.absoluteString isEqualToString:otherItem.linkMetadata.URL.absoluteString]) &&
           (self.customDate == otherItem.customDate || [self.customDate isEqualToDate:otherItem.customDate]) &&
           (self.cardImportName == otherItem.cardImportName || [self.cardImportName isEqualToString:otherItem.cardImportName]) &&
           (self.tagReference == otherItem.tagReference || [self.tagReference isEqual:otherItem.tagReference]);
}

#pragma mark - Class Functions

+ (NSArray <SSListItem *> *)testItems
{
    SSListItem *test1 = [[SSListItem alloc] initForTesting];
    test1.title = @"Food";
    test1.recurringPricingCycle = ListItemRecurringPricingChoiceMonth;
    test1.recurringPricingFrequency = @1;
    test1.baseAmount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    
    SSListItem *test2 = [[SSListItem alloc] initForTesting];
    test1.title = @"Entertainment";
    test1.recurringPricingCycle = ListItemRecurringPricingChoiceMonth;
    test1.recurringPricingFrequency = @1;
    test1.baseAmount = [NSDecimalNumber decimalNumberWithString:@"15.00"];
    
    return @[test1, test2];
}

@end
