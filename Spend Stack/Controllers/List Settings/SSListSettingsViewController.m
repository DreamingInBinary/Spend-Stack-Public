//
//  SSListSettingsViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/16/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListSettingsViewController.h"
#import "SSGeneralTableViewCell.h"
#import "SSListSectionHeaderView.h"
#import "SSListExporter.h"
#import "SSEditNameViewController.h"
#import "SSNoConnectionViewController.h"
#import "SSFindTaxRateViewController.h"
#import "SSTaxPermissionsViewController.h"
#import "SSAdvancedListOptionsViewController.h"
#import "SSEnterTaxRateViewController.h"
#import "LAContext+Utils.h"
#import "UITraitCollection+Utils.h"
#import "Spend_Stack_2-Swift.h"
#import <LocalAuthentication/LocalAuthentication.h>

static NSString * _Nonnull const CELL_ID = @"cell";
static NSInteger const SECTION_LIST_SHARE = 0;
static NSInteger const SECTION_LIST_EDIT = 1;
static NSInteger const SECTION_LIST_OPTIONS = 2;

@interface SSListSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic, readwrite, nullable) SSList *list;
@property (weak, nonatomic, nullable) id <SSListSettingsViewControllerDelegate> delegate;
@property (strong, nonatomic, nonnull) SSListExporter *exporter;
@property (strong, nonatomic, nonnull) UITableView *tv;
@property (strong, nonatomic, readonly, nonnull) NSString *taxRateActionString;
@property (strong, nonatomic, nonnull) LAContext *authCTX;
@property (nonatomic) BOOL didSelectShare; // Only used to track if the presentation controller should set this or the edit tax rate row for the popover on iPad regular trait collections
@property (strong, nonatomic, nonnull) NSString *authString;

@end

@implementation SSListSettingsViewController

#pragma mark - Computed Properties

- (NSString *)taxRateActionString
{
    return self.list.taxInfo.taxRate.doubleValue > 0 ? [NSString stringWithFormat:ss_Localized(@"list.vc.changeTax"), self.list.taxInfo.taxRateStringValue] : ss_Localized(@"createList.vc.set");
}

- (NSString *)authString
{
    if (!_authString)
    {
        NSString *authType = [LAContext localizedBiometryAuthType];
        _authString = [NSString stringWithFormat:ss_Localized(@"list.vc.lock"), authType];
    }
    
    return _authString;
}

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list delegate:(id<SSListSettingsViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.list = list;
        self.exporter = [[SSListExporter alloc] initWithList:self.list];
        self.delegate = delegate;
        self.authCTX = [LAContext new];
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithList:nil delegate:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithList:nil delegate:nil];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = ss_Localized(@"list.vc.title");
    
    if ([self.navigationController isKindOfClass:[SSNavigationController class]])
    {
        [((SSNavigationController *)self.navigationController) styleNavigationBarAsPlainWhiteWithBoldText];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissController)];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tv.delegate = self;
    self.tv.dataSource = self;
    self.tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    self.tv.backgroundColor = [UIColor systemBackgroundColor];
    [self.tv registerClass:[SSGeneralTableViewCell class] forCellReuseIdentifier:CELL_ID];
    [self.tv registerClass:[SSListSectionHeaderView class] forHeaderFooterViewReuseIdentifier:SS_LIST_SECTION_HEADER_ID];
    
    [self.view addSubview:self.tv];
    
    [self.tv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    __weak typeof(self) weakSelf = self;
    self.onPreferredContentSizeChanged = ^{
        [weakSelf.tv reloadData];
    };
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self deselectTableRow:self.tv];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tv flashScrollIndicators];
}

#pragma mark - Popover Presentation

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    if (self.didSelectShare)
    {
        self.didSelectShare = NO;
        popoverPresentationController.sourceView = [self sourceViewForShareTableViewRow];
        popoverPresentationController.sourceRect = [self sourceRectForshareTableViewRow];
    }
    else
    {
        // 1 == Set Tax Rate
        UITableViewCell *setTaxRateTVC = [self.tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:SECTION_LIST_EDIT]];
        popoverPresentationController.sourceView = setTaxRateTVC;
        popoverPresentationController.sourceRect = CGRectMake(setTaxRateTVC.boundsWidth/2, setTaxRateTVC.boundsHeight/2, 1, 1);
    }
}

- (NSIndexPath *)indexPathForShareRow
{
    return [NSIndexPath indexPathForRow:1 inSection:SECTION_LIST_SHARE];
}

