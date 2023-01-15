//
//  SSTag+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTag+Utils.h"

@implementation SSTag (Utils)

+ (SSTag *)masterTagForListTag:(SSListTag *)listTag 
{
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF.dbID = %@", listTag.fkTagID];
    return [[[SSDataStore sharedInstance] queryAllMasterTags] filteredArrayUsingPredicate:searchPredicate].firstObject;
}

+ (UIColor *)rawColorFromColor:(NSString *)colorString
{
    return [colorString isEqualToString:@"clear"] ? [SSTag miscTagDisplayColor] : [UIColor performSelector:NSSelectorFromString(colorString)];
}

+ (iCloudTagsDictionary *)tagsByCloudDB:(SSTag *)masterTag localDBConnection:(FMDatabase *)db
{
    // Update any list tags that are associated with the master tag on the server. Locally,
    // These are updated via SQLite triggers.
    NSMutableArray <__kindof SSObject *> *tagsToSave = [NSMutableArray new];
    [tagsToSave addObject:masterTag];
    NSMutableArray <SSListTag *> *listTagsForMasterTag = [[SSListTag listTagsForMasterTag:masterTag inDB:db] mutableCopy];
    
    // If we are not the list owner for some of these, save them in the shared DB.
    // Even if the master tag originated from us, the list we're in might not be ours.
    NSArray <SSListTag *> *listTagsForShare = [SSListTag listTagsForSharedDatabase:listTagsForMasterTag];
    [listTagsForMasterTag removeObjectsInArray:listTagsForShare];
    
    // These go in our private DB - we own all of these lists even if it's shared.
    [tagsToSave addObjectsFromArray:listTagsForMasterTag];
    
    return @{SS_TAGS_IN_MY_DB:tagsToSave, SS_TAGS_IN_SHARED_DB:listTagsForShare};
}

+ (void)saveListItemIDsUsingTagToBeDeleted:(FMDatabase * _Nonnull)db tag:(SSTag *)tag
{
    // Save the listItem's ID who used a list tag coming from this master tag.
    // A delete trigger will make their fkTagID NULL when deleting a tag.
    // The reason we do this is, if they restore the tag we have to make a new recordID for it.
    // This means we need to re-add the new tagID to the listItems that had it before it was deleted.
    FMResultSet *result = [db executeQuery:sql_ListTagSelectListItemIDsUsingListTagsFromTagID, tag.dbID];
    NSMutableArray <NSString *> *listItemIDsUsingTag = [NSMutableArray new];

    while ([result next])
    {
        NSString *listItemID = [result stringForColumn:@"listItemID"];
        [listItemIDsUsingTag addObject:listItemID];
    }
    
    [ss_defaults() setObject:listItemIDsUsingTag
                                              forKey:SS_LIST_ITEM_IDS_RECENTLY_DELETED_TAG];
}

+ (void)restoreTagAndReassociateListItemForeignKeysToTag:(SSTag *)tag database:(FMDatabase *)db
{
    // Find listItems of all listItems that were using the tag (tracked before deletion of the tag)
    NSArray <NSString *> *listItemIDsUsingRestoringTag = [ss_defaults()
                                                          objectForKey:SS_LIST_ITEM_IDS_RECENTLY_DELETED_TAG];
    NSMutableArray <SSListItem *> *listItemsUsingTag = [NSMutableArray new];

    NSString *selectionString = [db stringifyArrayOfIDs:listItemIDsUsingRestoringTag];
    FMResultSet *result = [db executeQuery:[sql_ListItemSelectByIDs stringByAppendingString:selectionString]];
    while ([result next])
    {
        SSListItem *listItem = [[SSListItem alloc] initWithResultSet:result];
        [listItemsUsingTag addObject:listItem];
    }
    
    // Put new records on the restored tag, starting with the master tag
    [tag initializeNewRecordsForRedoWithZoneID:nil];
    [db insertTagIntoDB:tag];

    NSMutableArray <SSListItem *> *myListItems = [NSMutableArray new];
    NSMutableArray <SSListItem *> *sharedListItems = [NSMutableArray new];
    
    // Associate the tag back to them with its new database ID
    // Save them in the database.
    for (SSListItem *listItem in listItemsUsingTag)
    {
        FMResultSet *listItemRes = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, listItem.fkListID];
        SSList *itemList;
        while ([listItemRes next])
        {
            itemList = [[SSList alloc] initWithResultSet:listItemRes];
        }

        if ([itemList listIsSharedWithMe])
        {
            SSListTag *listTag = [listItem listTagFromMasterTagInDatabase:db list:itemList tag:tag];
            [listItem addSharedListTag:listTag withList:itemList];
            [sharedListItems addObject:listItem];
        }
        else
        {
            [listItem addListTag:tag withList:itemList withDB:db];
            [myListItems addObject:listItem];
        }
        
        [db updateListItemInDB:listItem taxInfo:itemList.taxInfo taxUtil:itemList.taxUtil];
    }

    // Clear out cache of those list items IDs
    [ss_defaults() removeObjectForKey:SS_LIST_ITEM_IDS_RECENTLY_DELETED_TAG];

    // Hit cloudkit
    iCloudTagsDictionary *tagsByDB = [SSTag tagsByCloudDB:tag localDBConnection:db];
    
    NSMutableArray <__kindof SSObject *> *objectsForMe = [NSMutableArray new];
    NSMutableArray <__kindof SSObject *> *objectsSharedWithMe = [NSMutableArray new];
    
    // Local tag, list tags + items
    [objectsForMe addObjectsFromArray:myListItems];
    [objectsForMe addObjectsFromArray:tagsByDB[SS_TAGS_IN_MY_DB]];
    
    // Shared list tags + items
    [objectsSharedWithMe addObjectsFromArray:sharedListItems];
    [objectsSharedWithMe addObjectsFromArray:tagsByDB[SS_TAGS_IN_SHARED_DB]];
    
    [[SSDataStore sharedInstance].ckManager.privateDB saveObjects:objectsForMe
                                                   withSavePolicy:CKRecordSaveChangedKeys
                                                    deleteObjects:@[]
                                                   withCompletion:^(NSError * error) {
                                                       NSLog(@"Spend Stack - Restored tag, list tags and associated list items with error:(%@)", error);
                                                   }];
    
    if (objectsSharedWithMe.count > 0)
    {
        [[SSDataStore sharedInstance].ckManager.sharedDB saveObjects:objectsSharedWithMe
                                                       withSavePolicy:CKRecordSaveChangedKeys
                                                        deleteObjects:@[]
                                                       withCompletion:^(NSError * error) {
                                                           NSLog(@"Spend Stack - Restored list tags and list items in shared DB with error:(%@)", error);
                                                       }];
    }
}

#pragma mark - Instance Methods

- (UIColor *)rawColor
{
    return [self.color isEqualToString:@"clear"] ? [SSTag miscTagDisplayColor] : [UIColor performSelector:NSSelectorFromString(self.color)];
}

@end
