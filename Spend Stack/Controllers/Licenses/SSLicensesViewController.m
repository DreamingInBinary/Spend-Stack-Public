//
//  SSLicensesViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/25/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSLicensesViewController.h"
#import "SSLabelTableViewCell.h"
#import "SSListSectionHeaderView.h"
#import "SSViewLicenseViewController.h"

@interface SSLicensesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic, nonnull) UITableView *tv;

@end

@implementation SSLicensesViewController

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.title = ss_Localized(@"openSource.vc.title");
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissController)];
        self.navigationItem.rightBarButtonItem = done;
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        
        self.tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.tv.delegate = self;
        self.tv.dataSource = self;
        self.tv.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
        self.tv.backgroundColor = [UIColor systemBackgroundColor];
        [self.tv registerClass:[SSLabelTableViewCell class] forCellReuseIdentifier:LABEL_CELL_ID];
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
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self deselectTableRow:self.tv];
}

- (NSArray <UIKeyCommand *> *)keyCommands
{
    return @[[self dismissOrPopControllerKeyCommand]];
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SSLabelTableViewCell *cell = (SSLabelTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LABEL_CELL_ID];
    
    switch (indexPath.row)
    {
        case 0:
        {
            cell.topLabel.text = @"Masonry";
            cell.bottomLabel.text = ss_Localized(@"openSource.vc.masonry");
            break;
        }
        case 1:
        {
            cell.topLabel.text = @"IGListKit - Diffing";
            cell.bottomLabel.text = ss_Localized(@"openSource.vc.ig");
            break;
        }
        case 2:
        {
            cell.topLabel.text = @"FMDB";
            cell.bottomLabel.text = ss_Localized(@"openSource.vc.fmdb");
            break;
        }
        default:
            break;
    }
    
    cell.showDivider = YES;
    cell.showDisclosureIndicator = YES;
    return cell;
}

#pragma mark - TableView Delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = ss_Localized(@"openSrouce.vc.header");
    
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
    switch (indexPath.row)
    {
        case 0:
            [self.navigationController pushViewController:[[SSViewLicenseViewController alloc] initWithLicense:LicenseMasonry] animated:YES];
            break;
        case 1:
            [self.navigationController pushViewController:[[SSViewLicenseViewController alloc] initWithLicense:LicenseIGListKit] animated:YES];
            break;
        case 2:
            [self.navigationController pushViewController:[[SSViewLicenseViewController alloc] initWithLicense:LicenseFMDB] animated:YES];
            break;
        default:
            break;
    }
}

#pragma mark - Utils

- (NSString *)defaultAcknowledgementsPlistPath
{
    NSString *targetName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    NSString *expectedPlistName = [NSString stringWithFormat:@"Pods-%@-acknowledgements", targetName];
    NSString *expectedPlistPath = [self acknowledgementsPlistPathForName:expectedPlistName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:expectedPlistPath])
    {
        return expectedPlistPath;
    }
    
    return @"";
}

- (NSString *)acknowledgementsPlistPathForName:(NSString *)name
{
    return [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
}

@end
