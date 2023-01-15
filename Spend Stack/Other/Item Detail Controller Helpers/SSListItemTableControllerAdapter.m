//
//  SSListItemTableControllerAdapter.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemTableControllerAdapter.h"
#import "SSListItemEntryTableViewCell.h"
#import "SSListItemTaxToggleTableViewCell.h"
#import "SSListItemSegmentTableViewCell.h"
#import "SSListItemPriceDataTableViewCell.h"
#import "SSListItemQuantityTableViewCell.h"
#import "SSListItemNoteTableViewCell.h"
#import "SSListItemTagTableViewCell.h"
#import "SSListItemAddAttachmentTableViewCell.h"
#import "SSListItemMediaTableViewCell.h"
#import "SSListItemDateTableViewCell.h"
#import "SSListItemSegmentAttachmentTableViewCell.h"

@interface SSListItemTableControllerAdapter()

@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSListItemTableControllerAdapter

#pragma mark - Intiializer

- (instancetype)initWithList:(SSList *)list
{
    self = [super init];
    
    if (self)
    {
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:list.currencyIdentifier];
    }
    
    return self;
}

#pragma mark - Row Counts

- (NSInteger)rowsInSection:(NSInteger)section forListItem:(SSListItem *)item
{
    switch (section)
    {
        case SECTION_NAME_TAX_DATE:
        {
            return 3;
            break;
        }
        case SECTION_PRICING:
        {
            BOOL hasPricingModifier = ([item checkHasWeightedPricing] || [item checkIsUsingRecurringPricing]);
            if (hasPricingModifier)
            {
                return [item checkHasDiscountApplied] > 0 ? 7 : 6;
            }
            else if ([item checkHasDiscountApplied])
            {
                return 6;
            }
            else
            {
                return 5;
            }
            break;
        }
        case SECTION_QUANTITY:
            return 1;
            break;
        case SECTION_NOTES:
            return 1;
            break;
        case SECTION_TAG:
            return 1;
            break;
        case SECTION_ATTACHMENTS:
            return 2;
            break;
        default:
            return 0;
            break;
    }
}

#pragma mark - Rows

- (NSString *)cellIDForIndexPath:(NSIndexPath *)indexPath forListItem:(SSListItem * _Nonnull)item
{
    if (indexPath.section == SECTION_NAME_TAX_DATE)
    {
        switch (indexPath.row)
        {
            case 0:
                return SS_ITEM_ENTRY_CELL_ID;
                break;
            case 1:
                return SS_ITEM_TAX_TOGGLE_CELL_ID;
                break;
            case 2:
                return SS_ITEM_ENTRY_DATE_CELL_ID;
                break;
            default:
                return SS_ITEM_ENTRY_CELL_ID;
                break;
        }
    }
    else if (indexPath.section == SECTION_PRICING)
    {
        return (indexPath.row == 0) ? SS_ITEM_ENTRY_SEGMENT_CELL_ID : SS_ITEM_PRICE_DATA_CELL_ID;
    }
    else if (indexPath.section == SECTION_QUANTITY)
    {
        return SS_ITEM_QUANTITY_CELL_ID;
    }
    else if (indexPath.section == SECTION_NOTES)
    {
        return SS_ITEM_NOTE_CELL_ID;
    }
    else if (indexPath.section == SECTION_TAG)
    {
        return SS_ITEM_TAG_CELL_ID;
    }
    else if (indexPath.section == SECTION_ATTACHMENTS)
    {
        if (indexPath.row == 0)
        {
            return SS_ITEM_ENTRY_SEGMENT_ATTACHMENT_CELL_ID;
        }
        else
        {
            if (self.viewMode == AttachmentViewModeImage)
            {
                return item.mediaAttachment ? SS_ITEM_MEDIA_CELL_ID : SS_ITEM_ADD_MEDIA_CELL_ID;
            }
            else if (self.viewMode == AttachmentViewModeLink)
            {
                return item.linkAttachment ? SS_ITEM_MEDIA_CELL_ID : SS_ITEM_ADD_MEDIA_CELL_ID;
            }
        }
    }
    
    return @"";
}

