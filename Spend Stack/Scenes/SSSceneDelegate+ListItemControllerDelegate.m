//
//  SSSceneDelegate+ListItemControllerDelegate.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/8/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSSceneDelegate+ListItemControllerDelegate.h"
#import "Spend_Stack_2-Swift.h"

@implementation SSSceneDelegate (ListItemControllerDelegate)

- (BOOL)shouldReflectSingleWindowUI
{
    return YES;
}

- (void)requestCloseSceneSessionForListItemController:(UISceneSession *)sceneSession
{
    [[UIApplication sharedApplication] requestSceneSessionDestruction:sceneSession options:nil errorHandler:^(NSError * _Nonnull error) {
        
    }];
}

- (void)onEditsCommitted:(SSListItem * _Nonnull)editedListItem
{
    FMDatabaseQueue *readWriteQueue = [FMDatabaseQueue databaseQueueWithPath:[SSDataStore databaseFilePath]];
    [readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, editedListItem.fkListID];
        SSList *list;
        while ([result next])
        {
            list = [[SSList alloc] initWithResultSet:result];
        }
        
        [list.datasourceAdapter applyEditsToItem:editedListItem];
        BOOL success = [db updateListItemInDB:editedListItem taxInfo:list.taxInfo taxUtil:list.taxUtil];
        NSLog(@"Spend Stack - Updated list item successfully:%@", @(success));
        
        [[list dbForList] saveObjects:@[editedListItem]
                       withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                        deleteObjects:@[]
                       withCompletion:^(NSError *possibleError) {
                           NSLog(@"Spend Stack - Saved edits for item %@ (Error: %@)", editedListItem.title, possibleError.localizedRecoveryOptions);
                       }];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            SSListItemBroadcaster *broadcaster = [SSListItemBroadcaster listItemBroadcasterWithWindow:self.window];
            broadcaster.listItem = editedListItem;
            broadcaster.event = BroadcastEventTypeUpdate;
            [broadcaster post];
            
            // For new swift files and combine
            [ExternalListCRUDPayloadShim sendExternalListCRUDPayloadWithList:list];
        });
    }];
}

- (BOOL)requestDeleteItem:(SSListItem * _Nonnull)itemToDelete
{
    SSList *parentList = [[SSDataStore sharedInstance] queryListByID:itemToDelete.fkListID];
    NSIndexPath *idp = [parentList.datasourceAdapter indexPathForListItem:itemToDelete];
    [parentList.datasourceAdapter refreshTags];
    [parentList removeItem:itemToDelete];
    
    SSListItemBroadcaster *listItemBroadcaster = [SSListItemBroadcaster listItemBroadcasterWithWindow:self.window];
    listItemBroadcaster.event = BroadcastEventTypeDelete;
    listItemBroadcaster.eventInfo = @{@"indexPath":idp};
    listItemBroadcaster.listItem = itemToDelete;
    [listItemBroadcaster post];
    
    [ExternalListCRUDPayloadShim sendExternalListCRUDPayloadWithList:parentList];
    
    return YES;
}

@end
