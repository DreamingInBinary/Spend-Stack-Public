//
//  SSListTag+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListTag+Utils.h"
#import "SSTagSelectionViewModel.h"

@implementation SSListTag (Utils)

+ (SSListTag *)miscTag
{
    return [[SSListTag alloc] initForMiscTag];
}

+ (SSTag *)masterTagForListItem:(SSListItem *)listItem
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block SSTag *masterTag;
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase *db) {
        masterTag = [SSListTag masterTagForListItem:listItem db:db];
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return masterTag;
}

+ (SSTag *)masterTagForListItem:(SSListItem *)listItem db:(FMDatabase *)db
{
    return [SSListTag masterTagForListTagID:listItem.tag.fkTagID db:db];
}

+ (SSTag *)masterTagForListTagID:(NSString *)listTagID db:(FMDatabase *)db
{
    FMResultSet *result = [db executeQuery:sql_TagSelectByTagID, listTagID];
    SSTag *masterTag;
    
    while ([result next])
    {
        masterTag = [[SSTag alloc] initWithResultSet:result];
    }
    
    return masterTag;
}

+ (NSArray <SSListTag *> *)listTagsForMasterTag:(SSTag *)tag inDB:(FMDatabase * _Nonnull)db
{
    // These updates are always your own DB because if you're editing a tag, you own it.
    FMResultSet *result = [db executeQuery:sql_ListTagSelectByTagID, tag.dbID];
    NSMutableArray <SSListTag *> *listTags = [NSMutableArray new];
    
    while ([result next])
    {
        SSListTag *tag = [[SSListTag alloc] initWithResultSet:result];
        [listTags addObject:tag];
    }
    
    return listTags;
}

+ (NSArray <SSListTag *> *)listTagsForSharedDatabase:(NSArray<SSListTag *> *)listTags
{
    NSMutableArray <SSListTag *> *tags = [NSMutableArray new];
    
    for (SSListTag *listTag in listTags)
    {
        if ([listTag.listReference isSharedWithMe])
        {
            [tags addObject:listTag];
        }
    }
    
    return tags;
}

#pragma mark - Instance Methods

- (BOOL)tagIsSharedWithMe
{
    if (self == nil) return NO;
    // If it's nil, we don't have the master tag. This means it was a tag that was shared to you.
    return self.fkTagID == nil;
}

@end
