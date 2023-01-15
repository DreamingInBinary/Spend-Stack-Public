//
//  SSListItemViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemViewController.h"
#import "SSModalCardViewController.h"
#import "SSListItemTableControllerAdapter.h"
#import "SSListItemDetailSectionHeaderView.h"
#import "SSListItemEntryTableViewCell.h"
#import "SSListItemTaxToggleTableViewCell.h"
#import "SSListItemSegmentTableViewCell.h"
#import "SSListItemPriceDataTableViewCell.h"
#import "SSListItemQuantityTableViewCell.h"
#import "SSListItemNoteTableViewCell.h"
#import "SSListItemTagTableViewCell.h"
#import "SSListItemAddAttachmentTableViewCell.h"
#import "SSListItemSegmentAttachmentTableViewCell.h"
#import "SSListItemMediaTableViewCell.h"
#import "SSMediaPermissionsViewController.h"
#import "SSTagsViewController.h"
#import "SSTheaterViewController.h"
#import "SSBottomNavigationViewController.h"
#import "SSListItemImageView.h"
#import "SSTheaterTransitioningDelegate.h"
#import "UITableView+Common.h"
#import "SSImagePickerViewController.h"
#import "SSTagSelectionViewModel.h"
#import "SSListItemDateTableViewCell.h"
#import "UITableViewCell+Common.h"
#import "SSListItemViewController+Camera.h"
#import "SSListItemViewController+Documents.h"
#import "Spend_Stack_2-Swift.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <LinkPresentation/LinkPresentation.h>

@interface SSListItemViewController () <SSTagsViewControllerDelegate,
                                        SSTheaterImageViewProvidingDelegate,
                                        SSListItemDetailSectionHeaderViewDelegate,
                                        SSImagePickerViewControllerDelegate,
                                        PHPickerViewControllerDelegate,
                                        UITableViewDataSource,
                                        UITableViewDelegate,
                                        UITableViewDataSourcePrefetching,
                                        UINavigationControllerDelegate,
                                        UIImagePickerControllerDelegate,
                                        UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic, nullable) id <SSListItemViewControllerDelegate> delegate;
@property (strong, nonatomic, readwrite, nullable) SSListItem *listItem;
@property (strong, nonatomic, nonnull) SSList *parentList;
@property (strong, nonatomic, nonnull) UITableView *tableView;
@property (strong, nonatomic, nonnull) SSListItemTableControllerAdapter *adapter;
@property (strong, nonatomic, nonnull) SSToolbar *tb;
@property (nonatomic) SSListItemAttribute editingAttribute;
@property (nonatomic, getter=didHandleEditingAttributeRequest) BOOL handledEditingAttributeRequest;
@property (strong, nonatomic, nullable) UIImage *downsampledImage;
@property (nonatomic, nonnull) dispatch_queue_t downsampleQueue;

// Keeps a reference to the last removed item of their respective type to support undo. When a tag is removed, a nil tag is sent  - so this will keep around one instance to undo that removal.
@property (strong, nonatomic, nullable) SSTagSelectionViewModel *lastTagAdded;
@property (strong, nonatomic, nullable) PHAsset *lastAssetAdded;
@property (strong, nonatomic, nullable) NSString *lastLinkAdded;
@property (strong, nonatomic, nullable) NSMeasurement *lastWeightAmount;
@property (nonatomic) ListItemRecurringPricingChoice lastRecurringPriceChoice;
@property (nonatomic, getter=didFailDownloadingImage) BOOL failedDownloadingImage;

@end

@implementation SSListItemViewController

#pragma mark - Initializers

- (instancetype)initWithListItem:(SSListItem *)listItem delegate:(id<SSListItemViewControllerDelegate> _Nonnull)delegate
{
    self = [super init];
    
    if (self)
    {
        self.listItem = listItem;
        [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                FMResultSet *result = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, listItem.fkListID];
                
                while ([result next])
                {
                    self.parentList = [[SSList alloc] initWithResultSet:result];
                }
                
                self.delegate = delegate;
                self.adapter = [[SSListItemTableControllerAdapter alloc] initWithList:self.parentList];
                [self.tableView reloadData];
            });
        }];
        
        dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INTERACTIVE, 0);
        self.downsampleQueue = dispatch_queue_create("com.spendstack.downsample", qosAttribute);
        
        // Pricing methods (i.e. the amount changed, and regular vs weighted)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handlePriceAmountChangedNotification:)
                                                     name:SS_PRICE_AMOUNT_CHANGED
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handlePricingMethodChangedNotification:)
                                                     name:SS_PRICING_METHOD_CHANGED
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAttachmentViewModeChangedNotification:)
                                                     name:SS_ATTACHMENT_VIEW_MODE_CHANGED
                                                   object:nil];
        
        // Discount handling (i.e. turned off completely, or amount off price or percentage off price)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDiscountRemovedNotification:)
                                                     name:SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDiscountAmountEnabledNotification:)
                                                     name:SS_PRICING_DISCOUNT_AMOUNT_ON
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handlePercentageAmountEnabledNotification:)
                                                     name:SS_PRICING_DISCOUNT_PERCENTAGE_ON
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWeightEntryWasInvalidNotification:)
                                                     name:SS_PRICING_WEIGHT_ENTRY_WAS_INVALID
                                                   object:nil];
        
        // Media toggle
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMediaShouldToggleNotification:)
                                                     name:SS_MEDIA_WAS_TOGGLED
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMediaLinkShouldToggleNotification:)
                                                     name:SS_MEDIA_LINK_WAS_TOGGLED
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadChangedIndices:)
                                                     name:SS_NOTE_DATA_CHANGED
                                                   object:nil];
    }
    
    return self;
}

