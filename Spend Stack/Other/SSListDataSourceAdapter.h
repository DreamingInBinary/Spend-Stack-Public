//
//  SSListDataSourceAdapter.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/23/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SSList;
@class FMResultSet;

typedef NSDiffableDataSourceSnapshot<SSListTag *, SSListItem *> DiffSnapShot;
typedef NSMutableDictionary <SSListTag *, NSMutableArray <SSListItem *> *> SSListTableViewModel;

@interface SSListDataSourceAdapter : NSObject <NSCopying, NSSecureCoding>

@property (weak, nonatomic, readonly, nullable) SSList *list;
@property (strong, nonatomic, readonly, nonnull) NSArray <SSListTag *> *sortedTags;
@property (strong, nonatomic, readonly, nonnull) NSArray <SSListTag *> *userCreatedTags; // All tags, minus misc
@property (strong, nonatomic, readonly, nonnull) NSArray <SSListItem *> *allItems; // Computed
@property (strong, nonatomic, readonly, nonnull) NSArray <SSListItem *> *allCheckedItems; // Computed
@property (strong, nonatomic, readonly, nonnull) NSArray <SSListItem *> *allUncheckedItems; // Computed
@property (strong, nonatomic, readonly, nonnull) SSListTableViewModel *itemsByTag;
@property (readonly) BOOL listHasTaggedItems; // Computed, discounts Misc.
@property (nonatomic, readonly) NSInteger totalNumberOfItems; // Computed
@property (weak, nonatomic, nullable) SSListItem *previouslyReorderedItem; // Not persisted
@property (strong, nonatomic, nonnull) SSListTag *miscTag; // Not tracked on the server

- (SSListDataSourceAdapter * _Nullable)deepCopy;
- (SSListTag * _Nonnull)tagByDBID:(NSString * _Nonnull)dbID;
- (SSListItem * _Nullable)listItemByDBID:(NSString * _Nonnull)dbID;
- (void)setListDuringCopy:(SSList * _Nonnull)list;
- (void)refreshTags; // Gets any changes made to tags. Effectively should be called anytime before you view list data.
- (void)updateSortedTags; // Useful for situations where CRUD didn't happen, but sorted tags should be updated
- (void)addItem:(SSListItem * _Nonnull)listItem;
- (void)applyEditsToItem:(SSListItem * _Nonnull)listItem;
- (BOOL)containsItem:(SSListItem * _Nonnull)listItem;
- (void)removeItem:(SSListItem * _Nonnull)listItem;
- (void)removeItems:(NSArray <SSListItem *> * _Nonnull)listItems;
- (void)removeAllItems;
- (SSListItem * _Nullable)listItemFromIndexPath:(NSIndexPath * _Nonnull)indexPath;
- (NSArray <SSListItem *> * _Nullable)listItemsFromIndexPaths:(NSArray <NSIndexPath *> *_Nonnull)indexPaths;
- (NSIndexPath * _Nullable)indexPathForListItem:(SSListItem * _Nonnull)listItem;
- (void)moveTagAtIndexPath:(NSIndexPath * _Nonnull)sourceIndexPath toIndexPath:(NSIndexPath * _Nonnull)destinationIndexPath;
- (void)updateList:(SSList * _Nonnull)list;
- (void)updateFromSnapshot:(DiffSnapShot * _Nonnull)snapshot;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithList:(SSList * _Nonnull)list resultSet:(FMResultSet * _Nonnull)resultSet;

@end
