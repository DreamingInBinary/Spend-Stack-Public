//
//  SSConstants.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>
#import <sys/utsname.h>
#import "SSObject.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static inline void ss_printRecordIDs(NSArray * _Nonnull objects)
{
    CKRecord *recordType = nil; // From CloudKit CRU
    SSObject *objType = nil; // From datastore operations
    CKRecordID *recordIDType = nil; // From CloudKit deletions
    
    NSLog(@"\n\n\n**********\nRecord Names for objects:\n");
    for (id obj in objects)
    {
        if ([obj isKindOfClass:[SSObject class]])
        {
            objType = (SSObject *)obj;
            NSLog(@"RecordID's name for %@: %@", NSStringFromClass(objType.class), objType.objCKRecord.recordID.recordName);
        }
        else if ([obj isKindOfClass:[CKRecord class]])
        {
            recordType = (CKRecord *)obj;
            NSLog(@"RecordID's name for CKRecordType %@: %@", recordType.recordType, recordType.recordID.recordName);
        }
        else if ([obj isKindOfClass:[CKRecordID class]])
        {
            recordIDType = (CKRecordID *)obj;
            NSLog(@"RecordID's name for deletion: %@", recordIDType.recordName);
        }
    }
    NSLog(@"\n**********\n");
}

static inline NSString * _Nonnull ss_deviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}
#pragma clang diagnostic pop

static NSUInteger const SS_Week = 7;
static CGFloat const SS_WeeksInYear = 52.0;

static CGFloat const ss_tinyPhoneThreshold = 1334.0f;
/*
 * For iPad Pro in landscape for a detail view.
 */
static CGFloat const SS_iPadProDetailViewWidthLandscape = 990.0f;

/*
 * For iPhone in landscape for a detail view that we'd want to consider regular width.
 */
static CGFloat const SS_iPhoneDetailViewWidthLandscape = 800.0f;

// UI Elements

/*
 * 32 points.
 */
static CGFloat const SSSpacingJumboMargin = 32.0f;

/*
 * 16 points.
 */
static CGFloat const SSSpacingBigMargin = 16.0f;

/*
 * 8 points.
 */
static CGFloat const SSSpacingMargin = 8.0f;

/*
 * 32 points.
 */
static CGFloat const SSLeftJumboElementMargin = 32.0f;

/*
 * 032 points.
 */
static CGFloat const SSRightJumboElementMargin = -32.0f;

/*
 * 32 points.
 */
static CGFloat const SSTopJumboElementMargin = 32.0f;

/*
 * -32 points.
 */
static CGFloat const SSBottomJumboElementMargin = -32.0f;

/*
 * 16 points.
 */
static CGFloat const SSLeftBigElementMargin = 16.0f;

/*
 * -16 points.
 */
static CGFloat const SSRightBigElementMargin = -16.0f;

/*
 * 16 points.
 */
static CGFloat const SSTopBigElementMargin = 16.0f;

/*
 * -16 points.
 */
static CGFloat const SSBottomBigElementMargin = -16.0f;

/*
 * 8 points.
 */
static CGFloat const SSLeftElementMargin = 8.0f;

/*
 * -8 points.
 */
static CGFloat const SSRightElementMargin = -8.0f;

/*
 * 8 points.
 */
static CGFloat const SSTopElementMargin = 8.0f;

/*
 * -8 points.
 */
static CGFloat const SSBottomElementMargin = -8.0f;

/*
 * 60 points.
 */
static CGFloat const SSTopGiantElementMargin = 60.0f;

/*
 * -60 points.
 */
static CGFloat const SSBottomGiantElementMargin = -60.0f;

/*
 * 1 second.
 */
static CGFloat const SSUIKitTableViewBatchAnimationDuration = 0.35f;

/*
 * 1 second.
 */
static CGFloat const SSStandardAnimationDelay = 1.0f;

/*
 * 0.15 seconds.
 */
static CGFloat const SSFasterThanFastestAnimationDuration = 0.15f;

/*
 * 0.25 seconds.
 */
static CGFloat const SSFastestAnimationDuration = 0.25f;

/*
 * .52f seconds.
 */
static CGFloat const SSFastAnimationDuration = 0.52f;

/*
 * .74 seconds.
 */
static CGFloat const SSBriefAnimationDuration = 0.74f;

/*
 * 480 points.
 */
static NSInteger const SSModaliPadSize = 480;

// For icons on accessibility donts
static NSInteger const SSIconAccessibilitySize = 46;

// Minimum tap target according to the H.I.G.
static NSInteger const SSUIKitMinimumTapHeight = 44;

NS_ASSUME_NONNULL_BEGIN

// Location
static NSString * const COUNTRY_CODE_US = @"US";
static NSString * const COUNTRY_CODE_SWITZERLAND = @"CH";
static NSString * const COUNTRY_CODE_CHILE = @"CL";
static NSString * const COUNTRY_CODE_INDONESIA = @"ID";