- (UIView *)sourceViewForShareTableViewRow
{
    return [self.tv cellForRowAtIndexPath:[self indexPathForShareRow]];
}

- (CGRect)sourceRectForshareTableViewRow
{
    UITableViewCell *shareListTVC = [self.tv cellForRowAtIndexPath:[self indexPathForShareRow]];
    return CGRectMake(shareListTVC.boundsWidth/2, shareListTVC.boundsHeight/2, 1, 1);
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SECTION_LIST_EDIT) return 4;
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SSGeneralTableViewCell *cell = (SSGeneralTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CELL_ID];
    
    if (indexPath.section == SECTION_LIST_SHARE)
    {
        switch (indexPath.row)
        {
            case 0:
            {
                BOOL listIsShared = self.list.objCKRecord.share != nil;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                NSString *iconImage = listIsShared ? @"person.icloud" : @"person.badge.plus.fill";
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:iconImage] backgroundColor:[UIColor appleBlue]];
                cell.topLabel.text = listIsShared ? ss_Localized(@"list.vc.collab") : ss_Localized(@"list.vc.collabInit");
                cell.hideAllAccessoryViews = YES;
                if (@available(iOS 14.0, *)) {
                    cell.menu = nil;
                }
                
                break;
            }
            case 1:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"square.and.arrow.up.fill"] backgroundColor:[UIColor appleGreen]];
                cell.topLabel.text = ss_Localized(@"general.share");
                cell.hideAllAccessoryViews = YES;
                
                if (@available(iOS 14.0, *)) {
                    cell.menu = [self createShareActionsMenu];
                    [cell.menuButton addAction:[UIAction actionWithHandler:^(UIAction *action) {
                        [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
                        [self.tv selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                        [self.tv deselectRowAtIndexPath:indexPath animated:YES];
                    }] forControlEvents:UIControlEventMenuActionTriggered];
                }
                
                break;
            }
            case 2:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"printer.fill"] backgroundColor:[UIColor appleTealBlue]];
                cell.topLabel.text = ss_Localized(@"general.print");
                cell.hideAllAccessoryViews = YES;
                if (@available(iOS 14.0, *)) {
                    cell.menu = nil;
                }
                
                break;
            }
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_LIST_EDIT)
    {
        switch (indexPath.row)
        {
            case 0:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"signature"] backgroundColor:[UIColor appleNavy]];
                cell.topLabel.text = ss_Localized(@"list.vc.editName");
                cell.showDisclosureIndicator = YES;
                
                break;
            }
            case 1:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"percent"] backgroundColor:[UIColor applePurple]];
                cell.topLabel.text = self.taxRateActionString;
                cell.showDisclosureIndicator = YES;
                
                break;
            }
            case 2:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconImage:[UIImage systemImageNamed:@"coloncurrencysign.circle"] backgroundColor:[UIColor systemGreenColor]];
                cell.topLabel.text = [NSString stringWithFormat:ss_Localized(@"createList.vc.currency"), self.list.currencyCode];
                cell.showDisclosureIndicator = YES;
                
                break;
            }
            case 3:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"trash"] backgroundColor:[UIColor appleRed]];
                cell.topLabel.text = ss_Localized(@"list.vc.removeAll");
                cell.hideAllAccessoryViews = YES;
                
                break;
            }
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_LIST_OPTIONS)
    {
        switch (indexPath.row)
        {
            case 0:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"lock.circle.fill"] backgroundColor:[UIColor appleDarkBlue]];
                cell.topLabel.text = self.authString;
                cell.showSwitch = YES;
                [cell.rightSwitch setOn:self.list.locked];
                
                __weak typeof(self) weakSelf = self;
                cell.onSwitchChanged = ^(BOOL isOn) {
                    [weakSelf attemptAuthSetup:isOn];
                };
                
                break;
            }
            case 1:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] backgroundColor:[UIColor appleDarkGreen]];
                cell.topLabel.text = ss_Localized(@"list.vc.check");
                cell.showSwitch = YES;
                [cell.rightSwitch setOn:self.list.isShowingCheckboxes];
                
                __weak typeof(self) weakSelf = self;
                cell.onSwitchChanged = ^(BOOL isOn) {
                    [weakSelf changeShowCheckboxes:isOn];
                };
                
                break;
            }
            case 2:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"gear"] backgroundColor:[UIColor lightGrayColor]];
                cell.topLabel.text = ss_Localized(@"list.vc.advanced");
                cell.showDisclosureIndicator = YES;
                
                break;
            }
            default:
                break;
        }
    }
    
    cell.hideBottomLabel = YES;
    
    return cell;
}

