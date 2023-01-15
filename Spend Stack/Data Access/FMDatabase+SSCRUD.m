//
//  FMDatabase+SSCRUD.m
//  Spend Stack
//
//  Created by Jordan Morgan on 12/5/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "FMDatabase+SSCRUD.h"
#import "SSObject.h"
#import <LinkPresentation/LinkPresentation.h>

@implementation FMDatabase (SSCRUD)

#pragma mark - Lists CRUD

- (BOOL)insertListIntoDB:(SSList *)list
{
    BOOL success = [self executeUpdate:sql_ListInsert,
                    list.dbID,
                    list.name,
                    list.dateCreated,
                    list.orderingIndex,
                    list.totalCost,
                    @(list.locked),
                    @(list.isShowingCheckboxes),
                    @(list.totalDisplayType),
                    list.currencyIdentifier,
                    [list dataForRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list into FMDB.");
    return success;
}

- (BOOL)insertListIntoDBWithRecord:(CKRecord *)listRecord
{
    BOOL success = [self executeUpdate:sql_ListInsert,
                    listRecord.recordID.recordName,
                    listRecord[@"name"],
                    listRecord[@"dateCreated"],
                    listRecord[@"listOrderingIndex"],
                    listRecord[@"totalCost"],
                    listRecord[@"locked"],
                    listRecord[@"showingCheckboxes"] ?: @(0),
                    listRecord[@"totalDisplayType"] ?: @0,
                    listRecord[@"currencyIdentifier"],
                    [NSKeyedArchiver ss_secureArchive:listRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list into FMDB.");
    return success;
}

- (BOOL)updateListInDB:(SSList *)list
{
    BOOL success = [self executeUpdate:sql_ListUpdate,
                    list.name,
                    list.orderingIndex,
                    @(list.locked),
                    list.totalCost,
                    @(list.showingCheckboxes),
                    @(list.totalDisplayType),
                    list.currencyIdentifier,
                    [list dataForRecord],
                    list.dbID];
    NSAssert(success, @"Spend Stack - Problem updating list in FMDB.");
    return success;
}

- (BOOL)updateListInDBWithRecord:(CKRecord *)listRecord
{
    BOOL success = [self executeUpdate:sql_ListUpdate,
                    listRecord[@"name"],
                    listRecord[@"listOrderingIndex"],
                    listRecord[@"locked"],
                    listRecord[@"totalCost"],
                    listRecord[@"showingCheckboxes"] ?: @(0),
                    listRecord[@"totalDisplayType"] ?: @0,
                    listRecord[@"currencyIdentifier"],
                    [NSKeyedArchiver ss_secureArchive:listRecord],
                    listRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating list in FMDB.");
    return success;
}

- (BOOL)updateListRecord:(CKRecord * _Nonnull)listRecord
{
    BOOL success = [self executeUpdate:sql_ListUpdateRecord,
                    [NSKeyedArchiver ss_secureArchive:listRecord],
                    listRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Proble updating list item record in FMDB.");
    return success;
}

- (BOOL)deleteListInDB:(SSList *)list
{
    [self executeUpdate:@"PRAGMA foreign_keys = ON;"];
    BOOL success = [self executeUpdate:sql_ListDelete,
                    list.dbID];
    NSAssert(success, @"Spend Stack - Problem deleting list from FMDB.");
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_LISTS_WERE_DELETED object:@[list.dbID]];
    return success;
}

- (BOOL)deleteListsInDB:(NSArray<NSString *> *)listIDs
{
    [self executeUpdate:@"PRAGMA foreign_keys = ON;"];
    NSString *deletionString = [self stringifyArrayOfIDs:listIDs];
    BOOL success = [self executeUpdate:[sql_ListIDsDelete stringByAppendingString:deletionString]];
    NSAssert(success, @"Spend Stack - Problem deleting lists from FMDB.");
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_LISTS_WERE_DELETED object:listIDs];
    return success;
}

- (BOOL)listExistsForID:(NSString *)dbID
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM lists where listID = (?)", dbID];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

#pragma mark - Tax Rate Info CRUD

- (BOOL)insertTaxRateInfoIntoDB:(SSTaxRateInfo *)taxRateInfo
{
    NSString *taxRateString = taxRateInfo.taxRate ? [taxRateInfo.taxRate stringValue] : @"0.00";
    BOOL success = [self executeUpdate:sql_TaxRateInfoInsert,
                    taxRateInfo.dbID,
                    taxRateInfo.fkListID,
                    taxRateString,
                    @(taxRateInfo.taxEnabled),
                    taxRateInfo.localSalesTaxLocation,
                    taxRateInfo.didManuallySet ? taxRateInfo.didManuallySet : [NSNull null],
                    [NSKeyedArchiver ss_secureArchive:taxRateInfo.reference],
                    [taxRateInfo dataForRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list tax info into FMDB.");
    return success;
}

- (BOOL)insertTaxRateInfoIntoDBWithRecord:(CKRecord *)taxRateInfoRecord
{
    NSString *fkListID;
    FMResultSet *result = [self executeQuery:@"SELECT listID FROM Lists WHERE listID = (?);", ((CKReference *)taxRateInfoRecord[@"reference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListID = [result stringForColumn:@"listID"];
    }
    
    NSString *taxRateString = taxRateInfoRecord[@"taxRate"] ? taxRateInfoRecord[@"taxRate"] : @"0.00";
    id location = taxRateInfoRecord[@"localSalesTaxLocation"] ? taxRateInfoRecord[@"localSalesTaxLocation"] : [NSNull null];
    id didManuallySet = taxRateInfoRecord[@"didManuallySet"] ? taxRateInfoRecord[@"didManuallySet"] : [NSNull null];
    
    BOOL success = [self executeUpdate:sql_TaxRateInfoInsert,
                    taxRateInfoRecord.recordID.recordName,
                    fkListID,
                    taxRateString,
                    taxRateInfoRecord[@"taxEnabled"],
                    location,
                    didManuallySet,
                    [NSKeyedArchiver ss_secureArchive:taxRateInfoRecord[@"reference"]],
                    [NSKeyedArchiver ss_secureArchive:taxRateInfoRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list tax info into FMDB.");
    return success;
}

- (BOOL)updateTaxRateInfoInDB:(SSTaxRateInfo *)taxRateInfo
{
    NSString *taxRateString = taxRateInfo.taxRate ? [taxRateInfo.taxRate stringValue] : @"0.00";
    BOOL success = [self executeUpdate:sql_TaxRateInfoUpdate,
                    taxRateString,
                    @(taxRateInfo.taxEnabled),
                    taxRateInfo.localSalesTaxLocation,
                    taxRateInfo.didManuallySet ? taxRateInfo.didManuallySet : [NSNull null],
                    [taxRateInfo dataForRecord],
                    taxRateInfo.dbID];
    NSAssert(success, @"Spend Stack - Problem updating list tax info into FMDB.");
    return success;
}

- (BOOL)updateTaxRateInfoInDBWithRecord:(CKRecord *)taxRateInfoRecord
{
    NSString *taxRateString = taxRateInfoRecord[@"taxRate"] ? taxRateInfoRecord[@"taxRate"] : @"0.00";
    id location = taxRateInfoRecord[@"localSalesTaxLocation"] ? taxRateInfoRecord[@"localSalesTaxLocation"] : [NSNull null];
    id didManuallySet = taxRateInfoRecord[@"didManuallySet"] ? taxRateInfoRecord[@"didManuallySet"] : [NSNull null];
    
    BOOL success = [self executeUpdate:sql_TaxRateInfoUpdate,
                    taxRateString,
                    taxRateInfoRecord[@"taxEnabled"],
                    location,
                    didManuallySet,
                    [NSKeyedArchiver ss_secureArchive:taxRateInfoRecord],
                    taxRateInfoRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating list tax info into FMDB.");
    return success;
}

- (BOOL)updateTaxRateInfoRecord:(CKRecord *)taxRateInfoRecord
{
    BOOL success = [self executeUpdate:sql_TaxRateUpdateRecord,
                    [NSKeyedArchiver ss_secureArchive:taxRateInfoRecord],
                    taxRateInfoRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Proble updating tax rate info record in FMDB.");
    return success;
}

- (BOOL)deleteTaxRateInfoInDB:(SSTaxRateInfo *)taxRateInfo
{
    BOOL success = [self executeUpdate:sql_TaxRateInfoDelete,
                    taxRateInfo.dbID];
    NSAssert(success, @"Spend Stack - Problem deleting list tax info in FMDB.");
    return success;
}

- (BOOL)deleteTaxRatesInDB:(NSArray<NSNumber *> *)taxRateIDs
{
    NSString *deletionString = [self stringifyArrayOfIDs:taxRateIDs];
    BOOL success = [self executeUpdate:[sql_TaxRateIDsDelete stringByAppendingString:deletionString]];
    NSAssert(success, @"Spend Stack - Problem deleting tax rates from FMDB.");
    return success;
}

- (BOOL)taxRateExistsForID:(NSString *)dbID
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM ListTaxRateInfo where taxRateInfoID = (?)", dbID];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

#pragma mark - Tag CRUD

- (BOOL)insertTagIntoDB:(SSTag *)tag
{
    BOOL success = [self executeUpdate:sql_TagInsert,
                    tag.dbID,
                    tag.color,
                    tag.name,
                    tag.orderingIndex,
                    [tag dataForRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting tag into FMDB.");
    return success;
}

- (BOOL)insertTagIntoDBWithRecord:(CKRecord *)tagRecord
{
    BOOL success = [self executeUpdate:sql_TagInsert,
                    tagRecord.recordID.recordName,
                    tagRecord[@"color"],
                    tagRecord[@"name"],
                    tagRecord[@"tagOrderingIndex"],
                    [NSKeyedArchiver ss_secureArchive:tagRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting tag into FMDB.");
    return success;
}

- (BOOL)updateTagInDB:(SSTag *)tag
{
    BOOL success = [self executeUpdate:sql_TagUpdate,
                    tag.color,
                    tag.name,
                    tag.orderingIndex,
                    [tag dataForRecord],
                    tag.dbID];
    
    NSAssert(success, @"Spend Stack - Problem updating tag in FMDB.");
    return success;
}

- (BOOL)updateTagInDBWithRecord:(CKRecord *)tagRecord
{
    BOOL success = [self executeUpdate:sql_TagUpdate,
                    tagRecord[@"color"],
                    tagRecord[@"name"],
                    tagRecord[@"tagOrderingIndex"],
                    [NSKeyedArchiver ss_secureArchive:tagRecord],
                    tagRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating tag in FMDB.");
    return success;
}

- (BOOL)updateTagRecord:(CKRecord *)tagRecord
{
    BOOL success = [self executeUpdate:sql_TagUpdateRecord,
                    [NSKeyedArchiver ss_secureArchive:tagRecord],
                    tagRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating tag record in FMDB.");
    return success;
}

- (BOOL)deleteTagInDB:(SSTag *)tag
{
    [self executeUpdate:@"PRAGMA foreign_keys = ON;"];
    BOOL success = [self executeUpdate:sql_TagDelete,
                    tag.dbID];
    NSAssert(success, @"Spend Stack - Problem deleting tag in FMDB.");
    return success;
}

- (BOOL)deleteTagsInDB:(NSArray<NSString *> *)tagIDs
{
    NSString *deletionString = [self stringifyArrayOfIDs:tagIDs];
    BOOL success = [self executeUpdate:[sql_TagIDsDelete stringByAppendingString:deletionString]];
    NSAssert(success, @"Spend Stack - Problem deleting tags from FMDB.");
    return success;
}

- (BOOL)tagExistsForID:(NSString *)dbID
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM Tags where tagID = (?)", dbID];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

#pragma mark - List Tags CRUD

- (BOOL)insertListTagIntoDB:(SSListTag *)tag
{
    BOOL success = [self executeUpdate:sql_ListTagInsert,
                    tag.dbID,
                    tag.fkListID,
                    tag.fkTagID,
                    tag.color,
                    tag.name,
                    tag.orderingIndex,
                    [NSKeyedArchiver ss_secureArchive:tag.listReference],
                    [NSKeyedArchiver ss_secureArchive:tag.listTagReference],
                    [tag dataForRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list tag into FMDB.");
    return success;
}

- (BOOL)insertListTagIntoDBWithRecord:(CKRecord *)tagRecord
{
    NSString *fkListID;
    id fkListTagID = [NSNull null]; // Will be NULL if this tag came in via a share from someone else since they won't have the master tag
    FMResultSet *result = [self executeQuery:@"SELECT tagID FROM Tags WHERE tagID = (?);", ((CKReference *)tagRecord[@"listTagReference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListTagID = [result stringForColumn:@"tagID"];
    }
    
    result = [self executeQuery:@"SELECT listID FROM Lists WHERE listID = (?);", ((CKReference *)tagRecord[@"listReference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListID = [result stringForColumn:@"listID"];
    }
    
    if (fkListID == nil)
    {
        // The tag's list doesn't exist anymore
        return [self deleteListTagInDBWithRecord:tagRecord];
    }
    
    BOOL success = [self executeUpdate:sql_ListTagInsert,
                    tagRecord.recordID.recordName,
                    fkListID,
                    fkListTagID,
                    tagRecord[@"color"],
                    tagRecord[@"name"],
                    tagRecord[@"listTagOrderingIndex"],
                    [NSKeyedArchiver ss_secureArchive:tagRecord[@"listReference"]],
                    [NSKeyedArchiver ss_secureArchive:tagRecord[@"listTagReference"]],
                    [NSKeyedArchiver ss_secureArchive:tagRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list tag into FMDB.");
    return success;
}

- (BOOL)updateListTagInDB:(SSListTag *)tag
{
    BOOL success = [self executeUpdate:sql_ListTagUpdate,
                    tag.fkListID,
                    tag.fkTagID,
                    tag.color,
                    tag.name,
                    tag.orderingIndex,
                    [NSKeyedArchiver ss_secureArchive:tag.listReference],
                    [NSKeyedArchiver ss_secureArchive:tag.listTagReference],
                    [tag dataForRecord],
                    tag.dbID];
    NSAssert(success, @"Spend Stack - Problem updating list tag in FMDB.");
    return success;
}

- (BOOL)updateListTagInDBWithRecord:(CKRecord *)tagRecord
{
    NSString *fkListID;
    id fkListTagID = [NSNull null]; // Will be NULL if this tag came in via a share from someone else since they won't have the master tag
    FMResultSet *result = [self executeQuery:@"SELECT tagID FROM Tags WHERE tagID = (?);", ((CKReference *)tagRecord[@"listTagReference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListTagID = [result stringForColumn:@"tagID"];
    }
    
    result = [self executeQuery:@"SELECT listID FROM Lists WHERE listID = (?);", ((CKReference *)tagRecord[@"listReference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListID = [result stringForColumn:@"listID"];
    }
    
    if (fkListID == nil)
    {
        // The tag's list doesn't exist anymore
        return [self deleteListTagInDBWithRecord:tagRecord];
    }
    
    BOOL success = [self executeUpdate:sql_ListTagUpdate,
                    fkListID,
                    fkListTagID,
                    tagRecord[@"color"],
                    tagRecord[@"name"],
                    tagRecord[@"listTagOrderingIndex"],
                    [NSKeyedArchiver ss_secureArchive:tagRecord[@"listReference"]],
                    [NSKeyedArchiver ss_secureArchive:tagRecord[@"listTagReference"]],
                    [NSKeyedArchiver ss_secureArchive:tagRecord],
                    tagRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating list tag in FMDB.");
    return success;
}

- (BOOL)updateListTagRecord:(CKRecord *)tagRecord
{
    BOOL success = [self executeUpdate:sql_ListTagUpdateRecord,
                    [NSKeyedArchiver ss_secureArchive:tagRecord],
                    tagRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating list tag record in FMDB.");
    return success;
}

- (BOOL)deleteListTagInDB:(SSListTag *)tag
{
    BOOL success = [self executeUpdate:sql_ListTagDelete,
                    tag.dbID];
    NSAssert(success, @"Spend Stack - Problem deleting tag in FMDB.");
    return success;
}

- (BOOL)deleteListTagInDBWithRecord:(CKRecord *)record
{
    BOOL success = [self executeUpdate:sql_ListTagDelete,
                    record.recordID.recordName];
       NSAssert(success, @"Spend Stack - Problem deleting tag in FMDB.");
       return success;
}

- (BOOL)deleteListTagsInDB:(NSArray<NSString *> *)tagIDs
{
    NSString *deletionString = [self stringifyArrayOfIDs:tagIDs];
    BOOL success = [self executeUpdate:[sql_ListTagIDsDelete stringByAppendingString:deletionString]];
    NSAssert(success, @"Spend Stack - Problem deleting list tags from FMDB.");
    return success;
}

- (BOOL)listTagExistsForID:(NSString *)dbID
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM ListTags where listTagID = (?)", dbID];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

- (BOOL)listTagExistsForListID:(NSString *)listDBID masterTag:(SSTag *)masterTag
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM ListTags where listTagListID = (?) AND listTagMasterTagID = (?)", listDBID, masterTag.objCKRecord.recordID.recordName];
    NSUInteger count = 0;

    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }

    return count > 0;
}

#pragma mark - List Item CRUD

- (BOOL)insertListItemIntoDB:(SSListItem *)listItem taxInfo:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    // Nullables
    id fkTagIDInsertValue = listItem.fkTagID ? listItem.fkTagID : [NSNull null];
    id discountAmountInsertValue = listItem.discountAmount ? listItem.discountAmount : [NSNull null];
    id discountPercentageInsertValue = listItem.discountPercentage ? listItem.discountPercentage : [NSNull null];
    id weightInsertValue = listItem.weight ? @(listItem.weight.doubleValue).stringValue : [NSNull null];
    id notesInsertValue = listItem.notes ? listItem.notes : [NSNull null];
    id mediaAttachmentInsertValue = listItem.mediaAttachment ? [NSKeyedArchiver ss_archive:listItem.mediaAttachment] : [NSNull null];
    id mediaAssetDataInsertValue = listItem.mediaAssetData ? listItem.mediaAssetData : [NSNull null];
    id linkAttachmentInsertValue = listItem.linkAttachment ? listItem.linkAttachment : [NSNull null];
    id linkMetadataInsertValue = listItem.linkMetadata ? [NSKeyedArchiver ss_secureArchive:listItem.linkMetadata] : [NSNull null];
    id customDateInsertValue = listItem.customDate ? listItem.customDate : [NSNull null];
    id tagInsertValue = listItem.tagReference ? [NSKeyedArchiver ss_secureArchive:listItem.tagReference] : [NSNull null];
    id cardImportNameValue = listItem.cardImportName ?: [NSNull null];
    
    BOOL success = [self executeUpdate:sql_ListItemInsert,
                    listItem.dbID,
                    listItem.fkListID,
                    fkTagIDInsertValue,
                    @(listItem.checkedOff),
                    listItem.title,
                    listItem.orderingIndex,
                    @(listItem.hasTaxApplied),
                    listItem.baseAmount.stringValue,
                    discountAmountInsertValue,
                    discountPercentageInsertValue,
                    [listItem calcTotalAmount:taxInfo taxUtil:taxUtil].stringValue,
                    weightInsertValue,
                    @(listItem.quantity),
                    notesInsertValue,
                    @(listItem.recurringPricingCycle),
                    listItem.recurringPricingFrequency,
                    mediaAttachmentInsertValue,
                    mediaAssetDataInsertValue,
                    linkAttachmentInsertValue,
                    linkMetadataInsertValue,
                    customDateInsertValue,
                    cardImportNameValue,
                    tagInsertValue,
                    [NSKeyedArchiver ss_secureArchive:listItem.reference],
                    [listItem dataForRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list item into FMDB.");
    return success;
}

- (BOOL)insertListItemIntoDBWithRecord:(CKRecord *)listItemRecord
{
    NSString *fkListID;
    FMResultSet *result = [self executeQuery:@"SELECT listID FROM Lists WHERE listID = (?);", ((CKReference *)listItemRecord[@"reference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListID = [result stringForColumn:@"listID"];
    }
    
    if (fkListID == nil)
    {
        // Different database or the list is gone now, delete it
        NSLog(@"Spend Stack - Orphaned list item record, deleting locally.");
        return [self deleteListItemInDBWithRecord:listItemRecord];
    }
    
    NSString *fkTagID;
    result = [self executeQuery:@"SELECT listTagID FROM ListTags WHERE listTagID = (?);", ((CKReference *)listItemRecord[@"tagReference"]).recordID.recordName];
    
    while ([result next])
    {
        fkTagID = [result stringForColumn:@"listTagID"];
    }

    // Nullables
    id fkTagIDInsertValue = fkTagID  ? fkTagID : [NSNull null];
    id discountAmountInsertValue = listItemRecord[@"discountAmount"] ? listItemRecord[@"discountAmount"] : [NSNull null];
    id discountPercentageInsertValue = listItemRecord[@"discountPercentage"] ? listItemRecord[@"discountPercentage"] : [NSNull null];
    id weightInsertValue = listItemRecord[@"weight"] ? [listItemRecord[@"weight"] stringValue] : [NSNull null];
    id notesInsertValue = listItemRecord[@"notes"] ? listItemRecord[@"notes"] : [NSNull null];
    id recurringPriceInsert = listItemRecord[@"recurringPricingCycle"] ? listItemRecord[@"recurringPricingCycle"] : 0;
    id recurringPriceFreqInsert = listItemRecord[@"recurringPricingFrequency"] ? listItemRecord[@"recurringPricingFrequency"] : @(1);
    id mediaAttachmentInsertValue = listItemRecord[@"mediaAttachment"] ? [NSKeyedArchiver ss_archive:listItemRecord[@"mediaAttachment"]] : [NSNull null];
    id mediaAssetDataInsertValue = [NSNull null];
    if (mediaAttachmentInsertValue)
    {
        NSData *data = [NSData dataWithContentsOfURL:((CKAsset *)listItemRecord[@"mediaAttachment"]).fileURL];
        if (data)
        {
            mediaAssetDataInsertValue = data;
        }
    }
    id linkAttachmentInsertValue = listItemRecord[@"linkAttachment"] ? listItemRecord[@"linkAttachment"] : [NSNull null];
    id linkMetadataInsertValue = [NSNull null];
    id customDateInsertValue = listItemRecord[@"customDate"] ? listItemRecord[@"customDate"] : [NSNull null];
    id tagInsertValue = listItemRecord[@"tagReference"] ? [NSKeyedArchiver ss_secureArchive:listItemRecord[@"tagReference"]] : [NSNull null];
    id cardImportNameValue = listItemRecord[@"cardImportName"] ?: [NSNull null];
    
    // Get tax info for calculation
    result = [self executeQuery:sql_TaxRateSelectByTaxRateInfoListID, fkListID];
    
    SSTaxRateInfo *taxRate;
    while ([result next])
    {
        taxRate = [[SSTaxRateInfo alloc] initWithResultSet:result];
    }
    
    TaxUtility *taxUtil;
    NSString *currencyID = @"en_US";
    result = [self executeQuery:sql_ListSelectCurrencyIDByListID, fkListID];
    while ([result next])
    {
        currencyID = [result stringForColumn:@"currencyIdentifier"];
    }
    taxUtil = [[TaxUtility alloc] initWithLocaleID:currencyID];
    
    BOOL success = [self executeUpdate:sql_ListItemInsert,
                    listItemRecord.recordID.recordName,
                    fkListID,
                    fkTagIDInsertValue,
                    listItemRecord[@"checkedOff"],
                    listItemRecord[@"title"],
                    listItemRecord[@"listItemOrderingIndex"],
                    listItemRecord[@"hasTaxApplied"],
                    [listItemRecord[@"baseAmount"] stringValue],
                    discountAmountInsertValue,
                    discountPercentageInsertValue,
                    [SSListItem calcTotalAmountWithRecord:listItemRecord taxInfo:taxRate taxUtil:taxUtil].stringValue,
                    weightInsertValue,
                    listItemRecord[@"quantity"],
                    notesInsertValue,
                    recurringPriceInsert,
                    recurringPriceFreqInsert,
                    mediaAttachmentInsertValue,
                    mediaAssetDataInsertValue,
                    linkAttachmentInsertValue,
                    linkMetadataInsertValue,
                    customDateInsertValue,
                    cardImportNameValue,
                    tagInsertValue,
                    [NSKeyedArchiver ss_secureArchive:listItemRecord[@"reference"]],
                    [NSKeyedArchiver ss_secureArchive:listItemRecord]];
    NSAssert(success, @"Spend Stack - Problem inserting list item into FMDB.");
    return success;
}

- (BOOL)updateListItemInDB:(SSListItem *)listItem taxInfo:(SSTaxRateInfo *)taxInfo taxUtil:(TaxUtility *)taxUtil
{
    // Nullables
    id fkTagIDInsertValue = listItem.fkTagID ? listItem.fkTagID : [NSNull null];
    id discountAmountInsertValue = listItem.discountAmount ? listItem.discountAmount : [NSNull null];
    id discountPercentageInsertValue = listItem.discountPercentage ? listItem.discountPercentage : [NSNull null];
    id weightInsertValue = listItem.weight ? @(listItem.weight.doubleValue).stringValue : [NSNull null];
    id notesInsertValue = listItem.notes ? listItem.notes : [NSNull null];
    id mediaAttachmentInsertValue = listItem.mediaAttachment ? [NSKeyedArchiver ss_archive:listItem.mediaAttachment] : [NSNull null];
    id mediaAssetDataInsertValue = listItem.mediaAssetData ? listItem.mediaAssetData : [NSNull null];
    id linkAttachmentInsertValue = listItem.linkAttachment ? listItem.linkAttachment : [NSNull null];
    id linkMetadataInsertValue = listItem.linkMetadata ? [NSKeyedArchiver ss_secureArchive:listItem.linkMetadata] : [NSNull null];
    id customDateInsertValue = listItem.customDate ? listItem.customDate : [NSNull null];
    id tagInsertValue = listItem.tagReference ? [NSKeyedArchiver ss_secureArchive:listItem.tagReference] : [NSNull null];
    id cardImportNameValue = listItem.cardImportName ?: [NSNull null];
    
    BOOL success = [self executeUpdate:sql_ListItemUpdate,
                    listItem.fkListID,
                    fkTagIDInsertValue,
                    @(listItem.checkedOff),
                    listItem.title,
                    listItem.orderingIndex,
                    @(listItem.hasTaxApplied),
                    listItem.baseAmount.stringValue,
                    discountAmountInsertValue,
                    discountPercentageInsertValue,
                    [listItem calcTotalAmount:taxInfo taxUtil:taxUtil].stringValue,
                    weightInsertValue,
                    @(listItem.quantity),
                    notesInsertValue,
                    @(listItem.recurringPricingCycle),
                    listItem.recurringPricingFrequency,
                    mediaAttachmentInsertValue,
                    mediaAssetDataInsertValue,
                    linkAttachmentInsertValue,
                    linkMetadataInsertValue,
                    customDateInsertValue,
                    cardImportNameValue,
                    tagInsertValue,
                    [NSKeyedArchiver ss_secureArchive:listItem.reference],
                    [listItem dataForRecord],
                    listItem.dbID];
    NSAssert(success, @"Spend Stack - Problem updating list item in FMDB.");
    return success;
}

- (BOOL)updateListItemInDBWithRecord:(CKRecord *)listItemRecord
{
    NSString *fkListID;
    FMResultSet *result = [self executeQuery:@"SELECT listID FROM Lists WHERE listID = (?);", ((CKReference *)listItemRecord[@"reference"]).recordID.recordName];
    
    while ([result next])
    {
        fkListID = [result stringForColumn:@"listID"];
    }
    
    NSString *fkTagID;
    result = [self executeQuery:@"SELECT listTagID FROM ListTags WHERE listTagID = (?);", ((CKReference *)listItemRecord[@"tagReference"]).recordID.recordName];
    
    while ([result next])
    {
        fkTagID = [result stringForColumn:@"listTagID"];
    }

    // Nullables
    id fkTagIDInsertValue = fkTagID ? fkTagID : [NSNull null];
    id discountAmountInsertValue = listItemRecord[@"discountAmount"] ? listItemRecord[@"discountAmount"] : [NSNull null];
    id discountPercentageInsertValue = listItemRecord[@"discountPercentage"] ? listItemRecord[@"discountPercentage"] : [NSNull null];
    id weightInsertValue = listItemRecord[@"weight"] ? [listItemRecord[@"weight"] stringValue] : [NSNull null];
    id notesInsertValue = listItemRecord[@"notes"] ? listItemRecord[@"notes"] : [NSNull null];
    id recurringPriceInsert = listItemRecord[@"recurringPricingCycle"] ? listItemRecord[@"recurringPricingCycle"] : 0;
    id recurringPriceFreqInset = listItemRecord[@"recurringPricingFrequency"] ? listItemRecord[@"recurringPricingFrequency"] : @(1);
    id mediaAttachmentInsertValue = listItemRecord[@"mediaAttachment"] ? [NSKeyedArchiver ss_archive:listItemRecord[@"mediaAttachment"]] : [NSNull null];
    id mediaAssetDataInsertValue = [NSNull null];
    if (mediaAttachmentInsertValue)
    {
        NSData *data = [NSData dataWithContentsOfURL:((CKAsset *)listItemRecord[@"mediaAttachment"]).fileURL];
        if (data)
        {
            mediaAssetDataInsertValue = data;
        }
    }
    id linkAttachmentInsertValue = listItemRecord[@"linkAttachment"] ? listItemRecord[@"linkAttachment"] : [NSNull null];
    id linkMetadataInsertValue = [NSNull null];
    id customDateInsertValue = listItemRecord[@"customDate"] ? listItemRecord[@"customDate"] : [NSNull null];
    id tagInsertValue = listItemRecord[@"tagReference"] ? [NSKeyedArchiver ss_secureArchive:listItemRecord[@"tagReference"]] : [NSNull null];
    id cardImportNameValue = listItemRecord[@"cardImportName"] ?: [NSNull null];
    
    // Get tax info for calculation
    result = [self executeQuery:sql_TaxRateSelectByTaxRateInfoListID, fkListID];
    
    SSTaxRateInfo *taxRate;
    while ([result next])
    {
        taxRate = [[SSTaxRateInfo alloc] initWithResultSet:result];
    }
    
    TaxUtility *taxUtil;
    NSString *currencyID = @"en_US";
    result = [self executeQuery:sql_ListSelectCurrencyIDByListID, fkListID];
    while ([result next])
    {
        currencyID = [result stringForColumn:@"currencyIdentifier"];
    }
    taxUtil = [[TaxUtility alloc] initWithLocaleID:currencyID];

    // See if there's existing link metadata so we don't wipe it out. The metadata is local and doesn't sync,
    // So we don't want to erase it with a NULL insert it there's some already.
    if ([linkAttachmentInsertValue isEqual:[NSNull null]] == NO)
    {
        result = [self executeQuery:sql_ListItemSelectLinkMetadataByID, listItemRecord.recordID.recordName];
        while ([result next])
        {
            linkMetadataInsertValue = [result dataForColumn:@"linkMetadata"];
        }
    }
    
    BOOL success = [self executeUpdate:sql_ListItemUpdate,
                    fkListID,
                    fkTagIDInsertValue,
                    listItemRecord[@"checkedOff"],
                    listItemRecord[@"title"],
                    listItemRecord[@"listItemOrderingIndex"],
                    listItemRecord[@"hasTaxApplied"],
                    [listItemRecord[@"baseAmount"] stringValue],
                    discountAmountInsertValue,
                    discountPercentageInsertValue,
                    [SSListItem calcTotalAmountWithRecord:listItemRecord taxInfo:taxRate taxUtil:taxUtil].stringValue,
                    weightInsertValue,
                    listItemRecord[@"quantity"],
                    notesInsertValue,
                    recurringPriceInsert,
                    recurringPriceFreqInset,
                    mediaAttachmentInsertValue,
                    mediaAssetDataInsertValue,
                    linkAttachmentInsertValue,
                    linkMetadataInsertValue,
                    customDateInsertValue,
                    cardImportNameValue,
                    tagInsertValue,
                    [NSKeyedArchiver ss_secureArchive:listItemRecord[@"reference"]],
                    [NSKeyedArchiver ss_secureArchive:listItemRecord],
                    listItemRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem inserting list item into FMDB.");
    return success;
}

- (BOOL)updateListItemRecord:(CKRecord *)listItemRecord
{
    BOOL success = [self executeUpdate:sql_ListItemUpdateRecord,
                    [NSKeyedArchiver ss_secureArchive:listItemRecord],
                    listItemRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem updating list item record in FMDB.");
    return success;
}

- (BOOL)deleteListItemInDB:(SSListItem *)listItem
{
    BOOL success = [self executeUpdate:sql_ListItemDelete,
                    listItem.dbID];
    NSAssert(success, @"Spend Stack - Problem deleting list item in FMDB.");
    return success;
}

- (BOOL)deleteListItemInDBWithRecord:(CKRecord *)listItemRecord
{
    BOOL success = [self executeUpdate:sql_ListItemDelete,
                    listItemRecord.recordID.recordName];
    NSAssert(success, @"Spend Stack - Problem deleting list item via its CKRecord in FMDB.");
    return success;
}

- (BOOL)deleteListItemsInDB:(NSArray<NSNumber *> *)listItemIDs
{
    NSString *deletionString = [self stringifyArrayOfIDs:listItemIDs];
    BOOL success = [self executeUpdate:[sql_ListItemIDsDelete stringByAppendingString:deletionString]];
    NSAssert(success, @"Spend Stack - Problem deleting list items from FMDB.");
    return success;
}

- (BOOL)listItemExistsForID:(NSString *)dbID
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM ListItems where listItemID = (?)", dbID];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

#pragma mark - Awaiting Sync

- (BOOL)insertAwaitingSyncObject:(__kindof SSObject *)obj
{
    BOOL success = [self executeUpdate:sql_AwaitingSyncInsert,
                    obj.dbID,
                    obj.recordType,
                    [NSNull null],
                    @(0)];
    
    NSAssert(success, @"Spend Stack - Problem inserting awaiting sync data in FMDB.");
    return success;
}

- (BOOL)insertAwaitingDeleteSyncObject:(__kindof SSObject *)obj
{
    BOOL success = [self executeUpdate:sql_AwaitingSyncInsert,
                    obj.dbID,
                    obj.recordType,
                    [NSKeyedArchiver ss_secureArchive:obj.objCKRecord.recordID],
                    @(1)];
    
    NSAssert(success, @"Spend Stack - Problem inserting awaiting sync data in FMDB.");
    return success;
}

- (BOOL)deleteAwaitingSyncObjectWithSyncIDs:(NSArray<NSString *> *)syncIDs
{
    NSString *deletionString = [self stringifyArrayOfIDs:syncIDs];
    BOOL success = [self executeUpdate:[sql_AwaitingSyncIDsDelete stringByAppendingString:deletionString]];
    NSAssert(success, @"Spend Stack - Problem deleting awaiting sync data via syncID from FMDB.");
    return success;
}

- (BOOL)deleteAllAwaitingSyncObjects
{
    BOOL success = [self executeUpdate:sql_AwaitingSyncIDsDeleteAll];
    NSAssert(success, @"Spend Stack - Problem deleting all awaiting sync data from FMDB.");
    return success;
}

- (BOOL)resyncRecordExistsForID:(NSString *)dbID
{
    FMResultSet *result = [self executeQuery:@"SELECT COUNT(*) as count FROM AwaitingSyncData where syncID = (?)", dbID];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

- (BOOL)awaitingSyncHasData
{
    FMResultSet *result = [self executeQuery:sql_AwaitingSyncCount];
    NSUInteger count = 0;
    
    while ([result next])
    {
        count = [result intForColumn:@"count"];
    }
    
    return count > 0;
}

#pragma mark - Utils

- (NSInteger)mostRecentOrderingIndexForLists
{
    FMResultSet *result = [self executeQuery:@"select listOrderingIndex from lists ORDER BY listOrderingIndex DESC LIMIT 1"];
    NSUInteger mostRecentListOrderingIndex = 0;
    
    while ([result next])
    {
        mostRecentListOrderingIndex = [result intForColumn:@"listOrderingIndex"] + 1;
    }
    
    return mostRecentListOrderingIndex;
}

- (NSInteger)mostRecentOrderingIndexForTags
{
    FMResultSet *result = [self executeQuery:@"select tagOrderingIndex from tags ORDER BY tagOrderingIndex DESC LIMIT 1"];
    NSUInteger mostRecentTagOrderingIndex = 0;
    
    while ([result next])
    {
        mostRecentTagOrderingIndex = [result intForColumn:@"tagOrderingIndex"] + 1;
    }
    
    return mostRecentTagOrderingIndex;
}

- (NSArray <NSString *> *)recordsToDatabaseIDArray:(NSArray<CKRecord *> *)records
{
    NSMutableArray <NSString *> *dbIDs = [NSMutableArray new];
    for (CKRecord *record in records)
    {
        [dbIDs addObject:record.recordID.recordName];
    }
    
    return [dbIDs copy];
}

- (NSString *)stringifyArrayOfIDs:(NSArray *)deletionIDs
{
    NSString *idString = @"(";
    for (NSObject *deletionID in deletionIDs)
    {
        idString = [idString stringByAppendingString:[NSString stringWithFormat:@"\"%@\",", deletionID]];
    }
    
    // Take off the last comma, add the closing ')' and a semicolon
    idString = [idString substringToIndex:idString.length - 1];
    idString = [idString stringByAppendingString:@");"];
    
    return idString;
}

- (NSString *)stringifyArrayOfRecordToDatabaseIDs:(NSArray<CKRecord *> *)records
{
    NSString *idString = @"(";
    for (CKRecord *record in records)
    {
        idString = [idString stringByAppendingString:[NSString stringWithFormat:@"\"%@\",", record.recordID.recordName]];
    }
    
    // Take off the last comma, add the closing ')' and a semicolon
    idString = [idString substringToIndex:idString.length - 1];
    idString = [idString stringByAppendingString:@");"];
    
    return idString;
}

@end