- (instancetype)initWithListItem:(SSListItem *)listItem delegate:(id<SSListItemViewControllerDelegate>)delegate editingAttribute:(SSListItemAttribute)attribute
{
    self = [self initWithListItem:listItem delegate:delegate];
    
    if (self)
    {
        self.editingAttribute = attribute;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableViewAndToolBar];
    
    NSAssert([self.navigationController isKindOfClass:[SSModalCardNavigationController class]], @"Spend Stack - Wrong navigation controller supplied.");
    
    if (self.listItem.mediaAssetData)
    {
        [self downsampledImageWithData:self.listItem.mediaAssetData tableView:self.tableView];
    }
    
    BOOL shouldReflectSingleWindowUI = ([self.delegate respondsToSelector:@selector(shouldReflectSingleWindowUI)] &&
                                        [self.delegate shouldReflectSingleWindowUI]);
    
    if (shouldReflectSingleWindowUI)
    {
        [((SSModalCardNavigationController *)self.navigationController) resetCornerRadius];
    }
    else
    {
        [((SSModalCardNavigationController *)self.navigationController) prepareForDownChevron:@selector(dismissControllerAndCommitEdits)];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self handleQuickFindEditAttributeRequest];
}

#pragma mark - Quick Find Editing Requests

- (void)handleQuickFindEditAttributeRequest
{
    if (self.didHandleEditingAttributeRequest) return;
    
    if (self.editingAttribute == SSListItemAttributeNotes)
    {
        [self.tableView reloadData];
        NSIndexPath *idpOfQuickEditAttribute = [NSIndexPath indexPathForRow:0 inSection:SECTION_NOTES];
        [self.tableView scrollToRowAtIndexPath:idpOfQuickEditAttribute
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
        
        SSListItemNoteTableViewCell *noteTVC = (SSListItemNoteTableViewCell *)[self.tableView cellForRowAtIndexPath:idpOfQuickEditAttribute];
        [noteTVC markTextViewAsFirstResponder];
        self.handledEditingAttributeRequest = YES;
    }
}

#pragma mark - Diffing and Reloadable

- (void)loadChangedIndices:(NSNotification *)notification
{
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:sql_ListItemSelectByListItemID, self.listItem.dbID];
        SSListItem *freshListItem;
        
        while([result next])
        {
            freshListItem = [[SSListItem alloc] initWithResultSet:result];
        }
        
        if (freshListItem == nil)
        {
            UIAlertAction *actionRestore = [UIAlertAction actionWithTitle:@"Restore List" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self restoreListItem];
            }];
            
            UIAlertAction *actionLeaveDeleted = [UIAlertAction actionWithTitle:@"Leave Deleted" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self dismissController];
            }];
            
            [self showAlertControllerWithTitle:@"Item Deleted"
                                       message:@"This item has been deleted from another device. Do you want to restore it, or leave it deleted?"
                                       actions:@[actionRestore, actionLeaveDeleted]];
        }
        else
        {
            [self performDiffAndAssignNewDataFromLists:@[freshListItem]];
        }
    }];
}

- (void)performDiffAndAssignNewDataFromLists:(NSArray<__kindof SSObject *> *)freshData
{
    dispatch_sync(self.diffQueue, ^{
        SSListItem *newListItemData = freshData.firstObject;
        BOOL listItemChanged = [newListItemData isEqualToDiffableObject:self.listItem] == NO;
        
        if (listItemChanged)
        {
            self.listItem = newListItemData;
            // Reload differences lazily
            [self.tableView reloadData];
        }
    });
}

- (void)restoreListItem {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            // Update all of their records
            [self.listItem initializeNewRecordsForRedoWithZoneID:self.parentList.objCKRecord.recordID.zoneID];
            [self.listItem resetReferenceForRedo:self.parentList];
            
            if (self.listItem.tag)
            {
                SSTag *masterTag = [SSListTag masterTagForListItem:self.listItem db:db];
                
                if (masterTag)
                {
                    [self.listItem addListTag:masterTag withList:self.parentList withDB:db];
                }
                else
                {
                    [self.listItem addSharedListTag:self.listItem.tag withList:self.parentList];
                }
            }
            
            [db insertListItemIntoDB:self.listItem taxInfo:self.parentList.taxInfo taxUtil:self.parentList.taxUtil];

            [[self.parentList dbForList] saveObjects:@[self.listItem]
                                      withSavePolicy:CKRecordSaveChangedKeys
                                       deleteObjects:@[]
                                      withCompletion:^(NSError * error) {
                                                               NSLog(@"Spend Stack - Restored list item with error:(%@)", error);
                                                           }];
        }];
    });
}