#pragma mark - Table View Delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = @"";
    
    switch (section)
    {
        case SECTION_LIST_SHARE:
            headerTitle = ss_Localized(@"list.vc.header1");
            break;
        case SECTION_LIST_EDIT:
            headerTitle = ss_Localized(@"list.vc.header2");
            break;
        case SECTION_LIST_OPTIONS:
            headerTitle = ss_Localized(@"list.vc.header3");
            break;
        default:
            break;
    }
    
    SSListSectionHeaderView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SS_LIST_SECTION_HEADER_ID];
    sectionHeaderView.titleString = headerTitle;
    
    return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    SSListSectionHeaderView *sectionHeaderView = (SSListSectionHeaderView *)[tableView.delegate tableView:tableView viewForHeaderInSection:section];
    
    if ([sectionHeaderView isKindOfClass:[SSListSectionHeaderView class]] == NO)
    {
        return 0;
    }
    
    return [sectionHeaderView estimatedHeightForHeaderInView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_LIST_SHARE)
    {
        switch (indexPath.row)
        {
            case 0:
                [self beginShareList];
                break;
            case 1:
                [self presentShareSheet];
                break;
            case 2:
                [self printList];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_LIST_EDIT)
    {
        switch (indexPath.row)
        {
            case 0:
                [self pushEditName];
                break;
            case 1:
            {
                [self pushEditTaxRate];
                break;
            }
            case 2:
            {
                [self pushEditCurrency];
                break;
            }
            case 3:
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                [self deleteEntireList];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_LIST_OPTIONS)
    {
        switch (indexPath.row)
        {
            case 0:
                // Lock list
                break;
            case 1:
                // Checkboxes
                break;
            case 2:
                [self pushAdvancedOptions];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Menu Generators

- (UIMenu *)createShareActionsMenu
{
    void (^showActivityController)(UIViewController *) = ^(UIViewController *activityVC){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentViewController:activityVC animated:YES completion:^{
                
            }];
        });
    };
    
    UIAction *acTextAction = [UIAction actionWithTitle:ss_Localized(@"general.text") image:[UIImage systemImageNamed:@"square.fill.text.grid.1x2"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self.exporter textRepresentationForList]] applicationActivities:nil];
        
        UIPopoverPresentationController *popVC = activityItemVC.popoverPresentationController;
        popVC.sourceView = [self sourceViewForShareTableViewRow];
        popVC.sourceRect = [self sourceRectForshareTableViewRow];
        
        showActivityController(activityItemVC);
    }];

    UIAction *acImageAction = [UIAction actionWithTitle:ss_Localized(@"general.image") image:[UIImage systemImageNamed:@"photo"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self.exporter imageRepresentationForList:[self.delegate ss_tableViewForImageShareSnapshot]]] applicationActivities:nil];
        
        UIPopoverPresentationController *popVC = activityItemVC.popoverPresentationController;
        popVC.sourceView = [self sourceViewForShareTableViewRow];
        popVC.sourceRect = [self sourceRectForshareTableViewRow];

        showActivityController(activityItemVC);
    }];
    
    UIAction *acPDFAction = [UIAction actionWithTitle:ss_Localized(@"list.vc.pdf") image:[UIImage systemImageNamed:@"doc.richtext"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self.exporter pdfRepresentationForList]] applicationActivities:nil];
        
        UIPopoverPresentationController *popVC = activityItemVC.popoverPresentationController;
        popVC.sourceView = [self sourceViewForShareTableViewRow];
        popVC.sourceRect = [self sourceRectForshareTableViewRow];
        
        showActivityController(activityItemVC);
    }];
    
    return [UIMenu menuWithTitle:ss_Localized(@"general.shareList") children:@[acTextAction, acImageAction, acPDFAction]];
}
#pragma mark - Row Actions

- (void)beginShareList
{
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf.delegate ss_userRequestedStartCollaboration];
    }];
}

