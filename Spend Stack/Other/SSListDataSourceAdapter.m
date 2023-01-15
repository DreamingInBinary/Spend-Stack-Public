//
//  SSListDataSourceAdapter.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/23/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListDataSourceAdapter.h"
#import "SSListTag.h"

static NSArray<SSListTag *> *sortedTags(NSArray <SSListTag *> *tags) {
    return [tags sortedArrayUsingComparator:^NSComparisonResult(SSListTag *tag1, SSListTag *tag2) {
        if (tag1.orderingIndex.integerValue == tag2.orderingIndex.integerValue) {
            return [tag1.objCKRecord.creationDate compare:tag2.objCKRecord.creationDate] == NSOrderedAscending;
        }
        
        return tag1.orderingIndex.integerValue > tag2.orderingIndex.integerValue;
    }];
}

@interface SSListDataSourceAdapter()

@property (weak, nonatomic, readwrite, nullable) SSList *list;
@property (strong, nonatomic, readwrite, nonnull) SSListTableViewModel *itemsByTag;
@property (strong, nonatomic, readwrite, nonnull) NSArray <SSListTag *> *sortedTags;

@end

@implementation SSListDataSourceAdapter

#pragma mark - Custom Getters

- (NSArray <SSListTag *> *)sortedTags
{
    if (_sortedTags == nil)
    {
        [self updateSortedTags];
    }
    
    return _sortedTags;
}

- (NSArray <SSListTag *> *)userCreatedTags
{
    NSMutableArray <SSListTag *> *tags = [_itemsByTag.allKeys mutableCopy];
    [tags removeObject:self.miscTag];
    return sortedTags(tags);
}

- (BOOL)listHasTaggedItems
{
    if (self.sortedTags.count == 1 && [self.sortedTags.firstObject isEqual:self.miscTag])
    {
        return NO;
    }
    
    return YES;
}

- (NSInteger)totalNumberOfItems
{
    NSInteger numberOfItems = 0;
    
    for (NSMutableArray <SSListItem *> *itemArray in self.itemsByTag.allValues)
    {
        numberOfItems += itemArray.count;
    }
    
    return numberOfItems;
}

- (NSArray <SSListItem *> *)allItems
{
    NSMutableArray <SSListItem *> *allItems = [NSMutableArray new];
    
    for (NSMutableArray <SSListItem *> * itemArray in self.itemsByTag.allValues)
    {
        [allItems addObjectsFromArray:itemArray];
    }
    
    return [allItems copy];
}

- (NSArray <SSListItem *> *)allCheckedItems
{
    NSArray <SSListItem *> *allItems = [self allItems];
    NSPredicate *checkedPredicate = [NSPredicate predicateWithFormat:@"SELF.checkedOff == YES"];
    return [allItems filteredArrayUsingPredicate:checkedPredicate];
}

- (NSArray <SSListItem *> *)allUncheckedItems
{
    NSArray <SSListItem *> *allItems = [self allItems];
    NSPredicate *checkedPredicate = [NSPredicate predicateWithFormat:@"SELF.checkedOff == NO"];
    return [allItems filteredArrayUsingPredicate:checkedPredicate];
}

