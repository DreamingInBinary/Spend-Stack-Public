//
//  SSHelpAndMoreViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/19/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSHelpAndMoreViewController.h"
#import "SSGeneralTableViewCell.h"
#import "SSAboutViewController.h"
#import "EmailSender.h"
#import "TwitterLinkOpener.h"
#import "RedditLinkOpener.h"
#import "SSExplainerViewController.h"
#import "SSTagsViewController.h"
#import "SSListSectionHeaderView.h"
#import "SSTagSelectionViewModel.h"
#import "SSPrivacyViewController.h"
#import "SSLicensesViewController.h"
#import "SSAdvancedListOptionsViewController.h"
#import "NSLocale+Utils.h"
#import "Spend_Stack_2-Swift.h"
#import <SafariServices/SafariServices.h>

static NSInteger const SECTION_TIPS = 0;
static NSInteger const SECTION_APPEARANCE = 1;
static NSInteger const SECTION_LIST_SETTINGS = 2;
static NSInteger const SECTION_REACH_OUT = 3;
static NSInteger const SECTION_COLOPHON = 4;

@interface SSHelpAndMoreViewController () <UITableViewDataSource, UITableViewDelegate, SSTagsViewControllerDelegate>

@property (strong, nonatomic, nonnull) EmailSender *emailer;
@property (strong, nonatomic, nonnull) UITableView *tv;
@property (nonatomic, getter=shouldShowTagFooters) BOOL showTagFooters;
@property (nonatomic, getter=shouldShowListTotal) BOOL showListTotal;
@property (nonatomic, getter=shouldUseWholeNumbers) BOOL useWholeNumbers;

@end

@implementation SSHelpAndMoreViewController

#pragma mark - Custom Getters and Setters

- (BOOL)shouldShowTagFooters
{
    return [ss_defaults() boolForKey:Show_Tag_Footers];
}

- (void)setShowTagFooters:(BOOL)showTagFooters
{
    [ss_defaults() setBool:showTagFooters forKey:Show_Tag_Footers];
    [ss_defaults() synchronize];
}

- (BOOL)shouldShowListTotal
{
    return [ss_defaults() boolForKey:Show_List_Total];
}

- (void)setShowListTotal:(BOOL)showListTotal
{
    [ss_defaults() setBool:showListTotal forKey:Show_List_Total];
    [ss_defaults() synchronize];
}

- (BOOL)shouldUseWholeNumbers
{
    return [ss_defaults() boolForKey:Use_Whole_Numbers];
}

- (void)setUseWholeNumbers:(BOOL)useWholeNumbers
{
    [ss_defaults() setBool:useWholeNumbers forKey:Use_Whole_Numbers];
    [ss_defaults() synchronize];
    [[SwiftShims new] reloadWidgets];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = ss_Localized(@"ham.vc.title");
    self.emailer = [[EmailSender alloc] initWithContainingController:self];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
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
    [self.tv registerClass:[SSGeneralTableViewCell class] forCellReuseIdentifier:GENERAL_CELL_ID];
    [self.tv registerClass:[SSListSectionHeaderView class] forHeaderFooterViewReuseIdentifier:SS_LIST_SECTION_HEADER_ID];
    
    [self.view addSubview:self.tv];
    
    [self.tv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomElementMargin);
    }];
    
    __weak SSHelpAndMoreViewController *weakSelf = self;
    self.onPreferredContentSizeChanged = ^{
        [weakSelf.tv reloadData];
    };
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

