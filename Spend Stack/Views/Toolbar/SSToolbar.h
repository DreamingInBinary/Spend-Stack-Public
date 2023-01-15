//
//  SSToolbar.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SSListTag;

typedef const NSString SSToolBarItem;

static const SSToolBarItem * _Nonnull SSToolBarItemTypeShare = @"SSToolBarItemTypeShare";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeSort = @"SSToolBarItemTypeSort";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeBarcode = @"SSToolBarItemTypeBarcode";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeTotal = @"SSToolBarItemTypeTotal";
static const SSToolBarItem * _Nonnull SSToolBarItemTypePieChart = @"SSToolBarItemTypePieChart";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeDelete = @"SSToolBarItemTypeDelete";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeBasicAdd = @"SSToolBarItemTypeBasicAdd";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeBasicOutlinedAdd = @"SSToolBarItemTypeBasicOutlinedAdd";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeAddTag = @"SSToolBarItemTypeAddTag";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeAddCircleTag = @"SSToolBarItemTypeAddCircleTag";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeAddItem = @"SSToolBarItemTypeAddItem";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeDone = @"SSToolBarItemTypeDone";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeKeyboardDown = @"SSToolBarItemKeyboardDown";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeMutedKeyboardDown = @"SSToolBarItemTypeMutedKeyboardDown";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeEdit = @"SSToolBarItemEdit";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeDoubleZero = @"SSToolBarItemTypeDoubleZero";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeExport = @"SSToolBarItemTypeExport";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeCamera = @"SSToolBarItemTypeCamera";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeCloudDocuments = @"SSToolBarItemTypeCloudDocuments";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeGeneric = @"SSToolBarItemTypeGeneric";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeGenericNoBorder = @"SSToolBarItemTypeGenericNoBorder";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeFlexSpace = @"SSToolBarItemTypeFlexSpace";
static const SSToolBarItem * _Nonnull SSToolBarItemTypePlusMinus = @"SSToolBarItemTypePlusMinus";
static const SSToolBarItem * _Nonnull SSToolBarItemTypeCreditCard = @"SSToolBarItemTypeCreditCard";

@interface SSToolbar : UIToolbar

@property (nonatomic, getter=shouldHideBarBackground) BOOL hideBarBackground;
@property (nonatomic, copy, nullable) void (^onShare)(void);
@property (nonatomic, copy, nullable) void (^onSort)(void);
@property (nonatomic, copy, nullable) void (^onBarcode)(void);
@property (nonatomic, copy, nullable) void (^onTotal)(void);
@property (nonatomic, copy, nullable) void (^onPieChart)(void);
@property (nonatomic, copy, nullable) void (^onDelete)(void);
@property (nonatomic, copy, nullable) void (^onBasicAdd)(void);
@property (nonatomic, copy, nullable) void (^onAddTag)(void);
@property (nonatomic, copy, nullable) void (^onAddCircleTag)(void);
@property (nonatomic, copy, nullable) void (^onAddItem)(void);
@property (nonatomic, copy, nullable) void (^onDone)(void);
@property (nonatomic, copy, nullable) void (^onKeyboardDown)(void);
@property (nonatomic, copy, nullable) void (^onEdit)(void);
@property (nonatomic, copy, nullable) void (^onDoubleZero)(void);
@property (nonatomic, copy, nullable) void (^onExport)(void);
@property (nonatomic, copy, nullable) void (^onCamera)(void);
@property (nonatomic, copy, nullable) void (^onCloudDocuments)(void);
@property (nonatomic, copy, nullable) void (^onGenericAction)(void);
@property (nonatomic, copy, nullable) void (^onGenericNoBorderAction)(void);
@property (nonatomic, copy, nullable) void (^onPlusMinus)(void);
@property (nonatomic, copy, nullable) void (^onCreditCard)(void);
@property (nonatomic, strong, nullable) NSString *genericButtonTitle;
@property (nonatomic, strong, nullable) NSString *genericNoBorderButtonTitle;

- (instancetype _Nonnull)initWithItemTypes:(NSArray <SSToolBarItem *> * _Nonnull)items;
- (instancetype _Nonnull)initForDynamicStlyingWithItemTypes:(NSArray <SSToolBarItem *> * _Nonnull)items;
- (void)setToolBarItems:(NSArray <SSToolBarItem *> * _Nonnull)items;
- (void)replaceToolBarItemForType:(SSToolBarItem * _Nonnull)itemType withItem:(UIBarButtonItem * _Nonnull)item;
- (void)disableBarItemsAtIndicies:(NSArray <NSNumber *> * _Nonnull)indicesToDisable;
- (UIBarButtonItem * _Nullable)itemFromType:(SSToolBarItem * _Nonnull)itemType;
- (UIBarButtonItem * _Nullable)existingItemAtIndex:(NSInteger)itemIndex;
- (void)addTagsCollectionViewIfNeeded:(NSArray <SSListTag *> * _Nullable)sharedTags;
- (void)overrideStylingWithColor:(UIColor * _Nonnull)color;
- (void)animateTagView:(NSArray <SSListTag *> * _Nullable)sharedTags;
- (void)hideTagView:(BOOL)clearingTagSelection;

@end
