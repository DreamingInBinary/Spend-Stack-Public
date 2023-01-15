//
//  SSList.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/15/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSList.h"
#import "FMResultSet.h"
#import "SSList+Utils.h"
#import "SSListDataSourceAdapter.h"

extern NSString * _Nonnull ListTotalDisplayTypeToString(ListTotalDisplayType enumType)
{
    switch (enumType)
    {
        case ListTotalDisplayAll:
            return ss_Localized(@"listHeader.allItems");
            break;
        case ListTotalDisplayOnlyChecked:
            return ss_Localized(@"listHeader.checked");
            break;
        case ListTotalDisplayOnlyUnchecked:
            return ss_Localized(@"listHeader.unchecked");
            break;
    }
}

@interface SSList()

@property (strong, nonatomic, readwrite, nonnull) SSTaxRateInfo *taxInfo;
@property (nonatomic, readwrite) NSInteger itemCount;
@property (strong, nonatomic, readwrite, nonnull) SSListDataSourceAdapter *datasourceAdapter;

@end

@implementation SSList

#pragma mark - Custom Getter

- (NSString *)currencyIdentifier
{
    if (!_currencyIdentifier)
    {
        _currencyIdentifier = [NSLocale currentLocale].localeIdentifier;
    }

    return _currencyIdentifier;
}

- (TaxUtility *)taxUtil
{
    if (!_taxUtil || [_taxUtil.localeID isEqualToString:_currencyIdentifier] == NO)
    {
        _taxUtil = [[TaxUtility alloc] initWithLocaleID:_currencyIdentifier];
    }
    
    return _taxUtil;
}

- (NSString *)currencyCode
{
    return [NSLocale localeWithLocaleIdentifier:self.currencyIdentifier].currencyCode;
}

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.taxInfo = [[SSTaxRateInfo alloc] initWithParentListRecordID:self.objCKRecord.recordID];
        self.dateCreated = [NSDate date];
        self.totalCost = [[NSDecimalNumber alloc] initWithString:@"0"];
    }
    
    return self;
}

- (instancetype)initWithResultSet:(FMResultSet *)result
{
    self = [super initWithResultSet:result];
    
    if (self)
    {
        self.name = [result stringForColumn:@"name"];
        self.dateCreated = [result dateForColumn:@"dateCreated"];
        self.itemCount = [result intForColumn:@"itemCount"];
        self.orderingIndex = @([result intForColumn:@"listOrderingIndex"]);
        self.totalCost = [NSDecimalNumber decimalNumberWithString:[result stringForColumn:@"totalCost"]];
        self.locked = @([result intForColumn:@"locked"]).boolValue;
        self.showingCheckboxes = @([result intForColumn:@"showingCheckboxes"]).boolValue;
        self.totalDisplayType = @([result intForColumn:@"totalDisplayType"]).integerValue;
        self.taxInfo = [[SSTaxRateInfo alloc] initWithResultSet:result];
        self.currencyIdentifier = [result stringForColumn:@"currencyIdentifier"];
        self.datasourceAdapter = [[SSListDataSourceAdapter alloc] initWithList:self resultSet:result];
    }
    
    return self;
}