- (SSListTag *)miscTag
{
    if (_miscTag == nil)
    {
        SSListTag *uncategorizedTag = [SSListTag miscTag];
        _miscTag = uncategorizedTag;
    }
    
    return _miscTag;
}

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list resultSet:(FMResultSet *)resultSet
{
    self = [super init];
    
    if (self)
    {
        self.list = list;
        self.sortedTags = @[];
        self.itemsByTag = [self createItemsByTagDictionaryByQueryingDB:resultSet.parentDB];
        [self updateSortedTags];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.itemsByTag = [aDecoder decodeObjectForKey:@"itemsByTag"];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.itemsByTag forKey:@"itemsByTag"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SSListDataSourceAdapter *newDataSourceAdapter = [[[self class] allocWithZone:zone] init];
    
    if (newDataSourceAdapter)
    {
        newDataSourceAdapter.itemsByTag = [_itemsByTag copyWithZone:zone];
        newDataSourceAdapter.sortedTags =  [_sortedTags copyWithZone:zone];
    }
    
    return newDataSourceAdapter;
}

- (SSListDataSourceAdapter *)deepCopy
{
    NSData *buffer = [NSKeyedArchiver ss_archive:self];
    SSListDataSourceAdapter *copy = (SSListDataSourceAdapter *)[NSKeyedUnarchiver ss_unarchiveSSClassFromData:buffer];
    return copy;
}

#pragma mark - Private

- (SSListTableViewModel *)createItemsByTagDictionaryByQueryingDB:(FMDatabase *)db
{
    FMResultSet *res = [db executeQuery:sql_ListItemSelectByListID, self.list.dbID];
    return [self listTableViewModelFromResultSet:res];
}

- (SSListTableViewModel *)listTableViewModelFromResultSet:(FMResultSet *)resultSet
{
    NSMutableArray <SSListItem *> *listItems = [NSMutableArray new];
    while ([resultSet next])
    {
        SSListItem *item = [[SSListItem alloc] initWithResultSet:resultSet];
        [listItems addObject:item];
    }
    
    // Sort by ordering index
    [listItems sortUsingComparator:^NSComparisonResult(SSListItem *list1, SSListItem *list2) {
        return list1.orderingIndex.integerValue > list2.orderingIndex.integerValue;
    }];
    
    NSMutableDictionary <SSListTag *, NSMutableArray <SSListItem *> *> *itemsByTag = [NSMutableDictionary new];
    
    for (SSListItem *listItem in listItems)
    {
        SSListTag *listItemTag = listItem.tag;
        
        if (listItemTag == nil)
        {
            if (itemsByTag[self.miscTag] == nil) itemsByTag[self.miscTag] = [NSMutableArray new];
            [itemsByTag[self.miscTag] addObject:listItem];
        }
        else
        {
            if (itemsByTag[listItem.tag] == nil) itemsByTag[listItem.tag] = [NSMutableArray new];
            [itemsByTag[listItem.tag] addObject:listItem];
        }
    }

    return itemsByTag;
}

- (SSListItem *)listItemFromEditedListItem:(SSListItem *)editedListItem tagKey:(SSListTag *)listTag
{
    for (SSListItem *listItem in self.itemsByTag[listTag])
    {
        if ([listItem.dbID isEqualToString:editedListItem.dbID])
        {
            return listItem;
        }
    }
    
    return nil;
}

#pragma mark - Public Methods

- (SSListTag *)tagByDBID:(NSString *)dbID
{
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF.dbID == %@", dbID];
    NSArray <SSListTag *> *matches = [self.sortedTags filteredArrayUsingPredicate:searchPredicate];
    NSAssert(matches.count == 1 || matches.count == 0, @"Spend Stack - More than one tag matches its database ID.");
    return matches.firstObject;
}

- (SSListItem *)listItemByDBID:(NSString *)dbID
{
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF.dbID == %@", dbID];
    NSArray <SSListItem *> *matches = [self.allItems filteredArrayUsingPredicate:searchPredicate];
    NSAssert(matches.count == 1 || matches.count == 0, @"Spend Stack - More than one list item matches its database ID.");
    return matches.count > 0 ? matches.firstObject : nil;
}

- (SSListTag *)listTagForListItem:(SSListItem *)listItem
{
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF.dbID == %@", listItem.fkTagID];
    NSArray <SSListTag *> *matches = [self.sortedTags filteredArrayUsingPredicate:searchPredicate];
    NSAssert(matches.count == 1 || matches.count == 0, @"Spend Stack - More than one tag matches its database ID.");
    return matches.count > 0 ? matches.firstObject : self.miscTag;
}

- (void)setListDuringCopy:(SSList *)list
{
    // A bit hacky to be sure, but when copying the list isn't retained.
    self.list = list;
}

- (void)refreshTags
{
    // Takes care of any edits made by tags since we last viewed the list
    NSString *listIDPrimaryKey = self.list.dbID;
    
    __weak typeof(self) weakSelf = self;
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *res = [db executeQuery:sql_ListItemSelectByListID, listIDPrimaryKey];
        weakSelf.itemsByTag = [self listTableViewModelFromResultSet:res];
        [weakSelf updateSortedTags];
    }];
}