#pragma mark - Popover Presentation

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    NSString *title = popoverPresentationController.presentedViewController.title;
    
    if ([title isEqualToString:ss_Localized(@"pop.delete")])
    {
        popoverPresentationController.barButtonItem = self.tb.items.firstObject;
    }
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.adapter rowsInSection:section forListItem:self.listItem];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = [self.adapter cellIDForIndexPath:indexPath forListItem:self.listItem];
    __kindof SSBaseListItemEditingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    if (indexPath.section == SECTION_PRICING && indexPath.row != 0)
    {
        // Row 0 is the segment control, not the cells with pricing data
        ((SSListItemPriceDataTableViewCell *)cell).type = [self.adapter priceDataTypeForIndexPath:indexPath forListItem:self.listItem];
    }
    
    // Check for media failures or attachment updates
    if (indexPath.section == SECTION_ATTACHMENTS)
    {
        if (indexPath.row == 0)
        {
            SSListItemSegmentAttachmentTableViewCell * attachSegmentTVC = (SSListItemSegmentAttachmentTableViewCell *)cell;
            [attachSegmentTVC setActiveMediaSegmentAtIndex:self.adapter.viewMode];
        }
        else if (indexPath.row == 1)
        {
            if ([cell isKindOfClass:[SSListItemAddAttachmentTableViewCell class]])
            {
                SSListItemAddAttachmentTableViewCell * attachTVC = (SSListItemAddAttachmentTableViewCell *)cell;
                attachTVC.viewMode = self.adapter.viewMode; // Setting this will update the label
                
                if (@available(iOS 14.0, *)) {
                    if (attachTVC.viewMode == AttachmentViewModeImage) {
                        attachTVC.menu = [self generateAttachmentsMenu];
                        [attachTVC.menuButton addAction:[UIAction actionWithHandler:^(UIAction *action) {
                            [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
                            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                        }] forControlEvents:UIControlEventMenuActionTriggered];
                    } else {
                        attachTVC.menu = nil;
                    }
                }
            }
            else
            {
                SSListItemMediaTableViewCell *mediaTVC = (SSListItemMediaTableViewCell *)cell;
                mediaTVC.viewMode = self.adapter.viewMode;
                if (self.didFailDownloadingImage && self.adapter.viewMode == AttachmentViewModeImage)
                {
                    mediaTVC.errorState = YES;
                }
            }
        }
    }
    
    cell.currencyID = self.parentList.currencyIdentifier;
    [cell setData:self.listItem list:self.parentList];
    
    return cell;
}

#pragma mark - Table View Prefetch

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    if (self.downsampledImage != nil) return;
    
    NSIndexPath *mediaIndexPath = [NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS];
    
    // This logic could easily be factored out to handle fetching images for items.
    if (self.listItem.mediaAssetData)
    {
        if ([indexPaths containsObject:mediaIndexPath])
        {
            [self downsampledImageWithData:self.listItem.mediaAssetData tableView:tableView];
        }
    }
    else if (self.listItem.mediaAttachment)
    {
        // Fetch the asset
        __block NSData *data = [NSData dataWithContentsOfURL:self.listItem.mediaAttachment.fileURL];
        if (data)
        {
            // We've got it locally
            [self downsampledImageWithData:data tableView:tableView];
        }
        else
        {
            __weak typeof(self) weakSelf = self;
            // Hit the network
            [[self.parentList dbForList] forceFetchRecords:@[self.listItem.objCKRecord] desiredKeys:@[@"mediaAttachment"] withCompletion:^(NSArray<CKRecord *> * _Nonnull records, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (records.count > 0)
                    {
                        NSURL *assetURL = ((CKAsset *)records.firstObject[@"mediaAttachment"]).fileURL;
                        data = [NSData dataWithContentsOfURL:assetURL];
                        [weakSelf.listItem attachMediaDataToInstanceWithData:data];
                        [weakSelf downsampledImageWithData:data tableView:tableView];
                    }
                    else
                    {
                        // Error state
                        self.failedDownloadingImage = YES;
                        
                        if ([[tableView indexPathsForVisibleRows] containsObject:mediaIndexPath])
                        {
                            [tableView reloadRowsAtIndexPaths:@[mediaIndexPath]
                                             withRowAnimation:UITableViewRowAnimationNone];
                        }
                    }
                });
            }];
        }
    }
}

