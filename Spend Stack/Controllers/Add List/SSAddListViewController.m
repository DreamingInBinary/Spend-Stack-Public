//
//  SSAddListViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSAddListViewController.h"
#import "SSTaxPermissionsViewController.h"
#import "SSFindTaxRateViewController.h"
#import "SSEnterTaxRateViewController.h"
#import "SSNoConnectionViewController.h"
#import "SSExplainerViewController.h"
#import "SSConstants.h"
#import "LocationUtil.h"
#import "IQKeyboardManager.h"
#import "UIImageView+SSUtils.h"
#import "UIImage+Utils.h"
#import "UITableView+Common.h"
#import "UITableViewCell+Common.h"
#import "Spend_Stack_2-Swift.h"

@interface SSAddListViewController() <UITableViewDataSource,
                                      UITableViewDelegate>

@property (strong, nonatomic, nonnull) SSTextField *nameTextField;
@property (strong, nonatomic, nonnull) UITableView *tableView;
@property (strong, nonatomic, nonnull) UIView *textFieldContainerView;

@end

static NSString * const ADD_LIST_VC_CELL_ID = @"cell";
static NSInteger const SECTION_TAX = 0;
static NSInteger const SECTION_CHECKBOX_CURRENCY = 1;
static NSInteger const TAX_SWITCH = 0;
static NSInteger const TAX_TOGGLE = 1;

@implementation SSAddListViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.workingList = [SSList new];
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSInteger orderingIndex = [db mostRecentOrderingIndexForLists];
        if (isnan(orderingIndex)) orderingIndex = 0;
        self.workingList.orderingIndex = @(orderingIndex);
    }];
    
    self.title = ss_Localized(@"createList.vc.title");
    
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissController)];
    UIBarButtonItem *helpBarButton;
    if (@available(iOS 14.0, *)) {
        helpBarButton = [[UIBarButtonItem alloc] initWithTitle:ss_Localized(@"general.help") menu:[self createExplainSheetMenu]];
    } else {
        helpBarButton = [[UIBarButtonItem alloc] initWithTitle:ss_Localized(@"general.help") style:UIBarButtonItemStylePlain target:self action:@selector(presentExplainSheet)];
    }
    self.navigationItem.rightBarButtonItem = cancelBarButton;
    self.navigationItem.leftBarButtonItem = helpBarButton;
    
    [SSCitizenship setViewAsTransparentIfPossible:self.view];
    
    CGRect contentGuide = self.view.readableContentGuide.layoutFrame;
    CGFloat listNameHeaderHeightMultiplier = .20f;
    CGRect tableViewHeaderRect = CGRectMake(contentGuide.origin.x, 0, contentGuide.size.width, self.view.boundsHeight * -listNameHeaderHeightMultiplier);
    
    self.nameTextField = [[SSTextField alloc] initWithTextStyle:UIFontTextStyleTitle1];
    self.nameTextField.textColor = [UIColor ssTextPlaceholderColor];
    self.nameTextField.placeholder = ss_Localized(@"createList.vc.untitled");
    self.nameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.nameTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.nameTextField.mas_key = @"listTextField";
    self.nameTextField.frame = tableViewHeaderRect;
    [self.nameTextField configureFontWeight:UIFontWeightBold];
    
    self.textFieldContainerView = [UIView new];
    [self.view addSubview:self.textFieldContainerView];
    [self.textFieldContainerView addSubview:self.nameTextField];
    [self.textFieldContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top);
        make.left.and.right.equalTo(self.view);
        make.height.greaterThanOrEqualTo(@(fabs(tableViewHeaderRect.size.height)));
    }];
    [self updateTextFieldConstraints];
    
    UITableViewStyle style;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        style = UITableViewStyleInsetGrouped;
    } else {
        style = UITableViewStyleGrouped;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:style];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ADD_LIST_VC_CELL_ID];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.tableView.mas_key = @"tableView";
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textFieldContainerView.mas_bottom);
        make.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    NSArray <SSToolBarItem *> *items;
    if (self.isiPad)
    {
        items = @[SSToolBarItemTypeFlexSpace, SSToolBarItemTypeAddItem];
    }
    else
    {
        items = @[SSToolBarItemTypeMutedKeyboardDown, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeAddItem];
    }
    SSToolbar *toolBar = [[SSToolbar alloc] initWithItemTypes:items];
    __weak SSAddListViewController *weakSelf = self;
    toolBar.onKeyboardDown = ^{
        [weakSelf.nameTextField resignFirstResponder];
    };
    toolBar.onAddItem = ^{
        [weakSelf createList];
    };
    toolBar.clipsToBounds = NO;
    
    self.nameTextField.inputAccessoryView = toolBar;
    
    self.onPreferredContentSizeChanged = ^{
        [weakSelf.tableView reloadData];
    };
    
    [IQKeyboardManager sharedManager].enable = NO;
    
    // Give it a default currency if it's nil
    if (self.workingList.currencyCode == nil)
    {
        self.workingList.currencyIdentifier = @"en_US";
        self.workingList.taxUtil = [[TaxUtility alloc] initWithLocaleID:@"en_US"];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.nameTextField becomeFirstResponder];
    });
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateTextFieldConstraints];
}

