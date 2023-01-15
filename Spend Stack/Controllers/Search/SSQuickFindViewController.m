//
//  SSQuickFindViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/2/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSNavigationController.h"
#import "SSQuickFindViewController.h"
#import "SSEmptyStateView.h"
#import "SSQuickFindResult.h"
#import "SSQuickFindTableViewCell.h"
#import "UIView+SSEmptyView.h"
#import "UITraitCollection+Utils.h"
#import "UISearchBar+Utils.h"
#import "SSConstants.h"

@interface SSQuickFindViewController () <UITableViewDataSource,
                                         UITableViewDelegate,
                                         SSEmptyDataViewDataSource>

@property (strong, nonatomic, nonnull) UITableView *tableView;
@property (strong, nonatomic, nonnull) NSArray <SSQuickFindResult *> *searchResults;
@property (nonatomic) SSQuickFindResult *tappedSearchResult;

@end

@implementation SSQuickFindViewController

#pragma mark - Initializers

- (instancetype)initWithDelegate:(id<SSQuickFindViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Search Spend Stack";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissController)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.emptyDataViewDataSourceDelegate = self;
    self.tableView.dragInteractionEnabled = YES;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.tableView.emptyDataViewDataSourceDelegate = self;
    
    [self.tableView registerClass:[SSQuickFindTableViewCell class]
           forCellReuseIdentifier:SS_QUICK_FIND_CELL_ID];
    
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.searchController.searchBar becomeFirstResponder];
}

#pragma mark - Tableview Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SSQuickFindTableViewCell *cell = (SSQuickFindTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SS_QUICK_FIND_CELL_ID];
    [cell setData:self.searchResults[indexPath.row]];
    
    return cell;
}

#pragma mark - Tableview Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.tappedSearchResult = self.searchResults[indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate ss_searchTermWasTapped:self.tappedSearchResult];
        self.searchController.searchBar.text = nil;
    }];
}

#pragma mark - Empty State

- (UIView *)viewForEmptyData
{
    return [[SSEmptyStateView alloc] initWithStateText:@"Search for any list, item, tag or note."];
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsBlockForEmptyView
{
    return ^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(-100);
    };
}

#pragma mark - Search Delegates

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    
    if (searchText == nil || searchText.length <= 1)
    {
        self.searchResults = @[];
        [self.tableView reloadData];
        return;
    }
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *searchText = searchController.searchBar.text;
        NSDictionary *searchParms = @{@"search": [NSString stringWithFormat:@"%%%@%%", searchText]};
        FMResultSet *rest = [db executeQuery:sql_performQuickSearch withParameterDictionary:searchParms];
        
        NSArray <SSQuickFindResult *> *newResults = [SSQuickFindResult resultsFromQuery:rest];
        
        IGListIndexPathResult *diffedIndices = IGListDiffPaths(0, 0, self.searchResults, newResults, IGListDiffEquality);
        
        if (diffedIndices.hasChanges)
        {
            if (newResults.count <= 0)
            {
                [self.tableView performBatchUpdates:^ {
                    NSMutableArray <NSIndexPath *> *deletedIDPs = [NSMutableArray new];
                    for (NSInteger idx = 0; idx < self.searchResults.count; idx++)
                    {
                        [deletedIDPs addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                    }
                    
                    self.searchResults = @[];
                    [self.tableView deleteRowsAtIndexPaths:deletedIDPs
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                } completion:nil];
            }
            else
            {
                [self.tableView performBatchUpdates:^ {
                    self.searchResults = newResults;
                    [self.tableView deleteRowsAtIndexPaths:diffedIndices.deletes
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView insertRowsAtIndexPaths:diffedIndices.inserts
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    for (IGListMoveIndexPath *move in diffedIndices.moves)
                    {
                        [self.tableView moveRowAtIndexPath:move.from
                                               toIndexPath:move.to];
                    }
                } completion:^ (BOOL done) {
                    for (NSIndexPath *update in diffedIndices.updates)
                    {
                        if (update.row < self.searchResults.count)
                        {
                            [self.tableView reloadRowsAtIndexPaths:@[update] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    }
                }];
            }
        }
        else
        {
            self.searchResults = newResults;
            [self.tableView reloadData];
        }
    }];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    if (self.tappedSearchResult == nil)
    {
        return;
    }
    // HACK!!!: For whatever reason, tapping a list on iPhone locks up unless
    // You wait for the search controller to completely go away.
    if (self.tappedSearchResult.type == SSQuickFindResultList &&
        [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.delegate ss_searchTermWasTapped:self.tappedSearchResult];
        });
    }
    else
    {
        [self.delegate ss_searchTermWasTapped:self.tappedSearchResult];
    }
}

@end
