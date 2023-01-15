//
//  SSList+Utils.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSList+Utils.h"

@implementation SSList (Utils)

- (NSDecimalNumber *)calcBaseCost
{
    if (self.itemCount > 0)
    {
        double total = 0;
        
        for (SSListItem *listItem in self.datasourceAdapter.allItems)
        {
            total += [listItem calcSubtotalAmount].doubleValue;
        }
        
        return [[NSDecimalNumber alloc] initWithDouble:total];
    }
    
    return [[NSDecimalNumber alloc] initWithString:self.taxUtil.localizedPlaceholderAmount locale:self.taxUtil.currencyLocale];
}

- (NSDecimalNumber *)calcTaxAmount
{
    if (self.itemCount > 0)
    {
        double total = 0;
        
        for (SSListItem *listItem in self.datasourceAdapter.allItems)
        {
            total += [listItem calcTaxedAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
        }
        
        return [[NSDecimalNumber alloc] initWithDouble:total];
    }
    
    return [[NSDecimalNumber alloc] initWithString:self.taxUtil.localizedPlaceholderAmount locale:self.taxUtil.currencyLocale];
}

- (NSDecimalNumber *)calcDiscountAmount
{
    if (self.itemCount > 0)
    {
        double total = 0;
        
        for (SSListItem *listItem in self.datasourceAdapter.allItems)
        {
            total += [listItem calcActualDiscountOffPrice].doubleValue;
        }
        
        return [[NSDecimalNumber alloc] initWithDouble:total];
    }
    
    return [[NSDecimalNumber alloc] initWithString:self.taxUtil.localizedPlaceholderAmount locale:self.taxUtil.currencyLocale];
}

- (NSDecimalNumber *)calcTotalCost
{
    double total = 0;
    
    for (SSListItem *listItem in self.datasourceAdapter.allItems)
    {
        total += [listItem calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
    }
    
    return [[NSDecimalNumber alloc] initWithDouble:total];
}

- (NSDecimalNumber *)calcTotalCostFromDisplayType
{
    double total = 0;
    NSArray <SSListItem *> *items;
    
    switch (self.totalDisplayType)
    {
        case ListTotalDisplayAll:
            items = [self.datasourceAdapter allItems];
            break;
        case ListTotalDisplayOnlyChecked:
            items = [self.datasourceAdapter allCheckedItems];
            break;
        case ListTotalDisplayOnlyUnchecked:
            items = [self.datasourceAdapter allUncheckedItems];
            break;
        default:
            return [self calcTotalCost];
            break;
    }
    
    for (SSListItem *listItem in items)
    {
        total += [listItem calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
    }
    
    return [[NSDecimalNumber alloc] initWithDouble:total];
}

- (NSDecimalNumber *)calcTotalRecurringCost:(ListItemRecurringPricingChoice)recurringType
{
    double total = 0;
    
    for (SSListItem *listItem in [self recurringCostItems])
    {
        switch (recurringType)
        {
            case ListItemRecurringPricingChoiceDay:
                total += [listItem calcTotalRecurringCostDaily:self.taxInfo taxUtil:self.taxUtil].doubleValue;
                break;
            case ListItemRecurringPricingChoiceWeek:
                total += [listItem calcTotalRecurringCostWeekly:self.taxInfo taxUtil:self.taxUtil].doubleValue;
                break;
            case ListItemRecurringPricingChoiceMonth:
                total += [listItem calcTotalRecurringCostMonthly:self.taxInfo taxUtil:self.taxUtil].doubleValue;
                break;
            case ListItemRecurringPricingChoiceYear:
                total += [listItem calcTotalRecurringCostYearly:self.taxInfo taxUtil:self.taxUtil].doubleValue;
                break;
            default:
                break;
        }
    }
    
    return [[NSDecimalNumber alloc] initWithDouble:total];
}

- (double)itemTotalForTag:(SSListTag *)tag
{
    double total = 0.0;
    for (SSListItem *listItem in self.datasourceAdapter.itemsByTag[tag])
    {
        total += [listItem calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
    }
    
    return total;
}

- (NSNumber *)averageItemPrice
{
    double total = 0;
    double numberOfitems = self.datasourceAdapter.allItems.count;
    
    for (SSListItem *listItem in self.datasourceAdapter.allItems)
    {
        total += [listItem calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
    }
    
    if (numberOfitems == 0 || total == 0)
    {
        return @0;
    }
    
    return @(total/numberOfitems);
}

- (SSListItem *)mostExpensiveItem
{
    double amount = 0.0f;
    SSListItem *itemRef;
    for (SSListItem *item in self.datasourceAdapter.allItems)
    {
        double itemAmount = [item calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
        if (itemAmount == 0) continue;
        
        if (itemAmount == amount || itemAmount > amount)
        {
            amount = itemAmount;
            itemRef = [item copy];
        }
    }
    
    return itemRef;
}

- (SSListItem *)cheapestItem
{
    double amount = [[self mostExpensiveItem] calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
    SSListItem *itemRef;
    for (SSListItem *item in self.datasourceAdapter.allItems)
    {
        double itemAmount = [item calcTotalAmount:self.taxInfo taxUtil:self.taxUtil].doubleValue;
        if (itemAmount == 0) continue;
        
        if (itemAmount == amount || itemAmount < amount)
        {
            amount = itemAmount;
            itemRef = [item copy];
        }
    }
    
    return itemRef;
}

- (SSCloudKitDatabase *)dbForList
{
    if (self.objCKRecord.share.isSharedFromMe || self.objCKRecord.share == nil)
    {
        return [SSDataStore sharedInstance].ckManager.privateDB;
    }
    else
    {
        return [SSDataStore sharedInstance].ckManager.sharedDB;
    }
}

- (BOOL)listIsShared
{
    return self.objCKRecord.share != nil;
}

- (BOOL)listIsSharedWithMe
{
    return [self.objCKRecord.recordID.zoneID.ownerName localizedCaseInsensitiveContainsString:@"defaultowner"] == NO;
}

- (NSArray <SSListItem *> *)recurringCostItems
{
    NSArray <SSListItem *> *allItems = [self.datasourceAdapter allItems];
    NSPredicate *recurringPredicate = [NSPredicate predicateWithFormat:@"SELF.recurringPricingCycle != 0"];
    return [allItems filteredArrayUsingPredicate:recurringPredicate];
}

#pragma mark - Data Operators

- (void)saveOrderingForItemsWithDB:(FMDatabase *)db forceRefresh:(BOOL)forceRefresh
{
    NSArray <SSListItem *> *allItems = self.datasourceAdapter.allItems;
    
    for (SSListItem *listItem in allItems)
    {
        if (forceRefresh) listItem.orderingIndex = @([allItems indexOfObject:listItem]);
        BOOL success = [db updateListItemInDB:listItem taxInfo:self.taxInfo taxUtil:self.taxUtil];
        NSLog(@"Spend Stack - Succesfully updated list item: %@", @(success));
    }
    
    [[self dbForList] saveObjects:allItems
                    withSavePolicy:CKRecordSaveAllKeys
                     deleteObjects:@[]
                    withCompletion:^(NSError * error) {
        NSLog(@"Spend Stack - Saved new ordering indicies for list items with error:%@", error);
    }];
}

+ (void)moveListItems:(NSArray<SSListItem *> *)listItems fromList:(SSList *)fromlist toList:(SSList *)toList listTagID:(NSString *)listTagID completion:(nonnull void (^)(NSArray<SSListItem *> * _Nonnull, SSList * _Nonnull, SSList * _Nonnull, FMDatabase * _Nonnull))completion
{
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSMutableArray *updatedListItems = [NSMutableArray new];
        for (SSListItem *listItem in listItems)
        {
            [fromlist.datasourceAdapter removeItem:listItem];
            __block BOOL success = [db deleteListItemInDB:listItem];
            __block NSError *lastError;
            NSLog(@"Spend Stack - Successfully deleted item in database:%@", @(success));
            
            // Make a copy to remove the old CKRecord
            SSListItem *deepCopy = [listItem deepCopy];
            
            // Now save it to the new place and give it a new record
            [listItem resetReferenceForRedo:toList];
            [toList moveItemToList:listItem withListTagID:listTagID inDB:db];
            success = [db insertListItemIntoDB:listItem taxInfo:toList.taxInfo taxUtil:toList.taxUtil];
            NSLog(@"Spend Stack - Successfully inserted item in database:%@", @(success));
            
            [updatedListItems addObject:listItem];
            
            // Now commit to the cloud. Two different operations because they could have two different databases (i.e. a share)
            [[fromlist dbForList] saveObjects:@[]
                           withSavePolicy:CKRecordSaveAllKeys
                            deleteObjects:@[deepCopy]
                           withCompletion:^(NSError *possibleError) {
                NSLog(@"Spend Stack - Deleted item %@ (Error: %@)", listItem.title, possibleError.localizedDescription);
                lastError = possibleError;
                
                [[toList dbForList] saveObjects:@[listItem]
                               withSavePolicy:CKRecordSaveAllKeys
                                deleteObjects:@[]
                               withCompletion:^(NSError *possibleError) {
                    NSLog(@"Spend Stack - Saved item %@ (Error: %@)", listItem.title, possibleError.localizedDescription);
                    lastError = possibleError;
                }];
            }];
        }
        
        // Refresh data, pass it back to the caller
        SSList *updatedFromList;
        SSList *udpatedToList;
        
        FMResultSet *result = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, fromlist.dbID];
        
        while ([result next])
        {
            updatedFromList = [[SSList alloc] initWithResultSet:result];
        }
        
        result = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, toList.dbID];
        
        while ([result next])
        {
            udpatedToList = [[SSList alloc] initWithResultSet:result];
        }
        
        completion(updatedListItems, updatedFromList, udpatedToList, db);
    }];
}

@end