- (void)downsampledImageWithData:(NSData *)data tableView:(UITableView *)tableView
{
    self.failedDownloadingImage = NO;
    CGFloat scale = tableView.traitCollection.displayScale;
    CGFloat maxPixelSize = (tableView.ss_width - SSSpacingJumboMargin) * scale;
    if (maxPixelSize <= 0) maxPixelSize = (self.view.boundsWidth - SSSpacingJumboMargin) * scale;
    
    dispatch_async(self.downsampleQueue, ^{
        // Downsample
        self.downsampledImage = [UIImage downsampledImageFromData:data
                                                            scale:scale
                                                     maxPixelSize:maxPixelSize];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            self.listItem.downsampledMediaImage = self.downsampledImage;
            
            // Check if we should reload the cell
            NSIndexPath *mediaIndexPath = [NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS];
            [tableView reloadRowsAtIndexPaths:@[mediaIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    });
}

#pragma mark - Section Header Delegate

- (NSString *)buttonText
{
    return [self.adapter buttonTextForSection:SECTION_ATTACHMENTS forListItem:self.listItem];
}

- (UIColor *)buttonTextColor
{
    return [self.adapter buttonTextColorForSection:SECTION_ATTACHMENTS forListItem:self.listItem];
}

- (SSListItemDetailSectionHeaderViewTapScenario)tapScenario
{
    return [self.adapter tapScenarioForDetailHeaderViewInSection:SECTION_ATTACHMENTS];
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    SSListItemDetailSectionHeaderView *headerView = (SSListItemDetailSectionHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:SS_ITEM_ENTRY_SECTION_HEADER_ID];
    if (section == SECTION_ATTACHMENTS) headerView.delegate = self;
    headerView.titleString = [self.adapter sectionHeaderStringForSection:section];
    headerView.buttonString = [self.adapter buttonTextForSection:section forListItem:self.listItem];
    headerView.buttonTextColor = [self.adapter buttonTextColorForSection:section forListItem:self.listItem];
    headerView.tapScenario = [self.adapter tapScenarioForDetailHeaderViewInSection:section];
    
    return [headerView estimatedHeightForHeaderInView:self.tableView];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SSListItemDetailSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SS_ITEM_ENTRY_SECTION_HEADER_ID];
    headerView.delegate = self;
    headerView.titleString = [self.adapter sectionHeaderStringForSection:section];
    headerView.buttonString = [self.adapter buttonTextForSection:section forListItem:self.listItem];
    headerView.buttonTextColor = [self.adapter buttonTextColorForSection:section forListItem:self.listItem];
    headerView.tapScenario = [self.adapter tapScenarioForDetailHeaderViewInSection:section];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_PRICING && indexPath.row != 0)
    {
        SSListItemPriceDataDisplayType priceType = [self.adapter priceDataTypeForIndexPath:indexPath
                                                                               forListItem:self.listItem];
        SSListItemPriceDataTableViewCell *priceTVC = (SSListItemPriceDataTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        if (priceType != SSListItemPriceDataDisplayTypeSubtotalAmount &&
            priceType != SSListItemPriceDataDisplayTypeTaxAmount &&
            priceType != SSListItemPriceDataDisplayTypeTotalAmount &&
            priceType != SSListItemPriceDataDisplayTypeRecurring &&
            priceType != SSListItemPriceDataDisplayTypeUnknown)
        {
            [priceTVC makePriceEntryTextViewFirstResponder];
        }
        else if (priceType == SSListItemPriceDataDisplayTypeRecurring)
        {
            // Check if the mouse pointer "clicked" on the row. Otherwise, the label button is tapped.
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            for (id<UIInteraction> interaction in cell.contentView.interactions)
            {
                if ([interaction isKindOfClass:[UIPointerInteraction class]])
                {
                    [priceTVC presentCycleEditor];
                }
            }
        }
    }
    else if (indexPath.section == SECTION_TAG)
    {
        [self showTagsController];
    }
    else if (indexPath.section == SECTION_ATTACHMENTS)
    {
        if (self.adapter.viewMode == AttachmentViewModeImage && self.listItem.mediaAttachment == nil)
        {
            if (@available(iOS 14.0, *)) {
                    // do.Nothing() - the UIMenu presents options
            } else {
                [self openImageAttachmentPicker];
            }
        }
        else if (self.adapter.viewMode == AttachmentViewModeLink && self.listItem.linkAttachment == nil)
        {
            [self openLinkAttach];
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_ATTACHMENTS && self.listItem.mediaAttachment)
    {
        return fabs(self.view.boundsWidth - SSSpacingJumboMargin);
    }
    else
    {
        return [SSCitizenship accessibilityFontsEnabled] ? 128 : 64;
    }
}

#pragma mark - Row Tap Handlers

- (void)showTagsController
{
    SSTagSelectionViewModel *tagVM = [self.listItem createTagViewModel];
    [self pushOrPresentViewController:[[SSTagsViewController alloc] initWithSelectedTag:tagVM delegate:self scenario:SSTagsScenarioAddingToItem]];
}

- (UIMenu *)generateAttachmentsMenu API_AVAILABLE(ios(14.0))
{
    
    void (^deselectAttachIDP)(void) = ^(){
        // Presenting the context menu makes deselection not animate.
        // So just do it after the menu goes away.
        NSIndexPath *selectedIDP = [self.tableView indexPathForSelectedRow];
        if (selectedIDP) { [self.tableView deselectRowAtIndexPath:selectedIDP animated:YES]; }
    };
    
    // Camera
    UIAction *ac_cameraRoll = [UIAction actionWithTitle:ss_Localized(@"listItem.cell.acCamera") image:[UIImage systemImageNamed:@"photo"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        deselectAttachIDP();
        [self openImageAttachmentPicker];
    }];
    
    // Take photo
    UIAction *ac_takePhoto = [UIAction actionWithTitle:ss_Localized(@"listItem.cell.acTakePhoto") image:[UIImage systemImageNamed:@"camera.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        deselectAttachIDP();
        [self presentCamera];
    }];
    
    // Docs
    UIAction *ac_Docs = [UIAction actionWithTitle:ss_Localized(@"listItem.cell.acDocs") image:[UIImage systemImageNamed:@"doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        deselectAttachIDP();
        [self presentDocumentPicker];
    }];
    
    return [UIMenu menuWithChildren:@[ac_Docs, ac_takePhoto, ac_cameraRoll]];
}

- (void)openImageAttachmentPicker
{
    if (@available(iOS 14, *)) {
        PHPickerConfiguration *config = [PHPickerConfiguration new];
        config.selectionLimit = 1;
        config.filter = [PHPickerFilter imagesFilter];
        
        PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                if (status == PHAuthorizationStatusAuthorized)
                {
                    SSImagePickerViewController *pickerVC = [[SSImagePickerViewController alloc] initWithDelegate:self];
                    if (self.isiPad)
                    {
                        [self.navigationController pushViewController:pickerVC animated:YES];
                    }
                    else
                    {
                        SSModalCardNavigationController *navVC = [[SSModalCardNavigationController alloc] initWithRootViewController:pickerVC];
                        [self presentViewController:navVC animated:YES completion:nil];
                    }
                }
                else
                {
                    // We need authorization
                    SSMediaPermissionsViewController *mediaPermsVC = [SSMediaPermissionsViewController new];
                    [self presentViewController:mediaPermsVC animated:YES completion:nil];
                }
            });
        }];
    }
}

