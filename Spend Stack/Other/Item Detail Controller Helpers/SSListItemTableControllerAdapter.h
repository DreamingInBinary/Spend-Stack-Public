//
//  SSListItemTableControllerAdapter.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSListItemPriceDataTableViewCell.h"
#import "SSListItemDetailSectionHeaderView.h"
#import "SSListItemAddAttachmentTableViewCell.h"

static const NSInteger SECTION_NAME_TAX_DATE = 0;
static const NSInteger SECTION_PRICING = 1;
static const NSInteger SECTION_QUANTITY = 2;
static const NSInteger SECTION_NOTES = 3;
static const NSInteger SECTION_TAG = 4;
static const NSInteger SECTION_ATTACHMENTS = 5;

@interface SSListItemTableControllerAdapter : NSObject

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithList:(SSList * _Nonnull)list NS_DESIGNATED_INITIALIZER;

@property (nonatomic) AttachmentViewMode viewMode;

// Rows
- (NSInteger)rowsInSection:(NSInteger)section forListItem:(SSListItem * _Nonnull)item;
- (NSString * _Nonnull)cellIDForIndexPath:(NSIndexPath * _Nonnull)indexPath forListItem:(SSListItem * _Nonnull)item;
- (SSListItemPriceDataDisplayType)priceDataTypeForIndexPath:(NSIndexPath * _Nonnull)indexPath forListItem:(SSListItem * _Nonnull)item;

// Sections
- (NSString * _Nullable)sectionHeaderStringForSection:(NSInteger)section;
- (NSString * _Nonnull)buttonTextForSection:(NSInteger)section forListItem:(SSListItem * _Nonnull)listItem;
- (UIColor * _Nonnull)buttonTextColorForSection:(NSInteger)section forListItem:(SSListItem * _Nonnull)listItem;
- (SSListItemDetailSectionHeaderViewTapScenario)tapScenarioForDetailHeaderViewInSection:(NSInteger)section;

@end
