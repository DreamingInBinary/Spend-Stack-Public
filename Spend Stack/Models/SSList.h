//
//  SSList.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/15/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IGListDiffKit.h"
#import "SSObject.h"
#import "FMDatabase.h"
@class SSTag;
@class SSListItem;
@class SSListDataSourceAdapter;
@class SSTaxRateInfo;
@class TaxUtility;

typedef NS_ENUM(NSUInteger, ListSortOption) {
    ListSortOptionUnset,
    ListSortOptionAlphabetically,
    ListSortOptionNewest,
    ListSortOptionOldest
};

typedef NS_ENUM(NSUInteger, ListTotalDisplayType) {
    ListTotalDisplayAll,
    ListTotalDisplayOnlyChecked,
    ListTotalDisplayOnlyUnchecked
};

extern NSString * _Nonnull ListTotalDisplayTypeToString(ListTotalDisplayType enumType);

@interface SSList : SSObject <NSSecureCoding, NSCopying, IGListDiffable>

@property (strong, nonatomic, nonnull) NSString *name;
@property (strong, nonatomic, nonnull) NSDate *dateCreated;
@property (nonatomic, readonly) NSInteger itemCount;
@property (strong, nonatomic, nonnull) NSNumber *orderingIndex;
@property (strong, nonatomic, nonnull) NSDecimalNumber *totalCost;
@property (strong, nonatomic, nonnull, readonly) SSTaxRateInfo *taxInfo;
@property (strong, nonatomic, nonnull, readonly) SSListDataSourceAdapter *datasourceAdapter;
@property (nonatomic, getter=isLocked) BOOL locked;
@property (nonatomic, getter=isShowingCheckboxes) BOOL showingCheckboxes;
@property (nonatomic) ListTotalDisplayType totalDisplayType;
@property (strong, nonatomic, nonnull) NSString *currencyIdentifier;
@property (strong, nonatomic, nonnull) NSString *currencyCode; // Local only
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

// This does *NOT* carry over items. You need to do those manually.
- (instancetype _Nonnull)initWithExistingList:(SSList * _Nonnull)list;

- (SSList * _Nonnull)deepCopy;
- (void)addItem:(SSListItem * _Nonnull)item;
- (void)addItemLocallyAndOnServer:(SSListItem * _Nonnull)item inDB:(FMDatabase * _Nonnull)db;
- (void)moveItemToList:(SSListItem * _Nonnull)item withListTagID:(NSString * _Nullable)fkListTag inDB:(FMDatabase * _Nonnull)db;
- (void)applyEditsForItemLocally:(SSListItem * _Nonnull)item;
- (void)applyEditsForItemLocallyAndOnServer:(SSListItem * _Nonnull)item;
- (void)saveListLocallyAndOnServer:(void(^ _Nullable)(void))completion;
- (void)removeItem:(SSListItem * _Nonnull)item;
- (void)removeItems:(NSArray <SSListItem *> * _Nonnull)items;
- (void)removeAllItems;
// This above methods delete items from the local cache in the data adapter *and* the DB/CK.
// For bulk delete, to diff we need two different representations of the data but then we also need to
// Assign the current data to the list's datasource otherwise batch updates would crash. So by the time
// They diff, they are already deleted locally but we need to delete them from DB/CK as well.
// You should almost never use this method externally.
- (void)removeItemsFromDatabaseAndCloudKit:(NSArray <SSListItem *> * _Nonnull)items;
// See above comment.
- (void)assignNewAdapter:(SSListDataSourceAdapter * _Nonnull)adapter;

@end