- (void)openLinkAttach
{
    AttachLinkViewController *attachVC = [AttachLinkViewController new];
    attachVC.onLinkStringEntered = ^(NSString *link) {
        [self attachLinkToItemAndReload:link];
    };
    
    [self pushOrPresentViewController:attachVC];
}

- (void)attachLinkToItemAndReload:(NSString *)linkText
{
    self.lastLinkAdded = linkText;
    self.listItem.linkAttachment = linkText;
    self.adapter.viewMode = AttachmentViewModeLink;
    
    NSIndexPath *linkIDP = [NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS];
    
    // The media table view cell will kick off fetching the metadata
    [self.tableView reloadRowsAtIndexPaths:@[linkIDP]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView scrollToRowAtIndexPath:linkIDP
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    });
}

- (void)pushOrPresentViewController:(UIViewController *)controller
{
    if (self.isiPad)
    {
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        SSModalCardNavigationController *navVC = [[SSModalCardNavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:navVC animated:YES completion:nil];
    }
}

#pragma mark - Image Picker Delegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results
API_AVAILABLE(ios(14)) {
    if (results.count > 0)
    {
        PHPickerResult *firstPick = results.firstObject;
        [firstPick.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                if (error != nil) {
                    [self showError:error title:ss_Localized(@"general.error.title")];
                } else {
                    [self didSelectImage:(UIImage *)object];
                }
            });
        }];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSelectAsset:(PHAsset *)asset
{
    [self addMediaToItemWithAsset:asset];
}

- (void)didSelectImage:(UIImage *)image
{
    if (!image) return;
    __weak typeof(self) weakSelf = self;
    [self.listItem attachNewMediaDataToInstanceWithData:UIImageJPEGRepresentation(image, 1.0f) completion:^{
        [weakSelf finishAddMediaAndReloadSection:weakSelf];
    }];
}

- (void)addMediaToItemWithAsset:(PHAsset *)asset
{
    self.lastAssetAdded = asset;
    __weak typeof(self) weakSelf = self;
    [self.listItem addMediaToItem:asset completion:^{
        [weakSelf finishAddMediaAndReloadSection:weakSelf];
    }];
}

- (void)finishAddMediaAndReloadSection:(SSListItemViewController *const __weak)weakSelf
{
    CGFloat scale = weakSelf.tableView.traitCollection.displayScale;
    CGFloat maxPixelSize = (weakSelf.tableView.ss_width - SSSpacingJumboMargin) * scale;
    
    dispatch_async(weakSelf.downsampleQueue, ^{
        // Downsample
        weakSelf.downsampledImage = [UIImage downsampledImageFromData:weakSelf.listItem.mediaAssetData
                                                                scale:scale
                                                         maxPixelSize:maxPixelSize];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            weakSelf.listItem.downsampledMediaImage = weakSelf.downsampledImage;
            [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS]]
                                      withRowAnimation:UITableViewRowAnimationFade];
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS]
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_ATTACHMENT_VIEW_MODE_CHANGED object:@(self.adapter.viewMode)];
        });
    });
}

#pragma mark - Misc

- (void)setupTableViewAndToolBar
{
    self.tb = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeDelete, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeDone]];
    self.tb.clipsToBounds = NO;
    __weak SSListItemViewController *weakSelf = self;
    self.tb.onDone = ^{
        [weakSelf dismissControllerAndCommitEdits];
    };
    self.tb.onDelete = ^{
        UIAlertAction *delete = [UIAlertAction actionWithTitle:ss_Localized(@"general.delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf performDeleteItem];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:nil];
        
        [weakSelf showActionSheetWithTitle:ss_Localized(@"pop.delete") message:nil actions:@[delete, cancel]];
    };
    
    [self.view addSubview:self.tb];
    [self.tb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.prefetchDataSource = self;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.onPreferredContentSizeChanged = ^{
        [weakSelf.tableView reloadData];
    };
    
    [self.view insertSubview:self.tableView belowSubview:self.tb];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.top.equalTo(self.view.mas_top);
        make.bottom.equalTo(self.tb.mas_top);
    }];

    // Header registration
    [self.tableView registerClass:[SSListItemDetailSectionHeaderView class] forHeaderFooterViewReuseIdentifier:SS_ITEM_ENTRY_SECTION_HEADER_ID];
    
    // Cell registration
    [self.tableView registerClass:[SSListItemEntryTableViewCell class] forCellReuseIdentifier:SS_ITEM_ENTRY_CELL_ID];
    [self.tableView registerClass:[SSListItemTaxToggleTableViewCell class] forCellReuseIdentifier:SS_ITEM_TAX_TOGGLE_CELL_ID];
    [self.tableView registerClass:[SSListItemDateTableViewCell class] forCellReuseIdentifier:SS_ITEM_ENTRY_DATE_CELL_ID];
    [self.tableView registerClass:[SSListItemSegmentTableViewCell class] forCellReuseIdentifier:SS_ITEM_ENTRY_SEGMENT_CELL_ID];
    [self.tableView registerClass:[SSListItemPriceDataTableViewCell class] forCellReuseIdentifier:SS_ITEM_PRICE_DATA_CELL_ID];
    [self.tableView registerClass:[SSListItemQuantityTableViewCell class] forCellReuseIdentifier:SS_ITEM_QUANTITY_CELL_ID];
    [self.tableView registerClass:[SSListItemNoteTableViewCell class] forCellReuseIdentifier:SS_ITEM_NOTE_CELL_ID];
    [self.tableView registerClass:[SSListItemTagTableViewCell class] forCellReuseIdentifier:SS_ITEM_TAG_CELL_ID];
    [self.tableView registerClass:[SSListItemAddAttachmentTableViewCell class] forCellReuseIdentifier:SS_ITEM_ADD_MEDIA_CELL_ID];
    [self.tableView registerClass:[SSListItemMediaTableViewCell class] forCellReuseIdentifier:SS_ITEM_MEDIA_CELL_ID];
    [self.tableView registerClass:[SSListItemSegmentAttachmentTableViewCell class] forCellReuseIdentifier:SS_ITEM_ENTRY_SEGMENT_ATTACHMENT_CELL_ID];
}