- (void)updateSortedTags
{
    self.sortedTags = sortedTags(self.itemsByTag.allKeys);
    
    if ([self.sortedTags containsObject:self.miscTag])
    {
        NSMutableArray <SSListTag *> *mutableSortedTags = [self.sortedTags mutableCopy];
        [mutableSortedTags removeObject:self.miscTag];
        [mutableSortedTags insertObject:self.miscTag atIndex:0];
        
        self.sortedTags = [mutableSortedTags copy];
    }
}

- (void)addItem:(SSListItem *)listItem
{
    SSListTag *insertionTag = listItem.tag ?: self.miscTag;
    
    if (self.itemsByTag[insertionTag] == nil) self.itemsByTag[insertionTag] = [NSMutableArray new];
    
    // Update ordering of items
    NSNumber *orderingIndex = listItem.proposedInsertionIndex ?: @(self.itemsByTag[insertionTag].count);
    if (orderingIndex.integerValue < self.itemsByTag[insertionTag].count)
    {
        [self.itemsByTag[insertionTag] insertObject:listItem atIndex:orderingIndex.integerValue];
    }
    else
    {
        [self.itemsByTag[insertionTag] addObject:listItem];
    }
    
    for (NSUInteger idx = 0; idx < self.itemsByTag[insertionTag].count; idx++)
    {
        self.itemsByTag[insertionTag][idx].orderingIndex = @(idx);
    }
    
    [self updateSortedTags];
}

- (void)applyEditsToItem:(SSListItem *)listItem
{
    // Need to find the reference since its tag might've changed
    for (SSListTag *tagKey in self.itemsByTag.allKeys)
    {
        // Due to multiple windows, when the edit comes in - contains: might not work
        SSListItem *localEditedItem = [self listItemFromEditedListItem:listItem tagKey:tagKey];
        if (localEditedItem)
        {
            SSListTag *itemTag = listItem.tag ? listItem.tag : self.miscTag;
            BOOL itemChangedTags = ![itemTag isEqual:tagKey];
            
            if (itemChangedTags)
            {
                // Remove it from the old tag array
                NSInteger idxOfObj = [self.itemsByTag[tagKey] indexOfObject:localEditedItem];
                NSAssert(idxOfObj != NSNotFound, @"Couldn't find list item %@ for item with changed tag.", listItem.title);
                [self.itemsByTag[tagKey] removeObjectAtIndex:idxOfObj];
                if (self.itemsByTag[tagKey].count == 0) self.itemsByTag[tagKey] = nil;
                
                // Put it in the right tag array
                if (self.itemsByTag[itemTag] == nil) self.itemsByTag[itemTag] = [NSMutableArray new];
                [self.itemsByTag[itemTag] addObject:listItem];
            }
            else
            {
                NSInteger idxOfObj = [self.itemsByTag[tagKey] indexOfObject:localEditedItem];
                NSAssert(idxOfObj != NSNotFound, @"Couldn't find tag for list item %@.", listItem.title);
                [self.itemsByTag[tagKey] replaceObjectAtIndex:idxOfObj withObject:listItem];
            }
            
            break;
        }
    }
    
    [self updateSortedTags];
}

- (BOOL)containsItem:(SSListItem *)listItem
{
    SSListTag *tagArray = listItem.tag ? listItem.tag : self.miscTag;
    return [self.itemsByTag[tagArray] containsObject:listItem];
}

- (void)removeItem:(SSListItem *)listItem
{
    // We receive deep copies here some times, like when we move an item that was tagged into the misc section
    // Via drag and drop. By this point, it's tag has been removed so we need to find it by dbID.
    SSListItem *localListItem = [self listItemByDBID:listItem.dbID];
    SSListTag *tagKey = [self listTagForListItem:localListItem];
    
    NSInteger idxOfItem = [self.itemsByTag[tagKey] indexOfObject:localListItem];
    NSAssert(idxOfItem != NSNotFound, @"Couldn't find list item %@ to delete.", listItem.title);
    [self.itemsByTag[tagKey] removeObjectAtIndex:idxOfItem];
    if (self.itemsByTag[tagKey].count == 0) self.itemsByTag[tagKey] = nil;
    
    [self updateSortedTags];
}

