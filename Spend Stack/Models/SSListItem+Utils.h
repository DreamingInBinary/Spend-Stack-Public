//
//  SSListItem+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItem.h"
@class SSTagSelectionViewModel;

static NSString * _Nonnull const ss_ListItemActivityOpenWindowType = @"com.spendstack.openListItem";
static NSString * _Nonnull const ss_ListItemActivityOpenWindowTypeTitle = @"Open List Item";
static NSString * _Nonnull const ss_ListItemActivityOpenWindowTypeListUserInfoKey = @"listItem";

static NSString * _Nonnull const sql_ListItemCreateTable = @""
"CREATE TABLE IF NOT EXISTS ListItems ( "
"listItemID TEXT PRIMARY KEY, "
"listID TEXT NOT NULL, "
"tagID TEXT, "
"checkedOff INTEGER DEFAULT 0, "
"title TEXT NOT NULL, "
"listItemOrderingIndex INTEGER NOT NULL, "
"hasTaxApplied INTEGER NOT NULL DEFAULT 0, "
"baseAmount TEXT NOT NULL DEFAULT '0.00', "
"discountAmount TEXT, "
"discountPercentage TEXT, "
"totalCost TEXT NOT NULL DEFAULT '0.00', "
"weight TEXT, "
"quantity INTEGER NOT NULL DEFAULT 0, "
"notes TEXT, "
"recurringPricingCycle INTEGER DEFAULT 0, "
"recurringPricingFrequency INTEGER DEFAULT 1, "
"mediaAttachment BLOB, "
"mediaAssetData BLOB, "
"linkAttachment TEXT, "
"linkMetadata BLOB, "
"customDate REAL, "
"cardImportName TEXT, "
"listItemTagReference BLOB, "
"listItemReference BLOB NOT NULL, "
"listItemRecord BLOB NOT NULL, "
"FOREIGN KEY (listID) REFERENCES Lists(listID) ON DELETE CASCADE, "
"FOREIGN KEY (tagID) REFERENCES ListTags(listTagID) "
");";

static NSString * _Nonnull const sql_ListItemInsert = @""
"INSERT INTO "
"ListItems (listItemID, listID, tagID, checkedOff, title, listItemOrderingIndex, hasTaxApplied, baseAmount, discountAmount, discountPercentage, totalCost, weight, quantity, notes, recurringPricingCycle, recurringPricingFrequency, mediaAttachment, mediaAssetData, linkAttachment, linkMetadata, customDate, cardImportName, listItemTagReference, listItemReference, listItemRecord) "
"VALUES "
"(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

static NSString * _Nonnull const sql_ListItemUpdate = @""
"UPDATE ListItems "
"SET listID = (?), tagID = (?), checkedOff = (?), title = (?), listItemOrderingIndex = (?), hasTaxApplied = (?), baseAmount = (?), discountAmount = (?), discountPercentage = (?), totalCost = (?), weight = (?), quantity = (?), notes = (?), recurringPricingCycle = (?), recurringPricingFrequency = (?), mediaAttachment = (?), mediaAssetData = (?), linkAttachment = (?), linkMetadata = (?), customDate = (?), cardImportName = (?), listItemTagReference = (?), listItemReference = (?), listItemRecord = (?) "
"WHERE listItemID = (?);";

static NSString * _Nonnull const sql_ListItemUpdateRecord = @""
"UPDATE ListItems "
"SET listItemRecord = (?) "
"WHERE listItemID = (?);";

static NSString * _Nonnull const sql_ListItemDelete = @""
"DELETE FROM ListItems "
"WHERE listItemID = (?);";

static NSString * _Nonnull const sql_ListItemIDsDelete = @""
"DELETE FROM ListItems "
"WHERE listItemID IN ";

static NSString * _Nonnull const sql_ListItemSelectByIDs = @""
"SELECT * FROM ListItems "
"WHERE listItemID IN ";

static NSString * _Nonnull const sql_ListItemSelectByListID = @""
"SELECT li.listItemID, li.listID, li.tagID, li.checkedOff, li.title, li.listItemOrderingIndex, li.hasTaxApplied, li.baseAmount, li.discountAmount, li.discountPercentage, li.totalCost, li.weight, li.quantity, li.notes, li.recurringPricingCycle, li.recurringPricingFrequency, li.mediaAttachment, li.mediaAssetData, li.linkAttachment, li.linkMetadata, li.customDate, li.cardImportName, li.listItemTagReference, li.listItemReference, li.listItemRecord, t.listTagID, t.listTagMasterTagID, t.listTagListID, t.color, t.name, t.listTagOrderingIndex, t.listTagReference, t.listReference, t.listTagRecord "
"FROM ListItems as li "
"LEFT OUTER JOIN ListTags as t "
"ON li.tagID = t.listTagID "
"WHERE li.listID = (?); ";