- (void)performDeleteItem
{
    BOOL didDelete = [self.delegate requestDeleteItem:self.listItem];
    
    if (didDelete)
    {
        [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
            self.tableView.transform = CGAffineTransformMakeScale(0.80, 0.80f);
            self.tableView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self dismissSceneOrController];
        }];
    }
    else
    {
        [self dismissSceneOrController];
    }
}

#pragma mark - Pricing Method Notification Handling

- (void)handlePriceAmountChangedNotification:(NSNotification *)note
{
    // We can't reload the section because the text view for price entry is still the first responder.
    // Instead we've got to grab the labels and manually update them.
    NSInteger numberOfPriceCells = [self.tableView.dataSource tableView:self.tableView
                                                  numberOfRowsInSection:SECTION_PRICING];

    for (NSInteger row = 0; row < numberOfPriceCells; row++)
    {
        NSIndexPath *priceCellIndexPath = [NSIndexPath indexPathForRow:row inSection:SECTION_PRICING];
        
        SSListItemPriceDataTableViewCell *pricingCell = (SSListItemPriceDataTableViewCell *)[self.tableView cellForRowAtIndexPath:priceCellIndexPath];
        
        if ([pricingCell isKindOfClass:[SSListItemPriceDataTableViewCell class]])
        {
            // Don't update the cell if the user is currently entering data in it
            if (pricingCell.textViewIsFirstResponder == NO)
            {
                [pricingCell setData:self.listItem list:self.parentList];
            }
        }
    }
}

- (void)handlePricingMethodChangedNotification:(NSNotification *)note
{
    NSString *pricingMethod = note.object;
    NSInteger previousNumber = [self.tableView.dataSource tableView:self.tableView
                                              numberOfRowsInSection:SECTION_PRICING];

    if ([pricingMethod isEqualToString:SS_PRICING_METHOD_REGULAR])
    {
        self.lastWeightAmount = [self.listItem.weight copy];
        self.listItem.weight = nil;
        self.lastRecurringPriceChoice = self.listItem.recurringPricingCycle;
        self.listItem.recurringPricingCycle = ListItemRecurringPricingChoiceUnset;
    }
    else if ([pricingMethod isEqualToString:SS_PRICING_METHOD_WEIGHT])
    {
        // If they toggled back and forth, we saved their last amount so restore it here
        if (self.lastWeightAmount)
        {
            self.listItem.weight = self.lastWeightAmount;
        }
        else
        {
            self.listItem.weight =[NSMeasurement measurementWithValue:0];
        }
        
        self.lastRecurringPriceChoice = self.listItem.recurringPricingCycle;
        self.listItem.recurringPricingCycle = ListItemRecurringPricingChoiceUnset;
    }
    else if ([pricingMethod isEqualToString:SS_PRICING_METHOD_RECURRING])
    {
        self.lastWeightAmount = [self.listItem.weight copy];
        self.listItem.weight = nil;
        
        if (self.lastRecurringPriceChoice != ListItemRecurringPricingChoiceUnset)
        {
            self.listItem.recurringPricingCycle = self.lastRecurringPriceChoice;
        }
        else
        {
            self.listItem.recurringPricingCycle = ListItemRecurringPricingChoiceDay;
        }
    }
    
    NSInteger updatedNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    [self.tableView batchUpdateWithPreviousNumberOfRows:previousNumber updatedNumberOfRows:updatedNumber
                                              inSection:SECTION_PRICING];
    
    // Activate first responder in the textview
    if ([pricingMethod isEqualToString:SS_PRICING_METHOD_WEIGHT])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ENTER_WEIGHT object:nil];
    }
}

