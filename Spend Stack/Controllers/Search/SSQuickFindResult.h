//
//  SSQuickFindResult.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/3/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SSQuickFindResultType) {
    SSQuickFindResultList,
    SSQuickFindResultListItem,
    SSQuickFindResultTag,
    SSQuickFindResultNote,
    SSQuickFindResultUnknown
};

static NSString * _Nonnull const sql_performQuickSearch = @""
"SELECT * FROM "
"(SELECT l.name as searchTerm, l.listID as id, 'list' as type, NULL as parentID "
"FROM lists as l where l.name like :search) "
"UNION "
"SELECT * FROM "
"(SELECT li.title, li.listItemID, 'listitem' as type, li.listID as parentID "
"FROM listitems as li where li.title like :search) "
"UNION "
"SELECT * FROM "
"(SELECT li.notes, li.listItemID, 'note' as type, li.listID as parentID "
"FROM listitems as li where li.notes like :search) "
"UNION "
"SELECT * FROM "
"(SELECT t.name, t.tagID, 'tag' as type, NULL as parentID "
"FROM tags as t where t.name like :search);";

static NSString * _Nonnull const sql_performQuickSearchTest = @""
"SELECT l.name as searchTerm, l.listID as id, 'list' as type "
"FROM Lists as l where l.name like :search;";

static inline NSString * _Nonnull stringFromType(SSQuickFindResultType type)
{
    switch (type)
    {
        case SSQuickFindResultList:
            return @"List";
        case SSQuickFindResultListItem:
            return @"Item";
        case SSQuickFindResultNote:
            return @"Note";
        case SSQuickFindResultTag:
            return @"Tag";
        default:
            return @"";
    }
}

@interface SSQuickFindResult : NSObject <IGListDiffable>

@property (strong, nonatomic, nonnull) NSString *objectID;
@property (strong, nonatomic, nonnull) NSString *matchedTerm;
@property (strong, nonatomic, nullable) NSString *parentObjectID;
@property (nonatomic) SSQuickFindResultType type;

+ (NSArray <SSQuickFindResult *> * _Nonnull)resultsFromQuery:(FMResultSet * _Nonnull)res;

@end