- (void)presentShareSheet
{
    if (self.traitCollection.isInRegularTraitCollection)
    {
        // So the share sheet row will be used for the popover
        self.didSelectShare = YES;
        
        UIAlertAction *textAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.text") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self.exporter textRepresentationForList]] applicationActivities:nil];
            
            UIPopoverPresentationController *popVC = activityItemVC.popoverPresentationController;
            popVC.sourceView = [self sourceViewForShareTableViewRow];
            popVC.sourceRect = [self sourceRectForshareTableViewRow];
            
            __weak typeof(self) weakSelf = self;
            [self presentViewController:activityItemVC animated:YES completion:^{
                [weakSelf.tv deselectRowAtIndexPath:[self indexPathForShareRow] animated:YES];
            }];
        }];
        
        UIAlertAction *imageAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.image") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self.exporter imageRepresentationForList:[self.delegate ss_tableViewForImageShareSnapshot]]] applicationActivities:nil];
            
            UIPopoverPresentationController *popVC = activityItemVC.popoverPresentationController;
            popVC.sourceView = [self sourceViewForShareTableViewRow];
            popVC.sourceRect = [self sourceRectForshareTableViewRow];
            
            __weak typeof(self) weakSelf = self;
            [self presentViewController:activityItemVC animated:YES completion:^{
                [weakSelf.tv deselectRowAtIndexPath:[self indexPathForShareRow] animated:YES];
            }];
        }];
        
        UIAlertAction *pdfAction = [UIAlertAction actionWithTitle:ss_Localized(@"list.vc.pdf") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self.exporter pdfRepresentationForList]] applicationActivities:nil];
            
            UIPopoverPresentationController *popVC = activityItemVC.popoverPresentationController;
            popVC.sourceView = [self sourceViewForShareTableViewRow];
            popVC.sourceRect = [self sourceRectForshareTableViewRow];
            
            __weak typeof(self) weakSelf = self;
            [self presentViewController:activityItemVC animated:YES completion:^{
                [weakSelf.tv deselectRowAtIndexPath:[self indexPathForShareRow] animated:YES];
            }];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.tv deselectRowAtIndexPath:[self indexPathForShareRow] animated:YES];
        }];
        
        [self showActionSheetWithTitle:ss_Localized(@"general.shareList") message:ss_Localized(@"general.shareLists.method")
                               actions:@[textAction, imageAction, pdfAction, cancelAction]];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.delegate) [self.delegate ss_userRequestedShareSheet];
        }];
    }
}

- (void)pushEditName
{
    SSEditNameViewController *editNameVC = [[SSEditNameViewController alloc] initWithList:self.list];
    editNameVC.onItemRenamed = ^(NSString * _Nullable newName) {
        [self.delegate ss_userRequestedListRename:newName];
    };
    
    [self.navigationController pushViewController:editNameVC animated:YES];
}

- (void)pushEditTaxRate
{
    if (self.list.taxUtil.localeHasDynamicSalesTax == NO && self.list.taxInfo.taxIsEnabled == NO)
    {
        [self pushEnterTaxRateManually];
        return;
    }
    
    NSMutableArray <UIAlertAction *> *actions = [NSMutableArray new];
    
    UIAlertAction *findTaxRateAction = [UIAlertAction actionWithTitle:ss_Localized(@"createList.vc.location") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *handler) {
        [self pushFindTaxRate];
    }];
    
    UIAlertAction *enterTaxRateAction = [UIAlertAction actionWithTitle:ss_Localized(@"createList.vc.manually") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *handler) {
        [self pushEnterTaxRateManually];
    }];
    
    UIAlertAction *removeTaxRateAction = [UIAlertAction actionWithTitle:ss_Localized(@"createList.vc.removeTax") style:UIAlertActionStyleDestructive handler:^ (UIAlertAction *handler) {
        self.list.taxInfo.taxEnabled = NO;
        self.list.taxInfo.taxRate = nil;
        [self reloadTaxIndexPath];
        
        [[DataStore new] updateWithList:self.list completion:^{
            // When this is in Swift, we should pass a list ID here. Otherwise all windows reload.
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_REQUEST_RELOAD_LIST
                                                                object:nil];
        }];
    }];
    
    if (self.list.taxUtil.localeHasDynamicSalesTax) [actions addObject:findTaxRateAction];
    [actions addObject:enterTaxRateAction];
    
    if (self.list.taxInfo.taxIsEnabled)
    {
        [actions addObject:removeTaxRateAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.tv deselectRowAtIndexPath:[self.tv indexPathForSelectedRow] animated:YES];
    }];
    
    [actions addObject:cancelAction];
    
    [self showActionSheetWithTitle:self.taxRateActionString message:nil actions:actions];
}