- (void)removeItems:(NSArray<SSListItem *> *)listItems
{
    for (SSListItem *item in listItems)
    {
        [self removeItem:item];
    }
}

- (void)removeAllItems
{
    [self.itemsByTag removeAllObjects];
    [self updateSortedTags];
}

- (SSListItem *)listItemFromIndexPath:(NSIndexPath *)indexPath
{
    SSListTag *currentTagKey = self.sortedTags[indexPath.section];
    SSListItem *item = self.itemsByTag[currentTagKey][indexPath.row];
    return item;
}

- (NSArray <SSListItem *> *)listItemsFromIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    NSMutableArray <SSListItem *> *listItems = [NSMutableArray new];
    
    for (NSIndexPath *idp in indexPaths)
    {
        [listItems addObject:[self listItemFromIndexPath:idp]];
    }
    
    return [listItems copy];
}

- (NSIndexPath *)indexPathForListItem:(SSListItem *)listItem
{
    SSListTag *itemTag = listItem.tag ? listItem.tag : self.miscTag;
    
    NSInteger idxOfItem = [self.itemsByTag[itemTag] indexOfObject:listItem];
    NSInteger sectionOfItem = [self.sortedTags indexOfObject:itemTag];
    
    NSAssert(idxOfItem != NSNotFound && sectionOfItem != NSNotFound, @"Couldn't create index path for item %@", listItem.title);
    
    return [NSIndexPath indexPathForRow:idxOfItem inSection:sectionOfItem];
}

- (void)moveTagAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    SSListItem *reorderedListItem;
    
    SSListTag *currentTagKey = self.sortedTags[sourceIndexPath.section];
    SSListTag *reorderedTagKey = self.sortedTags[destinationIndexPath.section];
    
    reorderedListItem = [self listItemFromIndexPath:sourceIndexPath];
    [reorderedListItem deleteTag];
    
    SSTag *masterTag = [SSTag masterTagForListTag:reorderedTagKey];
    
    if (masterTag == nil)
    {
        // This tag is being shared with the current user, so they don't have
        // The master tag.
        [reorderedListItem addSharedListTag:reorderedTagKey withList:self.list];
    }
    else
    {
        [reorderedListItem addListTag:masterTag withList:self.list];
    }
    
    [self.itemsByTag[currentTagKey] removeObjectAtIndex:sourceIndexPath.row];
    if (self.itemsByTag[currentTagKey].count == 0) self.itemsByTag[currentTagKey] = nil;
    
    if (self.itemsByTag[reorderedTagKey] == nil) self.itemsByTag[reorderedTagKey] = [NSMutableArray new];
    [self.itemsByTag[reorderedTagKey] insertObject:reorderedListItem atIndex:destinationIndexPath.row];
    
    self.previouslyReorderedItem = reorderedListItem;
}

- (void)updateList:(SSList *)list
{
    self.list = list;
}

- (void)updateFromSnapshot:(DiffSnapShot *)snapshot
{
    NSMutableDictionary <SSListTag *, NSMutableArray <SSListItem *> *> *itemsByTag = [NSMutableDictionary new];

    NSArray <SSListItem *> *listItems = [snapshot.itemIdentifiers sortedArrayUsingComparator:^NSComparisonResult(SSListItem *obj1, SSListItem *obj2) {
        if (obj1.orderingIndex.integerValue == obj2.orderingIndex.integerValue) {
            return [obj1.objCKRecord.creationDate compare:obj2.objCKRecord.creationDate] == NSOrderedAscending;
        }
        
        return obj1.orderingIndex.integerValue > obj2.orderingIndex.integerValue;
    }];
    
    for (SSListItem *listItem in listItems)
    {
        SSListTag *listItemTag = listItem.tag;
        
        if (listItemTag == nil)
        {
            if (itemsByTag[self.miscTag] == nil) itemsByTag[self.miscTag] = [NSMutableArray new];
            [itemsByTag[self.miscTag] addObject:listItem];
        }
        else
        {
            if (itemsByTag[listItem.tag] == nil) itemsByTag[listItem.tag] = [NSMutableArray new];
            [itemsByTag[listItem.tag] addObject:listItem];
        }
    }
    
    self.itemsByTag = itemsByTag;
    
    [self updateSortedTags];
}

@end