- (instancetype)initWithExistingList:(SSList *)list
{
    self = [self init];
    
    if (self)
    {
        self.name = list.name;
        self.itemCount = list.itemCount;
        self.orderingIndex = @(list.orderingIndex.intValue + 1);
        self.locked = list.locked;
        self.showingCheckboxes = list.showingCheckboxes;
        self.totalDisplayType = list.totalDisplayType;
        self.taxInfo = [[SSTaxRateInfo alloc] initWithExistingTaxInfo:list.taxInfo withParentListRecordID:self.objCKRecord.recordID];
        self.currencyIdentifier = list.currencyIdentifier;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.dateCreated = [aDecoder decodeObjectForKey:@"dateCreated"];
        self.itemCount = [aDecoder decodeIntegerForKey:@"itemCount"];
        self.orderingIndex = [aDecoder decodeObjectForKey:@"listOrderingIndex"];
        self.totalCost = [aDecoder decodeObjectForKey:@"totalCost"];
        self.taxInfo = [aDecoder decodeObjectForKey:@"taxInfo"];
        self.datasourceAdapter = [aDecoder decodeObjectForKey:@"datasourceAdapter"];
        self.locked = [aDecoder decodeBoolForKey:@"locked"];
        self.showingCheckboxes = [aDecoder decodeBoolForKey:@"showingCheckboxes"];
        self.currencyIdentifier = [aDecoder decodeObjectForKey:@"currencyIdentifier"];
        self.totalDisplayType = ((NSNumber *)[aDecoder decodeObjectForKey:@"totalDisplayType"]).integerValue;
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
    
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.dateCreated forKey:@"dateCreated"];
    [aCoder encodeInteger:self.itemCount forKey:@"itemCount"];
    [aCoder encodeObject:self.dateCreated forKey:@"dateCreated"];
    [aCoder encodeObject:self.orderingIndex forKey:@"listOrderingIndex"];
    [aCoder encodeObject:self.totalCost forKey:@"totalCost"];
    [aCoder encodeObject:self.taxInfo forKey:@"taxInfo"];
    [aCoder encodeObject:self.datasourceAdapter forKey:@"datasourceAdapter"];
    [aCoder encodeBool:self.isLocked forKey:@"locked"];
    [aCoder encodeBool:self.isShowingCheckboxes forKey:@"showingCheckboxes"];
    [aCoder encodeObject:@(self.totalDisplayType) forKey:@"totalDisplayType"];
    [aCoder encodeObject:self.currencyIdentifier forKey:@"currencyIdentifier"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSList *newList = [super copyWithZone:zone];
    
    if (newList)
    {
        newList.name = [_name copyWithZone:zone];
        newList.dateCreated = [_dateCreated copyWithZone:zone];
        newList.orderingIndex = [_orderingIndex copyWithZone:zone];
        newList.totalCost = [_totalCost copyWithZone:zone];
        newList.taxInfo = [_taxInfo copyWithZone:zone];
        newList.datasourceAdapter = [_datasourceAdapter copyWithZone:zone];
        newList.orderingIndex = [_orderingIndex copyWithZone:zone];
        newList.locked = self.isLocked;
        newList.showingCheckboxes = self.isShowingCheckboxes;
        newList.totalDisplayType = self.totalDisplayType;
        newList.currencyIdentifier = [_currencyIdentifier copyWithZone:zone];
        [newList.datasourceAdapter setListDuringCopy:newList];
    }
    
    return newList;
}

#pragma mark - Public Functions

- (SSList *)deepCopy
{
    NSData *buffer = [NSKeyedArchiver ss_archive:self];
    SSList *copy = (SSList *)[NSKeyedUnarchiver ss_unarchiveSSClassFromData:buffer];
    [copy.datasourceAdapter updateList:copy];
    return copy;
}

- (void)addItem:(SSListItem *)item
{
    NSAssert(self.objCKRecord != nil || [item.reference.recordID isEqual:self.objCKRecord] == NO, @"List (%@) record ID is nil or the list item's reference isn't set to this list.", self.name);
    
    // This is set via a trigger in the database. Incrementing it manually here so if you add the first item with a price,
    // the calcTotal works even if the list isn't hydrated from the database yet, which would mean this is still 0 in that case.
    self.itemCount++;
    
    [self.datasourceAdapter addItem:item];
}

- (void)addItemLocallyAndOnServer:(SSListItem *)item inDB:(FMDatabase *)db
{
    [self addItem:item];
    
    item.fkListID = self.dbID;
    
    if (item.fkTagID == nil || [item.fkTagID isEqualToString:@""])
    {
        SSListTag *miscTag = self.datasourceAdapter.sortedTags.firstObject;
        item.orderingIndex = @(self.datasourceAdapter.itemsByTag[miscTag].count);
    }
    else
    {
        SSListTag *listItemTag = [self.datasourceAdapter tagByDBID:item.fkTagID];
        item.orderingIndex = @(self.datasourceAdapter.itemsByTag[listItemTag].count);
    }
    
    [[self dbForList] saveObjects:@[item]
                        withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                         deleteObjects:@[]
                        withCompletion:^(NSError * error) {
        NSLog(@"Spend Stack - Saved list item %@. Error:(%@)", item.title, error.localizedDescription);
    }];
    
    BOOL success = [db insertListItemIntoDB:item taxInfo:self.taxInfo taxUtil:self.taxUtil];
    NSLog(@"Spend Stack - New list item insert successful:%@", @(success));
}

- (void)moveItemToList:(SSListItem *)item withListTagID:(NSString * _Nullable)fkListTag inDB:(FMDatabase * _Nonnull)db
{
    NSAssert(self.objCKRecord != nil || [item.reference.recordID isEqual:self.objCKRecord] == NO, @"List (%@) record ID is nil or the list item's reference isn't set to this list.", self.name);
    
    self.itemCount++;
    
    // Did this item have a tag from another list?
    if (item.tag || fkListTag)
    {
        NSString *tagID = item.tag.fkTagID;
        if (fkListTag)
        {
            tagID = fkListTag;
        }
        
        // Remove the list's existing tag, add it this list's proxy representation of it.
        SSTag *masterTag = [SSListTag masterTagForListTagID:tagID db:db];
        [item deleteTag];
        
        if (masterTag)
        {
            [item addListTag:masterTag withList:self withDB:db];
        }
        else
        {
            [item addSharedListTag:item.tag withList:self];
        }
    }
    
    // Tag needs to be dealt with at this point
    [self.datasourceAdapter addItem:item];
}

- (void)applyEditsForItemLocally:(SSListItem *)item
{
    NSAssert(self.objCKRecord != nil || [item.reference.recordID isEqual:self.objCKRecord] == NO, @"List (%@) record ID is nil or the list item's reference isn't set to this list.", self.name);
    [self.datasourceAdapter applyEditsToItem:item];
}

- (void)applyEditsForItemLocallyAndOnServer:(SSListItem *)item
{
    NSAssert(self.objCKRecord != nil || [item.reference.recordID isEqual:self.objCKRecord] == NO, @"List (%@) record ID is nil or the list item's reference isn't set to this list.", self.name);
    [self.datasourceAdapter applyEditsToItem:item];
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL success = [db updateListItemInDB:item taxInfo:self.taxInfo taxUtil:self.taxUtil];
        NSLog(@"Spend Stack - Updated list item successfully:%@", @(success));
        
        [[self dbForList] saveObjects:@[item]
                       withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                        deleteObjects:@[]
                       withCompletion:^(NSError *possibleError) {
            NSLog(@"Spend Stack - Saved edits for item %@ (Error: %@)", item.title, possibleError.localizedRecoveryOptions);
        }];
    }];
}

