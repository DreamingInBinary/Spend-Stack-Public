//
//  SSList+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/10/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSList.h"
#import "SSListItem.h"
@class SSListTag;

static NSString * _Nonnull const ss_ListActivityOpenWindowType = @"com.spendstack.openList";
static NSString * _Nonnull const ss_ListActivityOpenWindowTypeTitle = @"Open List";
static NSString * _Nonnull const ss_ListActivityOpenWindowTypeListUserInfoKey = @"list";
static NSString * _Nonnull const ss_ListUserActivityType = @"com.spendstack.openListFromUserActivity";

static NSString * _Nonnull const sql_ListCreateTable = @""
"CREATE TABLE IF NOT EXISTS Lists ( "
"listID TEXT PRIMARY KEY, "
"name TEXT, "
"dateCreated DATE, "
"itemCount INTEGER, "
"totalCost TEXT NOT NULL DEFAULT '0.00', "
"listOrderingIndex INTEGER, "
"locked INTEGER NOT NULL DEFAULT 0, "
"showingCheckboxes INTEGER NOT NULL DEFAULT 0, "
"totalDisplayType INTEGER NOT NULL DEFAULT 0, "
"currencyIdentifier TEXT, "
"listRecord BLOB "
");";

static NSString * _Nonnull const sql_ListSelectAll = @""
"SELECT "
"* "
"FROM "
"LISTS;";

static NSString * _Nonnull const sql_ListSelectRecord = @""
"SELECT listRecord "
"FROM LISTS = (?) "
"WHERE listID = (?);";

static NSString * _Nonnull const sql_ListSelectAllListRecords = @""
"SELECT listRecord "
"FROM LISTS;";

static NSString * _Nonnull const sql_ListWithTaxRateInfoSelectAll = @""
"SELECT l.listID, l.name, l.dateCreated, l.itemCount, l.totalCost, l.listOrderingIndex, l.locked, l.showingCheckboxes, l.totalDisplayType, l.currencyIdentifier, l.listRecord, t.taxRateInfoID, t.listID, t.taxRate, t.taxEnabled, t.localSalesTaxLocation, t.didManuallySet, t.taxInfoReference, t.taxInfoRecord "
"FROM Lists as l "
"INNER JOIN ListTaxRateInfo as t "
"on l.listID = t.listID "
"ORDER BY l.listOrderingIndex ASC";

static NSString * _Nonnull const sql_ListWithTaxRateInfoSelectFromListID = @""
"SELECT l.listID, l.name, l.dateCreated, l.itemCount, l.totalCost, l.listOrderingIndex, l.locked, l.showingCheckboxes, l.totalDisplayType, l.currencyIdentifier, l.listRecord, t.taxRateInfoID, t.listID, t.taxRate, t.taxEnabled, t.localSalesTaxLocation, t.didManuallySet, t.taxInfoReference, t.taxInfoRecord "
"FROM Lists as l "
"INNER JOIN ListTaxRateInfo as t "
"ON l.listID = t.listID "
"WHERE l.listID = (?)";

static NSString * _Nonnull const sql_ListInsert = @""
"INSERT INTO "
"LISTS (listID, name, dateCreated, listOrderingIndex, totalCost, locked, showingCheckboxes, totalDisplayType, currencyIdentifier, listRecord) "
"VALUES "
"(?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

static NSString * _Nonnull const sql_ListUpdate = @""
"UPDATE Lists "
"SET name = (?), listOrderingIndex = (?), locked = (?), totalCost = (?), showingCheckboxes = (?), totalDisplayType = (?), currencyIdentifier = (?), listRecord = (?) "
"WHERE listID = (?);";

static NSString * _Nonnull const sql_ListUpdateRecord = @""
"UPDATE Lists "
"SET listRecord = (?) "
"WHERE listID = (?);";

static NSString * _Nonnull const sql_ListDelete = @""
"DELETE FROM Lists "
"WHERE listID = (?);";

static NSString * _Nonnull const sql_ListIDsDelete = @""
"DELETE FROM Lists "
"WHERE listID IN ";

static NSString * _Nonnull const sql_ListSelectByListID = @""
"SELECT * FROM Lists "
"WHERE listID = (?);";