#pragma mark - Textfield Constraints

- (void)updateTextFieldConstraints
{
    // The initial constraints make the textFiew too far to the left in portrait, but perfect in
    // Landscape. So, I need to set an offset in portrait that's unneeded in landscape.
    CGFloat leadingOffset = [self.view isLandscape] ? 0 : SSLeftElementMargin;

    [self.nameTextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textFieldContainerView.mas_readableContentGuideLeft).with.offset(leadingOffset);
        make.right.equalTo(self.textFieldContainerView.mas_readableContentGuideRight);
        make.height.equalTo(self.nameTextField.mas_height);
        make.bottom.equalTo(self.textFieldContainerView.mas_bottom);
    }];
}

#pragma mark - Popover Presentation

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    // Is this from setting a tax rate or choosing help?
    NSString *presentingTitle = popoverPresentationController.presentedViewController.title;
    
    if ([presentingTitle isEqualToString:ss_Localized(@"createList.vc.set")])
    {
        UITableViewCell *setTaxRateTVC = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        popoverPresentationController.sourceView = [setTaxRateTVC accessoryView];
        popoverPresentationController.sourceRect = CGRectMake(8, [setTaxRateTVC accessoryView].boundsHeight/2, 1, 1);
    }
    else if ([presentingTitle isEqualToString:ss_Localized(@"ham.vc.learn")])
    {
        popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    }
}