- (void)saveListLocallyAndOnServer:(void (^)(void))completion
{
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL success = [db updateListInDB:self];
        NSLog(@"Spend Stack - Successfully updated list in database:%@", @(success));
        success = [db updateTaxRateInfoInDB:self.taxInfo];
        NSLog(@"Spend Stack - Successfully updated tax info in database:%@", @(success));
        
        [[self dbForList] saveObjects:@[self, self.taxInfo]
                            withSavePolicy:CKRecordSaveAllKeys
                             deleteObjects:@[]
                            withCompletion:^(NSError * error) {
            NSLog(@"Spend Stack - Saved list and tax rate %@. (Error: %@)", self.name, error.localizedDescription);
        }];
        
        if (completion) completion();
    }];
}

- (void)removeItem:(SSListItem *)item
{
    [self.datasourceAdapter removeItem:item];

    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL success = [db deleteListItemInDB:item];
        NSLog(@"Spend Stack - Successfully deleted item in database:%@", @(success));
        
        [[self dbForList] saveObjects:@[]
                       withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                        deleteObjects:@[item]
                       withCompletion:^(NSError *possibleError) {
            NSLog(@"Spend Stack - Deleted item %@ (Error: %@)", item.title, possibleError.localizedDescription);
        }];
    }];
}