static NSString * _Nonnull const sql_ListSelectCurrencyIDByListID = @""
"SELECT currencyIdentifier FROM Lists "
"WHERE listID = (?);";

#pragma mark - Triggers

static NSString * _Nonnull const sql_ListItemCountInsertTrigger = @""
"CREATE TRIGGER IF NOT EXISTS updateListItemCountAfterInsert AFTER INSERT "
"ON ListItems "
"BEGIN "
"UPDATE Lists "
"SET itemCount = (SELECT DISTINCT COUNT(*) FROM ListItems WHERE listID = Lists.listID) "
"WHERE Lists.listID = NEW.listID; "
"END; ";

static NSString * _Nonnull const sql_ListItemCountDeleteTrigger = @""
"CREATE TRIGGER IF NOT EXISTS updateListItemCountAfterDelete AFTER DELETE "
"ON ListItems "
"BEGIN "
"UPDATE Lists "
"SET itemCount = (SELECT DISTINCT COUNT(*) FROM ListItems WHERE listID = Lists.listID) "
"WHERE Lists.listID = old.listID; "
"END; ";

static NSString * _Nonnull const sql_ListItemDeleteUpdateListTotalPriceTrigger = @""
"CREATE TRIGGER IF NOT EXISTS updateListItemListTotalAfterDelete AFTER DELETE "
"ON ListItems "
"BEGIN "
"UPDATE Lists "
"SET totalCost = (SELECT IFNULL(CAST(SUM(CAST(totalCost AS REAL)) AS Text), '0.00') FROM ListItems WHERE listID = Lists.listID) "
"WHERE Lists.listID = old.listID; "
"END; ";

static NSString * _Nonnull const sql_ListItemInsertUpdateListTotalPriceTrigger = @""
"CREATE TRIGGER IF NOT EXISTS updateListItemListTotalAfterInsert AFTER INSERT "
"ON ListItems "
"BEGIN "
"UPDATE Lists "
"SET totalCost = (SELECT IFNULL(CAST(SUM(CAST(totalCost AS REAL)) AS Text), '0.00') FROM ListItems WHERE listID = Lists.listID) "
"WHERE Lists.listID = new.listID; "
"END; ";

static NSString * _Nonnull const sql_ListItemUpdatedUpdateListTotalPriceTrigger = @""
"CREATE TRIGGER IF NOT EXISTS updateListItemListTotalAfterUpdate AFTER UPDATE "
"ON ListItems "
"BEGIN "
"UPDATE Lists "
"SET totalCost = (SELECT IFNULL(CAST(SUM(CAST(totalCost AS REAL)) AS Text), '0.00') FROM ListItems WHERE listID = Lists.listID) "
"WHERE Lists.listID = new.listID; "
"END; ";

NS_ASSUME_NONNULL_BEGIN
@interface SSList (Utils)

- (NSDecimalNumber *)calcBaseCost;
- (NSDecimalNumber *)calcTaxAmount;
- (NSDecimalNumber *)calcDiscountAmount;
- (NSDecimalNumber *)calcTotalCost;
- (NSDecimalNumber *)calcTotalCostFromDisplayType;
- (NSDecimalNumber *)calcTotalRecurringCost:(ListItemRecurringPricingChoice)recurringType;
- (double)itemTotalForTag:(SSListTag *)tag;
- (NSNumber *)averageItemPrice;
- (SSListItem * _Nullable)mostExpensiveItem;
- (SSListItem * _Nullable)cheapestItem;
- (SSCloudKitDatabase *)dbForList;
- (BOOL)listIsShared;
- (BOOL)listIsSharedWithMe;
- (NSArray <SSListItem *> * _Nonnull)recurringCostItems;
- (void)saveOrderingForItemsWithDB:(FMDatabase * _Nonnull)db forceRefresh:(BOOL)forceRefresh;
+ (void)moveListItems:(NSArray<SSListItem *> *)listItems fromList:(SSList *)fromList toList:(SSList *)toList listTagID:(NSString * _Nullable)listTagID completion:(void(^)(NSArray<SSListItem *> *listItems, SSList *fromList, SSList *toList, FMDatabase *db))completion;

@end
NS_ASSUME_NONNULL_END
