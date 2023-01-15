//
//  SSTag+Utils.h
//  Spend Stack
//
//  Created by Jordan Morgan on 5/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTag.h"
@class FMDatabase;

static NSString * _Nonnull const sql_TagsCreateTable = @""
"CREATE TABLE IF NOT EXISTS Tags ( "
"tagID TEXT PRIMARY KEY, "
"color TEXT NOT NULL, "
"name TEXT NOT NULL, "
"tagOrderingIndex INTEGER NOT NULL, "
"tagRecord BLOB NOT NULL "
");";

static NSString * _Nonnull const sql_TagSelectAll = @""
"SELECT "
"* "
"FROM "
"TAGS "
"ORDER BY tagOrderingIndex ASC; ";

static NSString * _Nonnull const sql_TagSelectByTagID = @""
"SELECT "
"* "
"FROM "
"TAGS "
"WHERE tagID = (?);";

static NSString * _Nonnull const sql_TagInsert = @""
"INSERT INTO "
"TAGS (tagID, color, name, tagOrderingIndex, tagRecord) "
"VALUES "
"(?, ?, ?, ?, ?);";

static NSString * _Nonnull const sql_TagUpdate = @""
"UPDATE Tags "
"SET color = (?), name = (?), tagOrderingIndex = (?), tagRecord = (?) "
"WHERE tagID = (?);";

static NSString * _Nonnull const sql_TagUpdateRecord = @""
"UPDATE Tags "
"SET tagRecord = (?) "
"WHERE tagID = (?);";

static NSString * _Nonnull const sql_TagDelete = @""
"DELETE FROM Tags "
"WHERE tagID = (?);";

static NSString * _Nonnull const sql_TagIDsDelete = @""
"DELETE FROM Tags "
"WHERE tagID IN ";

#pragma mark - Triggers

static NSString * _Nonnull const sql_TagRemoveFromListItemsDeleteTrigger = @""
"CREATE TRIGGER IF NOT EXISTS removeTagFromListItemsAfterDelete AFTER DELETE "
"ON Tags "
"BEGIN "
"DELETE FROM ListTags "
"WHERE ListTags.listTagMasterTagID = old.tagID; "
"END; ";

static NSString * _Nonnull const sql_TagEditListTagsWhenMasterTagEditedTrigger = @""
"CREATE TRIGGER IF NOT EXISTS tagEditListTagsWhenMasterTagEditedTrigger AFTER UPDATE "
"ON Tags "
"BEGIN "
"UPDATE ListTags "
"SET color = new.color, name = new.name, listTagOrderingIndex = new.tagOrderingIndex "
"WHERE ListTags.listTagMasterTagID = new.tagID; "
"END; ";

typedef NSDictionary <NSString *, NSArray <__kindof SSObject *> *> iCloudTagsDictionary;
static NSString * _Nonnull const SS_TAGS_IN_MY_DB = @"ssTagsInMyDB";
static NSString * _Nonnull const SS_TAGS_IN_SHARED_DB = @"ssTagsInSharedDB";

@interface SSTag (Utils)

+ (SSTag * _Nullable)masterTagForListTag:(SSListTag * _Nonnull)listTag;
+ (UIColor * _Nullable)rawColorFromColor:(NSString * _Nonnull)colorString;
+ (iCloudTagsDictionary * _Nonnull)tagsByCloudDB:(SSTag * _Nonnull)masterTag localDBConnection:(FMDatabase * _Nonnull)db;
+ (void)saveListItemIDsUsingTagToBeDeleted:(FMDatabase * _Nonnull)db tag:(SSTag * _Nonnull)tag;
+ (void)restoreTagAndReassociateListItemForeignKeysToTag:(SSTag * _Nonnull)tag database:(FMDatabase * _Nonnull)db;
- (UIColor * _Nullable)rawColor;

@end