- (void)removeItems:(NSArray<SSListItem *> *)items
{
    [self.datasourceAdapter removeItems:items];
    [self removeItemsFromDatabaseAndCloudKit:items];
}

- (void)removeAllItems
{
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        [[self dbForList] saveObjects:@[]
                       withSavePolicy:CKRecordSaveAllKeys
                        deleteObjects:self.datasourceAdapter.allItems
                       withCompletion:^(NSError * error) {
            NSLog(@"Spend Stack - Deleted all items. Error:(%@)", error.localizedDescription);
        }];
        
        for (SSListItem *listItem in self.datasourceAdapter.allItems)
        {
            BOOL success = [db deleteListItemInDB:listItem];
            NSLog(@"Spend Stack - Successfully deleted list item: %@", @(success));
        }
    }];
    
    [self.datasourceAdapter removeAllItems];
}

- (void)removeItemsFromDatabaseAndCloudKit:(NSArray<SSListItem *> *)items
{
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSMutableArray <NSString *> *deletionIDs = [NSMutableArray new];
        for (SSListItem *item in items)
        {
            [deletionIDs addObject:item.dbID];
        }
        
        BOOL success = [db deleteListItemsInDB:deletionIDs];
        NSLog(@"Spend Stack - Successfully deleted items in database:%@", @(success));
        
        [[self dbForList] saveObjects:@[]
                       withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                        deleteObjects:items
                       withCompletion:^(NSError *possibleError) {
                           NSLog(@"Spend Stack - Deleted items (Error: %@)", possibleError.localizedDescription);
                       }];
    }];
}

- (void)assignNewAdapter:(SSListDataSourceAdapter *)adapter
{
    self.datasourceAdapter = adapter;
}

#pragma mark - Overrides

- (NSDictionary *)dictionaryRepresentation
{
    NSDictionary *guranteedData = @{@"name":self.name,
                                    @"dateCreated":self.dateCreated,
                                    @"listOrderingIndex":self.orderingIndex,
                                    @"totalCost":self.totalCost,
                                    @"locked":@(self.isLocked),
                                    @"showingCheckboxes":@(self.showingCheckboxes),
                                    @"totalDisplayType":@(self.totalDisplayType),
                                    @"currencyIdentifier":self.currencyIdentifier
                                    };
    NSMutableDictionary *data = [[super dictionaryRepresentation] mutableCopy];
    [data addEntriesFromDictionary:guranteedData];
    
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

- (BOOL)isEqual:(SSList *)otherList
{
    if (self == otherList)
    {
        return YES;
    }
    
    if (otherList == nil || ![otherList isKindOfClass:[SSList class]])
    {
        return NO;
    }
    
    return self.itemCount == otherList.itemCount &&
           self.isLocked == otherList.isLocked &&
           self.isShowingCheckboxes == otherList.isShowingCheckboxes &&
           self.orderingIndex.integerValue == otherList.orderingIndex.integerValue &&
           self.totalCost.integerValue == otherList.totalCost.integerValue &&
           self.totalDisplayType == otherList.totalDisplayType &&
           (self.currencyIdentifier == otherList.currencyIdentifier || [self.currencyIdentifier isEqualToString:otherList.currencyIdentifier]) &&
           (self.dbID == otherList.dbID || [self.dbID isEqualToString:otherList.dbID]) &&
           (self.name == otherList.name || [self.name isEqualToString:otherList.name]) &&
           [self.dateCreated isEqualToDate:otherList.dateCreated] &&
           (self.taxInfo == otherList.taxInfo || [self.taxInfo isEqual:otherList.taxInfo]) &&
           (self.objCKRecord.share == otherList.objCKRecord.share || [self.objCKRecord.share isEqual:otherList.objCKRecord.share]) &&
           (self.datasourceAdapter.allItems == otherList.datasourceAdapter.allItems || [self.datasourceAdapter.allItems isEqual:otherList.datasourceAdapter.allItems]);
}

@end