#pragma mark - Tableview Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.workingList.taxInfo.taxIsEnabled ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SECTION_TAX) return self.workingList.taxInfo.taxEnabled ? 2 : 3;
    if (section == SECTION_CHECKBOX_CURRENCY) return 2;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ADD_LIST_VC_CELL_ID forIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor ssMainFontColor];
    cell.selectedBackgroundView = [cell ssSelectionView];
    cell.textLabel.numberOfLines = 0;
    cell.imageView.tintColor = [UIColor systemGrayColor];
    cell.imageView.contentMode = UIViewContentModeCenter;
    CGSize preferredIconSize = CGSizeMake(18, 18);
    
    NSString *currencyText = [NSString stringWithFormat:ss_Localized(@"createList.vc.currency"), self.workingList.currencyCode];
    
    if (indexPath.section == SECTION_TAX)
    {
        if (indexPath.row == TAX_SWITCH)
        {
            
            NSString *text = [NSString stringWithFormat:ss_Localized(@"createList.vc.apply"), self.workingList.taxUtil.localizedTaxRateString];
            
            if (self.workingList.taxUtil.localeHasDynamicSalesTax || self.workingList.taxInfo.taxIsEnabled)
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *taxSwitch = [UISwitch new];
                [taxSwitch addTarget:self action:@selector(onTaxToggleChange:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = taxSwitch;
                taxSwitch.onTintColor = [UIColor ssPrimaryColor];
                [taxSwitch setOn:self.workingList.taxInfo.taxIsEnabled animated:YES];
            }
            else
            {
                // Outside US, so propose manual entry
                cell.accessoryView = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            cell.textLabel.text = text;
            cell.imageView.image = [[[UIImage systemImageNamed:@"plus.circle.fill"] imageScaledToSize:preferredIconSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.tintColor = [UIColor systemBlueColor];
        }
        else if (indexPath.row == TAX_TOGGLE)
        {
            if (self.workingList.taxInfo.taxEnabled)
            {
                cell.accessoryView = nil;
                
                if (self.workingList.taxInfo.taxRate && self.workingList.taxInfo.taxIsEnabled == NO)
                {
                    cell.textLabel.text = ss_Localized(@"createList.vc.set");
                }
                else if (self.workingList.taxInfo.wasManuallySet && self.workingList.taxInfo.taxRate)
                {
                    cell.textLabel.text = [NSString stringWithFormat:ss_Localized(@"createList.vc.setTo"), self.workingList.taxInfo.taxRateStringValue];
                }
                else if (self.workingList.taxInfo.localSalesTaxLocation && self.workingList.taxInfo.taxRate)
                {
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", self.workingList.taxInfo.localSalesTaxLocation, self.workingList.taxInfo.taxRateStringValue];
                }
                else
                {
                    cell.textLabel.text = ss_Localized(@"createList.vc.set");
                }
                
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else
            {
                UISwitch *checkBoxSwitch = [UISwitch new];
                [checkBoxSwitch addTarget:self action:@selector(setWorkingListIsUsingCheckboxes:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = checkBoxSwitch;
                checkBoxSwitch.onTintColor = [UIColor ssPrimaryColor];
                [checkBoxSwitch setOn:self.workingList.isShowingCheckboxes animated:YES];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = ss_Localized(@"createList.vc.checks");
                cell.imageView.image = [[[UIImage systemImageNamed:@"checkmark.circle.fill"] imageScaledToSize:preferredIconSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imageView.tintColor = [UIColor systemIndigoColor];
            }
        }
        else
        {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.text = currencyText;
            cell.imageView.image = [[[UIImage systemImageNamed:@"coloncurrencysign.circle.fill"] imageScaledToSize:preferredIconSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.tintColor = [UIColor systemGreenColor];
        }
    }
    else if (indexPath.section == SECTION_CHECKBOX_CURRENCY)
    {
        if (indexPath.row == 0 )
        {
            UISwitch *checkBoxSwitch = [UISwitch new];
            [checkBoxSwitch addTarget:self action:@selector(setWorkingListIsUsingCheckboxes:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = checkBoxSwitch;
            checkBoxSwitch.onTintColor = [UIColor ssPrimaryColor];
            [checkBoxSwitch setOn:self.workingList.isShowingCheckboxes animated:YES];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = ss_Localized(@"createList.vc.checks");
            cell.imageView.image = [[[UIImage systemImageNamed:@"checkmark.circle.fill"] imageScaledToSize:preferredIconSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.tintColor = [UIColor systemIndigoColor];
        }
        else
        {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;\
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.text = currencyText;
            cell.imageView.image = [[[UIImage systemImageNamed:@"coloncurrencysign.circle.fill"] imageScaledToSize:preferredIconSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.tintColor = [UIColor systemGreenColor];
        }
    }
    
    return cell;
}

#pragma mark - Tableview Delegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tvc = [tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    NSString *cellText = tvc.textLabel.text;
    
    // Account for the switch cell
    BOOL hasSwitch = indexPath.section == SECTION_TAX && indexPath.row != TAX_TOGGLE;
    CGFloat cellContentWidth = (tvc.contentView.boundsWidth - tvc.layoutMargins.left) * (hasSwitch ? 0.66f : 0.90);
    CGFloat textHeight = [cellText boundingRectWithWidth:cellContentWidth
                                                    text:cellText
                                                    font:tvc.textLabel.font].size.height;
    
    return (textHeight + tvc.layoutMargins.top + tvc.layoutMargins.bottom);
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BOOL isCurrencyIDP = (indexPath.row == 2 || (indexPath.section == 1 && indexPath.row == 1));
    
    if (isCurrencyIDP)
    {
        [self pushSelectCurrency];
        return;
    }
    
    if (self.workingList.taxUtil.localeHasDynamicSalesTax == NO)
    {
        [self pushEnterTaxRateManually];
        return;
    }
    
    if (indexPath.section == SECTION_TAX && indexPath.row == TAX_TOGGLE && self.workingList.taxInfo.taxEnabled)
    {
        [self selectTaxRateEntryMethod];
    }
}

#pragma mark - Checkbox Toggle

- (void)setWorkingListIsUsingCheckboxes:(UISwitch *)sender
{
    self.workingList.showingCheckboxes = sender.isOn;
}

#pragma mark - Tax Rate Entry/Search

- (void)selectTaxRateEntryMethod
{
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.nameTextField resignFirstResponder];
        
        // Select entry methd
        UIAlertAction *findTaxRateAction = [UIAlertAction actionWithTitle:ss_Localized(@"createList.vc.location") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *handler) {
            [self pushFindTaxRate];
        }];
        
        NSString *localeTaxString = [NSString stringWithFormat:ss_Localized(@"createList.vc.use"), self.workingList.taxUtil.localizedTaxRateString, self.workingList.taxUtil.countryVATString];
        UIAlertAction *userLocaleAction = [UIAlertAction actionWithTitle:localeTaxString style:UIAlertActionStyleDefault handler:^ (UIAlertAction *handler) {
            NSString *vat = self.workingList.taxUtil.countryVATString;
            [self.workingList.taxUtil decimalTaxValueFromString:vat result:^(BOOL valid, NSString * _Nullable errorReason, NSDecimalNumber * _Nullable taxRate) {
                if (valid)
                {
                    self.workingList.taxInfo.taxRate = taxRate;
                    self.workingList.taxInfo.taxEnabled = YES;
                    self.workingList.taxInfo.localSalesTaxLocation = self.workingList.taxUtil.localizedTaxRateLocationString;
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.nameTextField becomeFirstResponder];
                    });
                }
                else
                {
                    [self showAlertControllerWithTitle:ss_Localized(@"general.error.title") message:errorReason];
                }
            }];
        }];
        
        UIAlertAction *enterTaxRateAction = [UIAlertAction actionWithTitle:ss_Localized(@"createList.vc.manually") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *handler) {
            [self pushEnterTaxRateManually];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:^ (UIAlertAction *handler) {
            [self.nameTextField becomeFirstResponder];

            //If they switched it on and didn't make any edits
            if (self.workingList.taxInfo.taxRate == nil && self.workingList.taxInfo.wasManuallySet == NO)
            {
                self.workingList.taxInfo.taxEnabled = NO;
            }
            else if (self.workingList.taxInfo.taxRate == nil)
            {
                self.workingList.taxInfo.taxEnabled = NO;
            }

            [((UISwitch *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].accessoryView) setOn:self.workingList.taxInfo.taxIsEnabled animated:YES];
        }];
        
        [self showActionSheetWithTitle:self.workingList.taxInfo.taxRate ? ss_Localized(@"createList.vc.edit") : ss_Localized(@"createList.vc.set") message:nil actions:@[self.workingList.taxUtil.localeHasDynamicSalesTax ? findTaxRateAction : userLocaleAction, enterTaxRateAction, cancelAction]];
    });
}

- (void)pushFindTaxRate
{
    if (self.connectionIsAvailable == NO)
    {
        SSNoConnectionViewController *connectionVC = [SSNoConnectionViewController new];
        [SSPopupModalPresentationController presentPresentationControllerFromController:self
                                                                    presentedController:connectionVC];
    }
    else if ([[LocationUtil sharedInstance] locationServicesEnabled])
    {
        SSFindTaxRateViewController *findTaxVC = [[SSFindTaxRateViewController alloc] initWithTaxInfo:self.workingList.taxInfo];
        findTaxVC.onConfirmation = ^(SSTaxRateInfo *taxInfo) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        };
        [self.navigationController pushViewController:findTaxVC animated:YES];
    }
    else
    {
        SSTaxPermissionsViewController *taxPermissionVC = [SSTaxPermissionsViewController new];
        [self.navigationController pushViewController:taxPermissionVC animated:YES];
    }
}

- (void)pushEnterTaxRateManually
{
    SSEnterTaxRateViewController *enterTaxRateVC = [[SSEnterTaxRateViewController alloc] initWithTaxInfo:self.workingList.taxInfo];
    [self.navigationController pushViewController:enterTaxRateVC animated:YES];
}

#pragma mark - Tax Toggling

- (void)onTaxToggleChange:(UISwitch *)sender
{
    self.workingList.taxInfo.taxEnabled = sender.isOn;
    
    if (self.workingList.taxInfo.taxEnabled)
    {
        if (self.workingList.taxUtil.localeHasDynamicSalesTax)
        {
            [self selectTaxRateEntryMethod];
        }
        else
        {
            [self pushEnterTaxRateManually];
        }
    }
    else
    {
        [self.tableView performBatchUpdates:^{
            //Clear out previous tax rate
            self.workingList.taxInfo.taxRate = nil;
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0],[NSIndexPath indexPathForRow:1 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:^(BOOL finished) {
            
        }];
    }
}

#pragma mark - Currency Picker

- (void)pushSelectCurrency
{
    PickCurrencyViewController *pickerVC = [PickCurrencyViewController new];
    __weak PickCurrencyViewController *weakPicker = pickerVC;
    pickerVC.onSelect = ^(NSString * localeID) {
        self.workingList.currencyIdentifier = localeID;
        self.workingList.taxUtil = [[TaxUtility alloc] initWithLocaleID:localeID];
        [self.tableView reloadData];
        [weakPicker.navigationController popToRootViewControllerAnimated:YES];
    };
    [self.navigationController pushViewController:pickerVC animated:YES];
}

#pragma mark - Misc

- (UIMenu *)createExplainSheetMenu API_AVAILABLE(ios(14.0))
{
    NSMutableArray <UIAction *> *actions = [NSMutableArray new];
    
    if (self.workingList.taxUtil.localeHasDynamicSalesTax)
    {
        UIAction *acTax = [UIAction actionWithTitle:ss_Localized(@"ex.util.tax") image:[UIImage systemImageNamed:@"percent"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showExplainerOfType:ExplainFeatureNewListTax];
            });
        }];
        [actions addObject:acTax];
    }
    
    UIAction *acChecklist = [UIAction actionWithTitle:ss_Localized(@"ex.util.check") image:[UIImage systemImageNamed:@"checkmark.circle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showExplainerOfType:ExplainFeatureNewListChecklist];
        });
    }];
    [actions addObject:acChecklist];
    
    UIAction *acCurrency = [UIAction actionWithTitle:ss_Localized(@"ex.util.currency") image:[UIImage systemImageNamed:@"dollarsign.circle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showExplainerOfType:ExplainFeatureNewListCurrency];
        });
    }];
    [actions addObject:acCurrency];

    return [UIMenu menuWithChildren:actions];
}

- (void)presentExplainSheet
{
    NSMutableArray <UIAlertAction *> *actions = [NSMutableArray new];
    
    if (self.workingList.taxUtil.localeHasDynamicSalesTax)
    {
        UIAlertAction *tax = [UIAlertAction actionWithTitle:ss_Localized(@"ex.util.tax") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showExplainerOfType:ExplainFeatureNewListTax];
            });
        }];
        [actions addObject:tax];
    }
    
    UIAlertAction *checklist = [UIAlertAction actionWithTitle:ss_Localized(@"ex.util.check") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showExplainerOfType:ExplainFeatureNewListChecklist];
        });
    }];
    [actions addObject:checklist];
    
    UIAlertAction *currency = [UIAlertAction actionWithTitle:ss_Localized(@"ex.util.currency") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SSUIKitTableViewBatchAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showExplainerOfType:ExplainFeatureNewListCurrency];
        });
    }];
    [actions addObject:currency];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:nil];
    [actions addObject:cancel];

    [self showActionSheetWithTitle:ss_Localized(@"ham.vc.learn") message:nil actions:actions];
}