static NSString * _Nonnull const sql_ListItemSelectByListItemID = @""
"SELECT li.listItemID, li.listID, li.tagID, li.checkedOff, li.title, li.listItemOrderingIndex, li.hasTaxApplied, li.baseAmount, li.discountAmount, li.discountPercentage, li.totalCost, li.weight, li.quantity, li.notes, li.recurringPricingCycle, li.recurringPricingFrequency, li.mediaAttachment, li.mediaAssetData, li.linkAttachment, li.linkMetadata, li.customDate, li.cardImportName, li.listItemTagReference, li.listItemReference, li.listItemRecord, t.listTagID, t.listTagMasterTagID, t.listTagListID, t.color, t.name, t.listTagOrderingIndex, t.listTagReference, t.listReference, t.listTagRecord "
"FROM ListItems as li "
"LEFT OUTER JOIN ListTags as t "
"ON li.tagID = t.listTagID "
"WHERE li.listItemID = (?); ";

static NSString * _Nonnull const sql_ListItemIDsSelectByListItemsContainingTagID = @""
"SELECT "
"* "
"FROM "
"ListItems "
"WHERE tagID = (?); ";

static NSString * _Nonnull const sql_ListItemSelectAll = @""
"SELECT "
"* "
"FROM "
"ListItems "
"LEFT OUTER JOIN ListTags "
"ON ListItems.tagID = ListTags.listTagID;";

static NSString * _Nonnull const sql_ListItemSelectLinkMetadataByID = @""
"SELECT linkMetadata FROM ListItems "
"WHERE listItemID = (?);";

#pragma mark - Triggers

static NSString * _Nonnull const sql_ListItemRemoveTagWhenMasterTagDeletesTrigger = @""
"CREATE TRIGGER IF NOT EXISTS listItemRemoveTagWhenMasterTagDeletesTrigger AFTER DELETE "
"ON ListTags "
"BEGIN "
"UPDATE ListItems "
"SET tagID = NULL "
"WHERE ListItems.tagID = old.listTagID; "
"END; ";

@interface SSListItemMediaAttachResult:NSObject

@property (strong, nonatomic, nonnull) NSData *data;
@property (strong, nonatomic, nonnull) CKAsset *asset;
@property (strong, nonatomic, nonnull) UIImage *image;

@end

@interface SSListItem (Utils)

+ (NSDecimalNumber * _Nonnull)calcSubtotalAmountWithRecord:(CKRecord * _Nonnull)record;
+ (NSDecimalNumber * _Nonnull)calcTaxedAmountWithRecord:(CKRecord * _Nonnull)record
                                                taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo
                                                taxUtil:(TaxUtility * _Nonnull)taxUtil;
+ (NSDecimalNumber * _Nonnull)calcActualDiscountOffPriceWithRecord:(CKRecord * _Nonnull)record;
+ (NSDecimalNumber * _Nonnull)calcTotalAmountWithRecord:(CKRecord * _Nonnull)record
                                                taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo
                                                taxUtil:(TaxUtility * _Nonnull)taxUtil;

- (BOOL)checkHasDiscountAmountApplied;
- (BOOL)checkHasDiscountPercentageApplied;
- (BOOL)checkHasDiscountApplied;
- (BOOL)checkHasWeightedPricing;
- (BOOL)checkIsNegativeAmount;
- (BOOL)checkIsUsingRecurringPricing;
- (BOOL)checkHasMediaAttachment;
- (BOOL)checkHasLinkAttachment;
- (BOOL)itemHasNoExtraDetails:(SSTaxRateInfo * _Nonnull)taxInfo;
- (BOOL)itemHasOnlyLeadingExtraDetails:(SSTaxRateInfo * _Nonnull)taxInfo;
- (BOOL)itemHasOnlyTrailingExtraDetails:(SSTaxRateInfo * _Nonnull)taxInfo;
- (BOOL)itemHasAllExtraDetails:(SSTaxRateInfo * _Nonnull)taxInfo;
- (NSDecimalNumber * _Nonnull)calcSubtotalAmount;
- (NSDecimalNumber * _Nonnull)calcTaxedAmount:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (NSDecimalNumber * _Nonnull)calcActualDiscountOffPrice;
- (NSDecimalNumber * _Nonnull)calcTotalAmount:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (NSDecimalNumber * _Nonnull)calcTotalRecurringCostDaily:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (NSDecimalNumber * _Nonnull)calcTotalRecurringCostWeekly:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (NSDecimalNumber * _Nonnull)calcTotalRecurringCostMonthly:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (NSDecimalNumber * _Nonnull)calcTotalRecurringCostYearly:(SSTaxRateInfo * _Nonnull)taxInfo taxUtil:(TaxUtility * _Nonnull)taxUtil;
- (SSListItemMediaAttachResult * _Nonnull)generateNewMediaItemResultFromData:(NSData * _Nonnull)data;
- (NSString * _Nonnull)modifiderDataString:(TaxUtility * _Nonnull)taxUtil;
- (SSTagSelectionViewModel * _Nullable)createTagViewModel;
- (NSString * _Nonnull)recurringPriceDisplayString;

@end