- (void)pushFindTaxRate
{
    if (self.connectionIsAvailable == NO)
    {
        SSNoConnectionViewController *noConnection = [SSNoConnectionViewController new];
        noConnection.shouldUseSecondaryBackgroundColor = YES;
        [self presentViewController:noConnection animated:YES completion:NULL];
    }
    else if ([[LocationUtil sharedInstance] locationServicesEnabled])
    {
        SSFindTaxRateViewController *findTaxVC = [[SSFindTaxRateViewController alloc] initWithTaxInfo:self.list.taxInfo];
        findTaxVC.shouldUseSecondaryBackgroundColor = YES;
        findTaxVC.onConfirmation = ^(SSTaxRateInfo *taxInfo) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self reloadTaxIndexPath];
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        };
        [self.navigationController pushViewController:findTaxVC animated:YES];
    }
    else
    {
        SSTaxPermissionsViewController *taxPermissionVC = [SSTaxPermissionsViewController new];
        taxPermissionVC.shouldUseSecondaryBackgroundColor = YES;
        [self.navigationController pushViewController:taxPermissionVC animated:YES];
    }
}

- (void)pushEnterTaxRateManually
{
    SSEnterTaxRateViewController *enterTaxRateVC = [[SSEnterTaxRateViewController alloc] initWithTaxInfoAndWhiteBackground:self.list.taxInfo];
    enterTaxRateVC.editingList = self.list;
    enterTaxRateVC.view.backgroundColor = [UIColor systemBackgroundColor];
    enterTaxRateVC.onConfirmation = ^{
        [self reloadTaxIndexPath];
    };
    [self.navigationController pushViewController:enterTaxRateVC animated:YES];
}

- (void)pushEditCurrency
{
    PickCurrencyViewController *pickerVC = [[PickCurrencyViewController alloc] initWithTableViewStyle:UITableViewStyleGrouped];
    __weak PickCurrencyViewController *weakPicker = pickerVC;
    pickerVC.onSelect = ^(NSString * localeID) {
        self.list.currencyIdentifier = localeID;
        self.list.taxUtil = [[TaxUtility alloc] initWithLocaleID:localeID];
        NSIndexPath *idp = self.tv.indexPathForSelectedRow;
        [self.tv reloadData];
        [self.tv selectRowAtIndexPath:idp animated:NO scrollPosition:UITableViewScrollPositionNone];
        [weakPicker.navigationController popToRootViewControllerAnimated:YES];
        [self.delegate ss_userChangedCurrency:localeID];
    };
    [self.navigationController pushViewController:pickerVC animated:YES];
}

- (void)printList
{
    if ([UIPrintInteractionController isPrintingAvailable] == NO)
    {
        [self showAlertControllerWithTitle:ss_Localized(@"general.print.no")
                                   message:ss_Localized(@"general.print.no2")];
        return;
    }
    
    UIPrintInteractionController *printController = [self.exporter printControllerForList];
    
    // Present
    [self dismissViewControllerAnimated:YES completion:^{
        [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
            
        }];
    }];
}

- (void)deleteEntireList
{
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.yes") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if ([self.delegate respondsToSelector:@selector(ss_userRequestedRemoveAllItems:)])
        {
            [self.delegate ss_userRequestedRemoveAllItems:self.list];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:nil];
    
    [self showAlertControllerWithTitle:ss_Localized(@"list.vc.clear")
                               message:ss_Localized(@"list.vc.clear1")
                               actions:@[deleteAction, cancelAction]];
}

- (void)attemptAuthSetup:(BOOL)enabled
{
    self.list.locked = enabled;
    
    if ([self.authCTX authFormIsAvailbleOnDevice] == NO)
    {
        [self showAlertControllerWithTitle:ss_Localized(@"list.vc.lockNo")
                                   message:ss_Localized(@"list.vc.lockNoReason")];
        self.list.locked = NO;
    }
    
    [self.list saveListLocallyAndOnServer:nil];
}

- (void)changeShowCheckboxes:(BOOL)isShowingCheckboxes
{
    [self.delegate ss_userRequestedCheckboxToggle:self.list];
}

- (void)pushAdvancedOptions
{
    [self.navigationController pushViewController:[[SSAdvancedListOptionsViewController alloc] initWithList:self.list scope:OptionScopeList] animated:YES];
}

- (void)reloadTaxIndexPath
{
    NSIndexPath *taxIDP = [NSIndexPath indexPathForItem:1 inSection:SECTION_LIST_EDIT];
    [self.tv reloadRowsAtIndexPaths:@[taxIDP] withRowAnimation:UITableViewRowAnimationFade];
}

@end