- (SSListItemPriceDataDisplayType)priceDataTypeForIndexPath:(NSIndexPath *)indexPath forListItem :(SSListItem *)item
{
    if (indexPath.section != SECTION_PRICING) return SSListItemPriceDataDisplayTypeUnknown;
    
    // Flow is...
    // Row 0 is always the segment toggle, and then:
    // If recurring pricing, then recurring pricing entry cell
    // Price (where they enter in data)
    // Subtotal (could != price depending on quantity)
    // Weight (if applicable)
    // Discount (if applicable)
    // Tax (shows even if it's off)
    // Total
    
    NSUInteger workingIndex = indexPath.row;
    
    if (workingIndex == 1)
    {
        if ([item checkIsUsingRecurringPricing])
        {
            return SSListItemPriceDataDisplayTypeRecurring;
        }
        else
        {
            return SSListItemPriceDataDisplayTypeBaseAmount;
        }
    }

    if (workingIndex == 2)
    {
        if ([item checkIsUsingRecurringPricing])
        {
            return SSListItemPriceDataDisplayTypeBaseAmount;
        }
        else
        {
            return SSListItemPriceDataDisplayTypeSubtotalAmount;
        }
    }
    
    if (workingIndex == 3)
    {
        if ([item checkHasWeightedPricing])
        {
            return SSListItemPriceDataDisplayTypeWeight;
        }
        else if ([item checkIsUsingRecurringPricing])
        {
            return SSListItemPriceDataDisplayTypeSubtotalAmount;
        }
        else if ([item checkHasDiscountApplied])
        {
            return SSListItemPriceDataDisplayTypeDiscount;
        }
        else
        {
            return SSListItemPriceDataDisplayTypeTaxAmount;
        }
    }
    
    BOOL hasPricingModifier = ([item checkHasWeightedPricing] || [item checkIsUsingRecurringPricing]);
    
    if (workingIndex == 4)
    {
        if (hasPricingModifier && [item checkHasDiscountApplied] == NO)
        {
            return SSListItemPriceDataDisplayTypeTaxAmount;
        }
        else if (hasPricingModifier && [item checkHasDiscountApplied])
        {
            return SSListItemPriceDataDisplayTypeDiscount;
        }
        else if (hasPricingModifier == NO && [item checkHasDiscountApplied])
        {
            return SSListItemPriceDataDisplayTypeTaxAmount;
        }
        else
        {
            return SSListItemPriceDataDisplayTypeTotalAmount;
        }
    }
    
    if (workingIndex == 5)
    {
        if (hasPricingModifier && [item checkHasDiscountApplied])
        {
            return SSListItemPriceDataDisplayTypeTaxAmount;
        }
    }
    
    return SSListItemPriceDataDisplayTypeTotalAmount;
}

#pragma mark - Section Headers

- (NSString *)sectionHeaderStringForSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_NAME_TAX_DATE:
            return nil;
            break;
        case SECTION_PRICING:
            return ss_Localized(@"listEdit.header1");
            break;
        case SECTION_QUANTITY:
            return ss_Localized(@"listEdit.header2");
            break;
        case SECTION_NOTES:
            return ss_Localized(@"listEdit.header3");
            break;
        case SECTION_TAG:
            return ss_Localized(@"listEdit.header4");
            break;
        case SECTION_ATTACHMENTS:
            return ss_Localized(@"listEdit.header5");
            break;
        default:
            return @"";
            break;
    }
}

- (NSString *)buttonTextForSection:(NSInteger)section forListItem:(SSListItem *)listItem
{
    if (section == SECTION_PRICING)
    {
        return [listItem checkHasDiscountApplied] ? ss_Localized(@"listEdit.remove") :ss_Localized(@"listEdit.add");
    }
    
    if (section == SECTION_ATTACHMENTS)
    {
        if (self.viewMode == AttachmentViewModeImage)
        {
            return listItem.mediaAttachment ? ss_Localized(@"listEdit.removePhoto") : @"";
        }
        else
        {
            return listItem.linkAttachment ? ss_Localized(@"listEdit.removeLink") : @"";
        }
    }
    
    return @"";
}

- (UIColor *)buttonTextColorForSection:(NSInteger)section forListItem:(SSListItem *)listItem
{
    if (section == SECTION_PRICING)
    {
        return [listItem checkHasDiscountApplied] ? [UIColor colorFromHexString:@"#F65E56"] : [UIColor ssPrimaryColor];
    }
    
    if (section == SECTION_ATTACHMENTS)
    {
        if (self.viewMode == AttachmentViewModeImage)
        {
            return listItem.mediaAttachment ? [UIColor colorFromHexString:@"#F65E56"] : [UIColor ssPrimaryColor];
        }
        else
        {
            return listItem.linkAttachment ? [UIColor colorFromHexString:@"#F65E56"] : [UIColor ssPrimaryColor];
        }
    }
    
    return [UIColor ssPrimaryColor];
}

- (SSListItemDetailSectionHeaderViewTapScenario)tapScenarioForDetailHeaderViewInSection:(NSInteger)section
{
    if (section == SECTION_PRICING)
    {
        return SSListItemDetailSectionHeaderViewTapScenarioToggleDiscount;
    }
    
    if (section == SECTION_ATTACHMENTS)
    {
        if (self.viewMode == AttachmentViewModeImage)
        {
            return SSListItemDetailSectionHeaderViewTapScenarioToggleMedia;
        }
        else
        {
            return SSListItemDetailSectionHeaderViewTapScenarioToggleMediaLink;
        }
    }
    
    return SSListItemDetailSectionHeaderViewTapScenarioUnset;
}

@end