- (void)showExplainerOfType:(ExplainFeature)feature
{
    [self.nameTextField resignFirstResponder];
    
    SSExplainerViewController *explainerVC = [[SSExplainerViewController alloc] initWithExplainedFeature:feature];
    explainerVC.showDoneButton = YES;
    explainerVC.onDismiss = ^{
        [self.nameTextField becomeFirstResponder];
    };
    
    [SSPopupModalPresentationController presentPresentationControllerFromController:self
                                                                presentedController:explainerVC];
}

- (void)createList
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSuccess];
    [self playSoundNamed:@"createdDing"];
    
    [self.nameTextField resignFirstResponder];
    self.workingList.name = [self.nameTextField.text isEqualToString:@""] ? ss_Localized(@"createList.vc.untitled") : self.nameTextField.text;
    self.workingList.name = [self.workingList.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL success = [db insertListIntoDB:self.workingList];
        NSLog(@"Spend Stack - New List insert successful:%@", @(success));

        self.workingList.taxInfo.fkListID = self.workingList.dbID;
        
        success = [db insertTaxRateInfoIntoDB:self.workingList.taxInfo];
        NSLog(@"Spend Stack - New tax rate info Write successful:%@", @(success));
        
        FMResultSet *result = [db executeQuery:sql_ListWithTaxRateInfoSelectFromListID, self.workingList.dbID];
        
        SSList *list;
        while ([result next])
        {
            list = [[SSList alloc] initWithResultSet:result];
        }
        
        self.workingList = list;
        
        [[SSDataStore sharedInstance].ckManager.privateDB saveObjects:@[list, list.taxInfo]
                                                       withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                                                        deleteObjects:@[]
                                                       withCompletion:^(NSError * error) {
            NSLog(@"Spend Stack - Save list and tax rate with error:(%@)", error);
        }];
        
        NSAssert(self.workingList.taxInfo != nil, @"Attemping to create a list with a nil taxInfo reference.");
        
        [self dismissControllerAndTextView:YES];
    }];
}