- (void)handleAttachmentViewModeChangedNotification:(NSNotification *)note
{
    NSAssert([note.object isKindOfClass:[NSNumber class]], @"Spend Stack - Expected view mode notification to send a number, but got %@.", note.object);
    
    NSIndexPath *mediaIDP = [NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS];
    NSString *previousCellID = [self.adapter cellIDForIndexPath:mediaIDP forListItem:self.listItem];
    AttachmentViewMode viewMode = ((NSNumber *)note.object).integerValue;
    self.adapter.viewMode = (AttachmentViewMode)viewMode;
    
    [self.tableView reloadRowsAtIndexPaths:@[mediaIDP]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    NSString *newCellID = [self.adapter cellIDForIndexPath:mediaIDP forListItem:self.listItem];
    
    // Basically don't scroll if you were viewing a photo or link already, and toggling between the two.
    // We only want to reload if the we went from a small cell to a big one, or vice versa.
    if ([newCellID isEqualToString:SS_ITEM_MEDIA_CELL_ID] &&
        [previousCellID isEqualToString:SS_ITEM_ADD_MEDIA_CELL_ID])
    {
        [self.tableView scrollToRowAtIndexPath:mediaIDP
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    }
}

- (void)handleWeightEntryWasInvalidNotification:(NSNotification *)note
{
    NSInteger previousNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    [self.listItem removeWeightedPricing];
    NSInteger updatedNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    // Make the segment control deselect weighted pricing
    SSListItemSegmentTableViewCell *segmentTVC = ((SSListItemSegmentTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SECTION_PRICING]]);
    if ([segmentTVC isKindOfClass:[SSListItemSegmentTableViewCell class]])
    {
        [segmentTVC setActivePricingSegmentAtIndex:0];
    }
    
    [self.tableView batchUpdateWithPreviousNumberOfRows:previousNumber updatedNumberOfRows:updatedNumber inSection:SECTION_PRICING];
}

#pragma mark - Discount Toggle Handling

- (void)handleDiscountRemovedNotification:(NSNotification *)note
{
    NSInteger previousNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    // Undo support
    if (self.listItem.discountAmount)
    {
        [self.undoManager registerUndoWithTarget:self
                                        selector:@selector(performUndoRemoveDiscountAmountFromItem:)
                                          object:self.listItem.discountAmount];
        [self.undoManager setActionName:@"Remove Discount Amount"];
    }
    else if (self.listItem.discountPercentage)
    {
        [self.undoManager registerUndoWithTarget:self
                                        selector:@selector(performUndoRemoveDiscountPercentFromItem:)
                                          object:self.listItem.discountPercentage];
        [self.undoManager setActionName:@"Remove Discount Percentage"];
    }
    
    // This is driving if the row shows for a discount
    [self.listItem removeDiscounts];
    
    NSInteger updatedNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    [self.tableView batchUpdateWithPreviousNumberOfRows:previousNumber updatedNumberOfRows:updatedNumber inSection:SECTION_PRICING];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_PRICING] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)handleDiscountAmountEnabledNotification:(NSNotification *)note
{
    NSInteger previousNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    // This is driving if the row shows for a discount
    [self.listItem removeDiscounts];
    self.listItem.discountAmount = [NSDecimalNumber new];
    
    NSInteger updatedNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    [self.tableView batchUpdateWithPreviousNumberOfRows:previousNumber updatedNumberOfRows:updatedNumber inSection:SECTION_PRICING];
    
    // The reload is wiping this out, no idea why. Just set it back.
    self.listItem.discountAmount = [NSDecimalNumber new];
    
    // Activate first responder for the text view
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ENTER_DISCOUNT object:nil];
}

- (void)handlePercentageAmountEnabledNotification:(NSNotification *)note
{
    NSInteger previousNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    // This is driving if the row shows for a discount
    [self.listItem removeDiscounts];
    self.listItem.discountPercentage = [NSDecimalNumber new];
    
    NSInteger updatedNumber = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:SECTION_PRICING];
    
    [self.tableView batchUpdateWithPreviousNumberOfRows:previousNumber updatedNumberOfRows:updatedNumber inSection:SECTION_PRICING];
    
    // Activate first responder for the text view
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ENTER_DISCOUNT object:nil];
}

#pragma mark - Media Toggle Handling

- (void)handleMediaShouldToggleNotification:(NSNotification *)note
{
    NSNumber *shouldRemoveMediaFromItemBoxedValue = note.object;
    if ([shouldRemoveMediaFromItemBoxedValue isKindOfClass:[NSNumber class]])
    {
        BOOL shouldRemoveMediaFromItem = shouldRemoveMediaFromItemBoxedValue.boolValue;
        
        if (shouldRemoveMediaFromItem)
        {
            [self.undoManager registerUndoWithTarget:self
                                            selector:@selector(performUndoRemoveMediaFromItem:)
                                              object:self.lastAssetAdded];
            [self.undoManager setActionName:@"Remove Photo"];
            
            [self.listItem removeMediaFromItem];
        }
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_ATTACHMENTS] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)handleMediaLinkShouldToggleNotification:(NSNotification *)note
{
    NSNumber *shouldRemoveMediaFromItemBoxedValue = note.object;
    if ([shouldRemoveMediaFromItemBoxedValue isKindOfClass:[NSNumber class]])
    {
        BOOL shouldRemoveMediaFromItem = shouldRemoveMediaFromItemBoxedValue.boolValue;
        
        if (shouldRemoveMediaFromItem)
        {
            [self.undoManager registerUndoWithTarget:self
                                            selector:@selector(performUndoRemoveMediaLinkFromItem:)
                                              object:self.lastLinkAdded];
            [self.undoManager setActionName:@"Remove Link"];
            
            self.lastLinkAdded = self.listItem.linkAttachment;
            [self.listItem removeLinkFromItem];
        }
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_ATTACHMENTS] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Tags Delegate

- (void)onTagSelectionChanged:(SSTagSelectionViewModel *)tag controller:(SSTagsViewController *)controller
{
    [self handleTagSelection:tag];
}

- (NSArray <SSListTag *> *)tagsFromListShare
{
    if (self.parentList.listIsShared == NO) return @[];
    return [[SSDataStore sharedInstance] queryListTagsSharedToMeForListID:self.parentList.dbID];
}

- (void)handleTagSelection:(SSTagSelectionViewModel *)tag
{
    [self.tableView performBatchUpdates:^{
        if (tag == nil)
        {
            [self.listItem deleteTag];
        }
        else
        {
            if (tag.type == SSTagTypeMasterTag)
            {
                [self.listItem addListTag:tag.underlyingTag withList:self.parentList];
            }
            else
            {
                [self.listItem addSharedListTag:tag.underlyingListTag withList:self.parentList];
            }
            
            self.lastTagAdded = tag;
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SECTION_TAG]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(BOOL finished) {
        if (finished)
        {
            if (tag == nil)
            {
                // Register Undo the Undo
                [self.undoManager registerUndoWithTarget:self
                                                selector:@selector(performUndoRemoveTagFromItem:)
                                                  object:self.lastTagAdded];
                [self.undoManager setActionName:@"Remove Tag"];
            }
            else
            {
                // Register Undo the Undo
                [self.undoManager registerUndoWithTarget:self
                                                selector:@selector(performRedoRemoveTagFromItem:)
                                                  object:nil];
                [self.undoManager setActionName:@"Add Tag"];
            }
        }
    }];
}

#pragma mark - Undo/Redo

- (void)performRedoRemoveTagFromItem:(SSTagSelectionViewModel * _Nonnull)tagToRedelete
{
    [self handleTagSelection:nil];
}

- (void)performUndoRemoveTagFromItem:(SSTagSelectionViewModel * _Nonnull)tagToRestore
{
    // Register Undo the Redo
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performRedoRemoveTagFromItem:)
                                      object:tagToRestore];
    [self.undoManager setActionName:@"Remove Tag"];
    [self handleTagSelection:tagToRestore];
}