- (NSArray <UIKeyCommand *> *)keyCommands
{
    return @[[self dismissOrPopControllerKeyCommand]];
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_TIPS:
            return 1;
            break;
        case SECTION_APPEARANCE:
            return 1;
            break;
        case SECTION_LIST_SETTINGS:
            return 5;
            break;
        case SECTION_REACH_OUT:
            return [NSLocale isUnitedStates] ? 3 : 4; // Localization helper menu
            break;
        case SECTION_COLOPHON:
            return 4;
            break;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SSGeneralTableViewCell *cell = (SSGeneralTableViewCell *)[tableView dequeueReusableCellWithIdentifier:GENERAL_CELL_ID];
    [cell setPointerInteractionEnabled:NO];
    
    if (indexPath.section == SECTION_TIPS)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"lightbulb.fill"] backgroundColor:[UIColor systemBlueColor]];
        cell.topLabel.text = ss_Localized(@"ham.vc.guides");
        cell.bottomLabel.text = ss_Localized(@"ham.vc.guides2");
        cell.showSwitch = NO;
        cell.styleBottomLabelAsButton = NO;
    }
    else if (indexPath.section == SECTION_APPEARANCE)
    {
        cell.showDisclosureIndicator = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"paintbrush"] backgroundColor:[UIColor systemTealColor]];
        cell.topLabel.text = ss_Localized(@"ham.vc.appearance");
        cell.bottomLabel.text = ss_Localized(@"ham.vc.appearance2");
        cell.showSwitch = NO;
        cell.styleBottomLabelAsButton = NO;
    }
    else if (indexPath.section == SECTION_LIST_SETTINGS)
    {
        __weak typeof(self) weakSelf = self;
        switch (indexPath.row)
        {
            case 0:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"tag.fill"] backgroundColor:[UIColor appleNavy]];
                cell.topLabel.text = ss_Localized(@"ham.vc.manage");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.tags");
                cell.showSwitch = NO;
                cell.styleBottomLabelAsButton = NO;
                
                break;
            }
            case 1:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell setLeadingIconImage:[UIImage imageNamed:@"tagTotal"] backgroundColor:[UIColor appleGreen]];
                cell.topLabel.text = ss_Localized(@"ham.vc.totals");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.learn");
                cell.showSwitch = YES;
                cell.styleBottomLabelAsButton = YES;
                [cell setPointerInteractionEnabled:YES];
                [cell.rightSwitch setOn:self.shouldShowTagFooters];
                
                cell.onBottomLabelTapped = ^{
                    SSExplainerViewController *explainerVC = [[SSExplainerViewController alloc] initWithExplainedFeature:ExplainFeatureTagsFooterTotals];
                    [weakSelf.navigationController pushViewController:explainerVC animated:YES];
                };
                cell.onSwitchChanged = ^(BOOL isOn) {
                    weakSelf.showTagFooters = isOn;
                    [[NSNotificationCenter defaultCenter] postNotificationName:SS_SHOW_TAG_FOOTER_TOGGLED object:@(isOn)];
                };
                break;
            }
            case 2:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell setLeadingIconImage:[UIImage imageNamed:@"totalFill"] backgroundColor:[UIColor appleTealBlue]];
                cell.topLabel.text = ss_Localized(@"ham.vc.listTotal");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.learn");
                cell.showSwitch = YES;
                cell.styleBottomLabelAsButton = YES;
                [cell setPointerInteractionEnabled:YES];
                [cell.rightSwitch setOn:self.shouldShowListTotal];
                
                cell.onBottomLabelTapped = ^{
                    SSExplainerViewController *explainerVC = [[SSExplainerViewController alloc] initWithExplainedFeature:ExplainFeatureTotalHeader];
                    [weakSelf.navigationController pushViewController:explainerVC animated:YES];
                };
                cell.onSwitchChanged = ^(BOOL isOn) {
                    weakSelf.showListTotal = isOn;
                    [[NSNotificationCenter defaultCenter] postNotificationName:SS_SHOW_LIST_TOTAL_TOGGLED object:@(isOn)];
                };
                break;
            }
            case 3:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                NSString *imgName = @"01.circle.fill";
                if (self.useWholeNumbers) {
                    imgName = @"1.circle.fill";
                }
                [cell setLeadingIconImage:[UIImage systemImageNamed:imgName] backgroundColor:[UIColor applePurple]];
                cell.topLabel.text = ss_Localized(@"ham.vc.wholeNum");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.learn");
                cell.showSwitch = YES;
                cell.styleBottomLabelAsButton = YES;
                [cell setPointerInteractionEnabled:YES];
                [cell.rightSwitch setOn:self.shouldUseWholeNumbers];
                
                cell.onBottomLabelTapped = ^{
                    SSExplainerViewController *explainerVC = [[SSExplainerViewController alloc] initWithExplainedFeature:ExplainFeatureUseWholeNumbers];
                    [weakSelf.navigationController pushViewController:explainerVC animated:YES];
                };
                cell.onSwitchChanged = ^(BOOL isOn) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        weakSelf.useWholeNumbers = isOn;
                        [weakSelf.tv reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        [[NSNotificationCenter defaultCenter] postNotificationName:SS_WHOLE_NUMBERS_TOGGLED object:nil];
                    });
                };
                break;
            }
            case 4:
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"gear"] backgroundColor:[UIColor lightGrayColor]];
                cell.topLabel.text = ss_Localized(@"general.advanced");
                cell.showDisclosureIndicator = YES;
                cell.bottomLabel.text = ss_Localized(@"ham.vc.more");
                break;
            }
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_REACH_OUT)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.showDisclosureIndicator = YES;
        cell.styleBottomLabelAsButton = NO;
        
        switch (indexPath.row)
        {
            case 0:
            {
                UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:14];
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill" withConfiguration:symbolConfig] backgroundColor:[UIColor applePurple]];
                cell.topLabel.text = ss_Localized(@"ham.vc.contact");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.question");
                break;
            }
            case 1:
                [cell setLeadingIconImage:[UIImage imageNamed:@"twitter"] backgroundColor:[UIColor twitterBlue]];
                cell.topLabel.text = ss_Localized(@"ham.vc.tweet");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.upToDate");
                break;
            case 2:
                [cell setLeadingIconImage:[UIImage imageNamed:@"reddit"] backgroundColor:[UIColor redditOrange]];
                cell.topLabel.text = ss_Localized(@"ham.vc.reddit");
                cell.bottomLabel.text =ss_Localized(@"ham.vc.reddit2");
                break;
            case 3:
                [cell setLeadingIconImage:[UIImage imageNamed:@"translate"] backgroundColor:[UIColor appleDarkPurple]];
                cell.topLabel.text = ss_Localized(@"ham.vc.localize");
                cell.bottomLabel.text =ss_Localized(@"ham.vc.localize2");
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_COLOPHON)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.showDisclosureIndicator = YES;
        switch (indexPath.row)
        {
            case 0:
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"info"] backgroundColor:[UIColor appleOrange]];
                cell.topLabel.text = ss_Localized(@"general.about");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.version");
                cell.styleBottomLabelAsButton = NO;
                break;
            case 1:
                [cell setLeadingIconWithSystemImage:[UIImage systemImageNamed:@"heart.fill"] backgroundColor:[UIColor applePink]];
                cell.topLabel.text = ss_Localized(@"ham.vc.review");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.review2");
                cell.styleBottomLabelAsButton = NO;
                break;
            case 2:
                [cell setLeadingIconImage:[UIImage systemImageNamed:@"hand.raised.slash.fill"] backgroundColor:[UIColor appleDarkGreen]];
                cell.topLabel.text = ss_Localized(@"ham.vc.privacy");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.privacy2");
                cell.styleBottomLabelAsButton = NO;
                break;
            case 3:
                [cell setLeadingIconImage:[UIImage systemImageNamed:@"person.circle.fill"] backgroundColor:[UIColor appleDarkPurple]];
                cell.topLabel.text = ss_Localized(@"ham.vc.acknowledge");
                cell.bottomLabel.text = ss_Localized(@"ham.vc.acknowledge2");
                cell.styleBottomLabelAsButton = NO;
            default:
                break;
        }
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = @"";
    
    switch (section)
    {
        case SECTION_TIPS:
            headerTitle =  ss_Localized(@"ham.vc.header00");
            break;
        case SECTION_APPEARANCE:
            headerTitle =  ss_Localized(@"ham.vc.header0");
            break;
        case SECTION_LIST_SETTINGS:
            headerTitle =  ss_Localized(@"ham.vc.header1");
            break;
        case SECTION_REACH_OUT:
            headerTitle =  ss_Localized(@"ham.vc.header2");
            break;
        case SECTION_COLOPHON:
            headerTitle =  ss_Localized(@"ham.vc.header3");
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
    if (indexPath.section == SECTION_TIPS)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        UIViewController *parentVC = self.presentingViewController;
        [self dismissViewControllerAnimated:YES completion:^{
            SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.spendstack.com/sharing-christmas-lists/"]];
            safariVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [parentVC presentViewController:safariVC animated:YES completion:nil];
        }];
    }
    else if (indexPath.section == SECTION_APPEARANCE)
    {
        ChangeIconViewController *changeIconVC = [ChangeIconViewController new];
        [self.navigationController pushViewController:changeIconVC animated:YES];
    }
    else if (indexPath.section == SECTION_LIST_SETTINGS)
    {
        switch (indexPath.row)
        {
            case 0:
                [self openEditTags];
                break;
            case 4:
                [self openAdvancedSettings];
                break;
            default:
                break;
        }
    }
    else if (indexPath.section == SECTION_REACH_OUT)
    {
        switch (indexPath.row)
        {
            case 0:
                [self sendEmail];
                break;
            case 1:
                [self openSpendStackTwitter];
                break;
            case 2:
                [self openReddit];
                break;
            case 3:
                [self sendTranslationSuggestion];
                break;
            default:
                break;
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (indexPath.section == SECTION_COLOPHON)
    {
        switch (indexPath.row)
        {
            case 0:
                [self showAboutController];
                break;
            case 1:
                [self deepLinkToReview];
                break;
            case 2:
                [self showPrivacyPolicyController];
                break;
            case 3:
                [self showOpenSourceController];
                break;
            default:
                break;
        }
    }
}

#pragma mark - 1st Section Actions

- (void)openEditTags
{
    SSTagsViewController *tagsVC = [[SSTagsViewController alloc] initWithSelectedTag:nil delegate:self scenario:SSTagsScenarioManageTags];
    [self.navigationController pushViewController:tagsVC animated:YES];
}

- (void)openAdvancedSettings
{
    SSAdvancedListOptionsViewController *advancedVC = [[SSAdvancedListOptionsViewController alloc] initWithList:nil scope:OptionScopeApp];
    [self.navigationController pushViewController:advancedVC animated:YES];
}

#pragma mark - 2nd Section Actions

- (void)sendEmail
{
    [self.emailer sendSupportEmail];
}

- (void)openSpendStackTwitter
{
    [TwitterLinkOpener openSpendStackTwitter];
}

- (void)openReddit
{
    [RedditLinkOpener openSpendStackReddit];
}

- (void)sendTranslationSuggestion
{
    [self.emailer sendTranslationSuggestion];
}

#pragma mark - 3rd Section Actions

- (void)showAboutController
{
    [self.navigationController pushViewController:[SSAboutViewController new] animated:YES];
}

- (void)deepLinkToReview
{
    NSString *spendStackAppStoreID = @"1329068268";
    NSURL *reviewURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@?action=write-review", spendStackAppStoreID]];
    [[UIApplication sharedApplication] openURL:reviewURL options:@{} completionHandler:nil];
}

#pragma mark - 4th Section Actions

- (void)showPrivacyPolicyController
{
    [self.navigationController pushViewController:[SSPrivacyViewController new] animated:YES];
}

- (void)showOpenSourceController
{
    [self.navigationController pushViewController:[SSLicensesViewController new] animated:YES];
}

#pragma mark - Tags Controller Delegate

- (void)onTagSelectionChanged:(SSTagSelectionViewModel *)tag controller:(SSTagsViewController *)controller
{
    // do.Nothing();
}

- (BOOL)shouldMakeTagLabelFirstResponderOnSelection
{
    return YES;
}

- (BOOL)controllerShouldPushTagsManagerWhenPresenting
{
    return YES;
}

@end