// Notifications
static NSString * const SS_NOTE_DATA_CHANGED = @"SSDiffsOccurred";
static NSString * const SS_PRICE_AMOUNT_CHANGED = @"SSPricrAmountChanged";
static NSString * const SS_PRICING_METHOD_CHANGED = @"SSPricingMethodChanged";
static NSString * const SS_ATTACHMENT_VIEW_MODE_CHANGED = @"SSAttachmentViewModeChanged";
static NSString * const SS_PRICING_DISCOUNT_AMOUNT_ON = @"SSPricingDiscountAmountOn";
static NSString * const SS_PRICING_DISCOUNT_PERCENTAGE_ON = @"SSPricingDiscountPercentageOn";
static NSString * const SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF = @"SSRemovedDiscount";
static NSString * const SS_PRICING_WEIGHT_ENTRY_WAS_INVALID = @"SSWeightEntryWeightInvalid";
static NSString * const SS_PRICING_METHOD_REGULAR = @"SSPricingMethodRegular";
static NSString * const SS_PRICING_METHOD_WEIGHT = @"SSPricingMethodWeight";
static NSString * const SS_PRICING_METHOD_RECURRING = @"SSPricingMethodRecurring";
static NSString * const SS_PRICING_ENTER_DISCOUNT = @"SSPricingEnterDiscount";
static NSString * const SS_PRICING_ENTER_WEIGHT = @"SSPricingEnterWeight";
static NSString * const SS_MEDIA_WAS_TOGGLED = @"SSMediaWasToggled";
static NSString * const SS_MEDIA_LINK_WAS_TOGGLED = @"SSMediaLinkWasToggled";
static NSString * const SS_CONTROLLER_WAS_POPPED = @"ss_controllerWasPopped";
static NSString * const SS_LISTS_WERE_DELETED = @"SSDeletedList";
static NSString * const SS_TRAIT_COLLECTION_CHANGED = @"ss_traitCollectionChanged";
static NSString * const SS_HANDLING_QUICK_ACTION = @"ss_handlingQuickAction";
static NSString * const SS_IPAD_PSEUDO_TRAIT_COLLECTION_CHANGED = @"ss_fakeTraitCollectionChanged";
static NSString * const SS_TAG_CRUD_FROM_TAG_MANAGER_CONTROLLER = @"ss_TagCRUDFromTagManagerController";
static NSString * const SS_WHOLE_NUMBERS_TOGGLED = @"ss_ToggledWholeNumbers";
static NSString * const SS_SHOW_TAG_FOOTER_TOGGLED = @"ss_ToggledShowTagFooters";
static NSString * const SS_SHOW_LIST_TOTAL_TOGGLED = @"ss_ToggledShowListTotal";
static NSString * const SS_LIST_SORT_OPTION_CHANGED = @"ss_SortOptionChanged";
static NSString * const SS_LIST_ITEM_CHECKBOX_TOGGLED = @"ss_ListItemCheckboxToggled";
static NSString * const SS_LIST_CHANGED_CURRENCY = @"ss_ListChangedCurrency";
static NSString * const SS_FOUND_TAX_RATE = @"ss_FoundTaxRate";
// There are scenarios where you need cells to redraw, but there won't be a diff in diffable data source.
// i.e. new tax rate, toggle check boxes, etc. For these, we have to fall back on reloadData.
static NSString * const SS_REQUEST_RELOAD_LIST = @"ss_RequestReloadList";
static NSString * const SS_APP_GROUP_NAME = @"group.dib.ss";

// User Defaults Keys
static NSString * const Show_Tag_Footers = @"showTagFooters";
static NSString * const Show_List_Total = @"showListTotal";
static NSString * const Use_Whole_Numbers = @"shouldUseWholeNumbers";
static NSString * const Private_Change_Token = @"serverChangeToken";
static NSString * const Did_Create_Custom_Zone = @"customZoneCreated";
static NSString * const SS_HAS_SEEN_FIRST_RUN = @"SSHasViewedSplashOnLaunch";
static NSString * const SS_HAS_SEEN_APPLE_CARD_SPLASH = @"SSHasViewedAppleCardSplash";
static NSString * const SS_HAS_DEMOED_EXIF_GESTURE = @"ss_hasDemoedExifGesture";
static NSString * const SS_LIST_ITEM_IDS_RECENTLY_DELETED_TAG = @"ss_listItemIDsForDeletedTag";
static NSString * const SS_HAS_SEEN_APP_ICON_INFO_BOX = @"ss_hasSeenAppInfoBox";

NS_ASSUME_NONNULL_END

static inline NSUserDefaults * _Nonnull ss_defaults()
{
    return [[NSUserDefaults alloc] initWithSuiteName:SS_APP_GROUP_NAME];
}