- (void)dismissControllerAndTextView:(BOOL)signalListCreated
{
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.nameTextField resignFirstResponder];
        
        if (signalListCreated)
        {
            
            // If we made it from a compact environment, don't show a weird state of dimissing, selecting a row and pushing a detail controller. You can't forgo animating
            // Showing a detail view unfortunately. So this is a psuedo transition to mask it.
            UIWindow *window = self.view.window;
            if (window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
            {
                [ListCreatedPayloadShim sendListCreatedPayloadWithAnimateReload:NO
                                                                  windowSceneID:self.windowSceneID];
                
                UIView *blockingView = [UIView new];
                blockingView.backgroundColor = [UIColor systemBackgroundColor];
                UIView *snapshot = [self.navigationController.view snapshotViewAfterScreenUpdates:NO];
                UIView *blurIt = [SSCitizenship transparentViewIfPossible];
                [SSCitizenship setViewFadeOutAnimation:blurIt];
                
                UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                
                snapshot.autoresizingMask = mask;
                blockingView.autoresizingMask = mask;
                blurIt.autoresizingMask = mask;
                
                blurIt.frame = snapshot.frame;
                blockingView.frame = snapshot.frame;
                
                [window addSubview:blockingView];
                [window addSubview:snapshot];
                [window addSubview:blurIt];
                
                [self dismissViewControllerAnimated:YES completion:nil];
                
                [UIView animateWithDuration:0.85f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    snapshot.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
                    snapshot.alpha = 0.0f;
                    [SSCitizenship setViewFadeInAnimation:blurIt];
                } completion:^(BOOL finished) {
                    if (finished)
                    {
                        [blockingView removeFromSuperview];
                        [snapshot removeFromSuperview];
                        
                        [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
                            [SSCitizenship setViewFadeOutAnimation:blurIt];
                        } completion:^(BOOL finished) {
                            if (finished)
                            {
                                [blurIt removeFromSuperview];
                            }
                        }];
                    }
                }];
            }
            else
            {
                // Here, we want to see the row added and then the detail view being shown
                [self dismissViewControllerAnimated:YES completion:^{
                    [ListCreatedPayloadShim sendListCreatedPayloadWithAnimateReload:YES
                                                                      windowSceneID:self.windowSceneID];
                }];
            }
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

@end