- (void)performRedoRemoveMediaFromItem
{
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performUndoRemoveMediaFromItem:)
                                      object:self.lastAssetAdded];
    [self.undoManager setActionName:@"Remove Photo"];
    
    [self.listItem removeMediaFromItem];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_ATTACHMENTS] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)performUndoRemoveMediaFromItem:(PHAsset * _Nonnull)mediaToRestore
{
    // Register Undo the Undo
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performRedoRemoveMediaFromItem)
                                      object:nil];
    [self.undoManager setActionName:@"Remove Photo"];
    
    [self addMediaToItemWithAsset:mediaToRestore];
}

- (void)performRedoRemoveMediaLinkFromItem
{
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performUndoRemoveMediaLinkFromItem:)
                                      object:self.lastLinkAdded];
    [self.undoManager setActionName:@"Remove Link"];
    
    [self.listItem removeLinkFromItem];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_ATTACHMENTS] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)performUndoRemoveMediaLinkFromItem:(LPLinkMetadata * _Nonnull)linkToRestore
{
    // Register Undo the Undo
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performRedoRemoveMediaLinkFromItem)
                                      object:nil];
    [self.undoManager setActionName:@"Remove Link"];
    
    [self attachLinkToItemAndReload:self.lastLinkAdded];
}

- (void)performRedoRemoveDiscountAmountFromItem
{
    [self handleDiscountRemovedNotification:nil];
}

- (void)performUndoRemoveDiscountAmountFromItem:(NSDecimalNumber *)amountToRestore
{
    // Register Undo the Undo
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performRedoRemoveDiscountAmountFromItem)
                                      object:nil];
    [self.undoManager setActionName:@"Remove Discount Amount"];
    
    [self handleDiscountAmountEnabledNotification:nil];
    
    self.listItem.discountAmount = amountToRestore;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_PRICING] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)performRedoRemoveDiscountPercentFromItem
{
    [self handleDiscountRemovedNotification:nil];
}

- (void)performUndoRemoveDiscountPercentFromItem:(NSDecimalNumber *)percentToRestore
{
    // Register Undo the Undo
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performRedoRemoveDiscountPercentFromItem)
                                      object:nil];
    [self.undoManager setActionName:@"Remove Discount Percentage"];
    
    [self handlePercentageAmountEnabledNotification:nil];
    
    self.listItem.discountPercentage = percentToRestore;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_PRICING] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Dismisall (Commits Edits)

- (void)dismissControllerAndCommitEdits
{
    [self.delegate onEditsCommitted:self.listItem];
    [self dismissSceneOrController];
}

- (void)dismissSceneOrController
{
    if ([self.delegate respondsToSelector:@selector(requestCloseSceneSessionForListItemController:)])
    {
        [self.delegate requestCloseSceneSessionForListItemController:self.view.window.windowScene.session];
    }
    else
    {
        // Not multiple window UI
        [self dismissController];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)presentImageViewerWithImageView:(__kindof UIImageView *)imageView
{
    BOOL imageIsBehindToolBar;
    CGRect tbFrameInWindow = [self.tb convertRect:self.tb.bounds toView:nil];
    CGRect imageViewFrameInWindow = [imageView convertRect:imageView.bounds toView:nil];
    imageIsBehindToolBar = CGRectIntersectsRect(imageViewFrameInWindow, tbFrameInWindow);
    
    if (imageIsBehindToolBar)
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            SSTheaterViewController *theaterVC = [[SSTheaterViewController alloc] initWithImage:imageView.image listItem:nil];
            [self presentViewController:theaterVC animated:YES completion:nil];
        });
    }
    else
    {
        SSTheaterViewController *theaterVC = [[SSTheaterViewController alloc] initWithImage:imageView.image listItem:nil];
        [self presentViewController:theaterVC animated:YES completion:nil];
    }
}

- (SSListItem *)editingItem
{
    return self.listItem;
}

#pragma mark - Theater Image Providing Delegate

- (UIImageView *)ss_presentingControllerImageView
{
    SSListItemMediaTableViewCell *mediaTVC = (SSListItemMediaTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:SECTION_ATTACHMENTS]];
    NSAssert([mediaTVC isKindOfClass:[SSListItemMediaTableViewCell class]], @"Spend Stack - Unexpected cell type for media cell request.");
    return mediaTVC.mediaImageView;
}

@end
