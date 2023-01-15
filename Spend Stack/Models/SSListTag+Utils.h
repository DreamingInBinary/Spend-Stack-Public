//
//  SSListTag+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListTag.h"
@class FMDatabase;
@class SSTagSelectionViewModel;
@class SSCloudKitDatabase;

static NSString * _Nonnull const sql_ListTagsCreateTable = @""
"CREATE TABLE IF NOT EXISTS ListTags ( "
"listTagID TEXT PRIMARY KEY, "
"listTagMasterTagID TEXT, "
"listTagListID TEXT NOT NULL, "
"color TEXT NOT NULL, "
"name TEXT NOT NULL, "
"listTagOrderingIndex INTEGER NOT NULL, "
"listTagReference BLOB NOT NULL, "
"listReference BLOB NOT NULL, "
"listTagRecord BLOB NOT NULL, "
"FOREIGN KEY (listTagMasterTagID) REFERENCES Tags(tagID) ON DELETE CASCADE "
");";

static NSString * _Nonnull const sql_ListTagSelectTagsSharedWithMeByListTagID = @""
"SELECT "
"* "
"FROM "
"ListTags "
"WHERE listTagMasterTagID IS NULL AND listTagListID = (?);";

static NSString * _Nonnull const sql_ListTagSelectByListAndTagID = @""
"SELECT "
"* "
"FROM "
"ListTags "
"WHERE listTagListID = (?) AND listTagMasterTagID = (?);";

static NSString * _Nonnull const sql_ListTagSelectByTagID = @""
"SELECT "
"* "
"FROM "
"ListTags "
"WHERE listTagMasterTagID = (?);";

static NSString * _Nonnull const sql_ListTagSelectByListID = @""
"SELECT "
"* "
"FROM "
"ListTags "
"WHERE listTagListID = (?);";

static NSString * _Nonnull const sql_ListTagSelectAll = @""
"SELECT "
"* "
"FROM "
"ListTags;";

// Get all listTags that match to the tag, and then listItem ID's using an
// Associated list tag created from that master tag.
static NSString * _Nonnull const sql_ListTagSelectListItemIDsUsingListTagsFromTagID = @""
"SELECT "
"listItemID "
"FROM "
"ListItems "
"LEFT JOIN ListTags "
"ON ListTags.listTagID = ListItems.tagID "
"WHERE ListTags.listTagMasterTagID = (?);";

static NSString * _Nonnull const sql_ListTagInsert = @""
"INSERT INTO "
"ListTags (listTagID, listTagListID, listTagMasterTagID, color, name, listTagOrderingIndex, listReference, listTagReference, listTagRecord) "
"VALUES "
"(?, ?, ?, ?, ?, ?, ?, ?, ?);";

static NSString * _Nonnull const sql_ListTagUpdate = @""
"UPDATE ListTags "
"SET listTagListID = (?), listTagMasterTagID = (?), color = (?), name = (?), listTagOrderingIndex = (?), listReference = (?), listTagReference = (?), listTagRecord = (?) "
"WHERE listTagID = (?);";

static NSString * _Nonnull const sql_ListTagUpdateFromMasterTag = @""
"UPDATE ListTags "
"SET color = (?), name = (?), listTagOrderingIndex = (?) "
"WHERE listTagID = (?);";

static NSString * _Nonnull const sql_ListTagUpdateRecord = @""
"UPDATE ListTags "
"SET listTagRecord = (?) "
"WHERE listTagID = (?);";

static NSString * _Nonnull const sql_ListTagDelete = @""
"DELETE FROM ListTags "
"WHERE listTagID = (?);";

static NSString * _Nonnull const sql_ListTagIDsDelete = @""
"DELETE FROM ListTags "
"WHERE listTagID IN ";

@interface SSListTag (Utils)

+ (SSListTag * _Nonnull)miscTag;
+ (SSTag * _Nullable)masterTagForListItem:(SSListItem * _Nonnull)listItem;
+ (SSTag * _Nullable)masterTagForListItem:(SSListItem * _Nonnull)listItem db:(FMDatabase * _Nonnull)db;
+ (SSTag * _Nullable)masterTagForListTagID:(NSString * _Nonnull)listTagID db:(FMDatabase * _Nonnull)db;
+ (NSArray <SSListTag *> * _Nonnull)listTagsForMasterTag:(SSTag * _Nonnull)tag inDB:(FMDatabase * _Nonnull)db;
// Finds any tags who, even though they may originate from your own master tags, are shared in a list that's not owned by you. As such, these need to be saved in the sharedDB,
// Just the same as adding a new list item would.
+ (NSArray <SSListTag *> * _Nonnull)listTagsForSharedDatabase:(NSArray <SSListTag *> * _Nonnull)listTags;
- (BOOL)tagIsSharedWithMe;

@end
