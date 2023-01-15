//
//  SSTagsViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/3/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTagsViewController.h"
#import "SSTagSelectionViewModel.h"
#import "SSTagsManagerViewController.h"
#import "SSListItemTagTableViewCell.h"
#import "SSEmptyStateView.h"
#import "SSExplainerViewController.h"
#import "UIView+Animations.h"
#import "UIView+SSEmptyView.h"
#import "Spend_Stack_2-Swift.h"

@interface SSTagsViewController () <UITableViewDataSource,
                                    UITableViewDelegate,
                                    SSEmptyDataViewDataSource,
                                    SSTagsManagerViewControllerDelegate>

@property (weak, nonatomic, nullable) id <SSTagsViewControllerDelegate> delegate;
@property (nonatomic) SSTagsScenario scenario;
@property (strong, nonatomic, nonnull) UITableView *tableView;
@property (strong, nonatomic, nonnull) SSToolbar *controllerTB;
@property (strong, nonatomic, nonnull) SSLabel *topLabel;
@property (strong, nonatomic, nonnull) NSArray <SSTagSelectionViewModel *> *tags;

@end

@implementation SSTagsViewController

#pragma mark - Initializer

- (instancetype)initWithSelectedTag:(SSTagSelectionViewModel * _Nullable)selectedTag delegate:(id<SSTagsViewControllerDelegate> _Nullable)delegate scenario:(SSTagsScenario)scenario
{
    self = [super init];
    
    if (self)
    {
        self.delegate = delegate;
        self.scenario = scenario;
        self.tags = [self fetchTags];
        
        NSAssert(delegate != nil, @"Spend Stack - The tag controller delegate was nil.");
        
        self.title = ss_Localized(@"ex.util.tag");
        
        self.topLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.topLabel.textColor = [UIColor ssSectionHeaderColor];
        [self.topLabel configureFontWeight:UIFontWeightMedium];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        self.tableView.tableFooterView = [UIView new];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.allowsMultipleSelection = NO;
        self.tableView.backgroundColor = [UIColor systemBackgroundColor];
        self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
        self.tableView.emptyDataViewDataSourceDelegate = self;
        [self.tableView registerClass:[SSListItemTagTableViewCell class]
               forCellReuseIdentifier:SS_ITEM_TAG_CELL_ID];
        
        if (selectedTag)
        {
            NSInteger idxOfSelectedTag = [self.tags indexOfObject:selectedTag];
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:idxOfSelectedTag inSection:0];
            
            [self showSelectedTagDetails:self.tags[idxOfSelectedTag]];
            
            // Hack - let the datasource load up first otherwise the cell is nil.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView selectRowAtIndexPath:selectedIndexPath
                                            animated:YES
                                      scrollPosition:UITableViewScrollPositionNone];
            });
        }
        else
        {
            [self setDeselectedTagDetails];
        }
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Nav bar
    [self setupNavigationBar];
    
    __weak SSTagsViewController *weakSelf = self;
    self.onPreferredContentSizeChanged = ^{
        [weakSelf.tableView reloadData];
    };
    
    NSArray <SSToolBarItem *> *items = @[SSToolBarItemTypeFlexSpace, SSToolBarItemTypeBasicAdd];
    if (self.scenario == SSTagsScenarioManageTags)
    {
        items = @[SSToolBarItemTypeGenericNoBorder, SSToolBarItemTypeFlexSpace, SSToolBarItemTypeBasicAdd];
    }
    
    self.controllerTB = [[SSToolbar alloc] initWithItemTypes:@[]];
    self.controllerTB.genericNoBorderButtonTitle = ss_Localized(@"general.help");
    [self.controllerTB setToolBarItems:items];
    self.controllerTB.onBasicAdd = ^{
        SSTagsManagerViewController *tagsManagerVC = [[SSTagsManagerViewController alloc] initWithTag:nil delegate:weakSelf];
        BOOL pushTagsManager = [weakSelf isOniPad];
        if ([weakSelf.delegate respondsToSelector:@selector(controllerShouldPushTagsManagerWhenPresenting)])
        {
            if ([weakSelf.delegate controllerShouldPushTagsManagerWhenPresenting])
            {
                pushTagsManager = YES;
            }
        }
        
        if (pushTagsManager)
        {
            [weakSelf.navigationController pushViewController:tagsManagerVC animated:YES];
        }
        else
        {
            SSModalCardNavigationController *modalPresentation = [[SSModalCardNavigationController alloc] initWithRootViewController:tagsManagerVC];
            [weakSelf presentViewController:modalPresentation animated:YES completion:nil];
        }
    };
    self.controllerTB.onGenericNoBorderAction = ^{
        SSExplainerViewController *explainerVC = [[SSExplainerViewController alloc] initWithExplainedFeature:ExplainFeatureTags];
        [weakSelf.navigationController pushViewController:explainerVC animated:YES];
    };
    
    [self.view addSubviews:@[self.tableView, self.topLabel, self.controllerTB]];
    
    [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.equalTo(self.view);
        make.top.equalTo(self.topLabel.mas_bottom).with.offset(SSSpacingBigMargin);
        make.bottom.equalTo(self.controllerTB.mas_top).with.offset(SSBottomBigElementMargin);
    }];
    
    if (self.scenario == SSTagsScenarioManageTags)
    {
        self.topLabel.text = ss_Localized(@"tags.vc.header");
    }
    
    [self.controllerTB mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.centerX.equalTo(self.view.mas_centerX);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadChangedIndices:)
                                                 name:SS_NOTE_DATA_CHANGED
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self deselectTableRow:self.tableView];
}

#pragma mark - Diffing and Reloadable

- (void)loadChangedIndices:(NSNotification *)notification
{
    NSArray <SSTagSelectionViewModel *> *tags = [self fetchTags];
    [self performDiffAndAssignNewDataFromLists:tags];
}

- (void)performDiffAndAssignNewDataFromLists:(NSArray<__kindof SSObject *> *)freshData
{
    dispatch_sync(self.diffQueue, ^{
        NSArray <SSTagSelectionViewModel *> *oldTags = [self.tags copy];
        
        //Any changes?
        IGListIndexPathResult *diffedIndices = IGListDiffPaths(0, 0, oldTags, freshData, IGListDiffEquality);
        
        if (diffedIndices.hasChanges)
        {
            NSLog(@"Spend Stack - Changes picked up in view lists controller, diffing and reloading.");
            if (freshData.count <= 0)
            {
                [self.tableView performBatchUpdates:^ {
                    NSMutableArray <NSIndexPath *> *deletedIDPs = [NSMutableArray new];
                    for (NSInteger idx = 0; idx < self.tags.count; idx++)
                    {
                        [deletedIDPs addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                    }
                    
                    self.tags = [NSMutableArray new];
                    [self.tableView deleteRowsAtIndexPaths:deletedIDPs
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                } completion:nil];
            }
            else
            {
                [self.tableView performBatchUpdates:^ {
                    self.tags = [freshData mutableCopy];
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
                        if (update.row < self.tags.count)
                        {
                            [self.tableView reloadRowsAtIndexPaths:@[update] withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    }
                }];
            }
        }
    });
}

#pragma mark - Empty Data Delegate

- (UIView *)viewForEmptyData
{
    SSEmptyStateView *emptyView = [[SSEmptyStateView alloc] initWithStateText:ss_Localized(@"tags.vc.empty")];
    emptyView.backgroundColor = [UIColor systemBackgroundColor];
    return emptyView;
}

- (void (^ _Nonnull)(MASConstraintMaker *))constraintsBlockForEmptyView
{
    return ^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.and.right.equalTo(self.view);
        make.bottom.equalTo(self.controllerTB.mas_top);
    };
}

#pragma mark - Tags Manager Delegate

- (void)newTagWasCreated:(SSTag *)newTag
{
    SSTagSelectionViewModel *tagVM = [[SSTagSelectionViewModel alloc] initWithMasterTag:newTag];
    self.tags = [[NSArray arrayWithArray:self.tags] arrayByAddingObject:tagVM];
    NSIndexPath *newIDP = [NSIndexPath indexPathForItem:[self.tags indexOfObject:tagVM] inSection:0];
    
    [self.tableView performBatchUpdates:^{
        [self.tableView insertRowsAtIndexPaths:@[newIDP]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(BOOL finished) {
        [self.tableView selectRowAtIndexPath:newIDP
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionBottom];
        
        if (self.scenario == SSTagsScenarioAddingToItem)
        {
            [self tableView:self.tableView didSelectRowAtIndexPath:newIDP];
        }
    }];
}

- (void)tagWasEdited:(SSTag *)editedTag
{
    SSTagSelectionViewModel *newVM = [[SSTagSelectionViewModel alloc] initWithMasterTag:editedTag];
    SSTagSelectionViewModel *currentVM = [SSTagSelectionViewModel tagViewModelForMasterTag:editedTag viewModels:self.tags];
    
    NSInteger idxOfEditedTag = [self.tags indexOfObject:currentVM];
    
    NSMutableArray *tagsCopy = [self.tags mutableCopy];
    tagsCopy[idxOfEditedTag] = newVM;
    self.tags = [tagsCopy copy];
    
    NSIndexPath *idpOfEditedTag = [NSIndexPath indexPathForRow:idxOfEditedTag inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[idpOfEditedTag]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [[SwiftShims new] reloadWidgets];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_TAG_CRUD_FROM_TAG_MANAGER_CONTROLLER object:editedTag];
}

- (void)tagWasDeleted:(SSTag *)deletedTag
{
    SSTagSelectionViewModel *deletedVM = [SSTagSelectionViewModel tagViewModelForMasterTag:deletedTag viewModels:self.tags];
    NSInteger idxOfDeletedTag = [self.tags indexOfObject:deletedVM];
    NSIndexPath *idpOfEditedTag = [NSIndexPath indexPathForItem:idxOfDeletedTag inSection:0];
    NSMutableArray *tagsCopy = [self.tags mutableCopy];
    [tagsCopy removeObjectAtIndex:idxOfDeletedTag];
    
    [[SwiftShims new] reloadWidgets];
    
    [self.tableView performBatchUpdates:^{
        self.tags = tagsCopy.count > 0 ? [tagsCopy copy] : @[];
        [self.tableView deleteRowsAtIndexPaths:@[idpOfEditedTag]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(BOOL finished) {
        if (finished)
        {
            [self.undoManager registerUndoWithTarget:self
                                            selector:@selector(performUndoDeleteTag:)
                                              object:deletedTag];
            [self.undoManager setActionName:ss_Localized(@"tags.vc.undo")];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_TAG_CRUD_FROM_TAG_MANAGER_CONTROLLER object:deletedTag];
        }
    }];
}

#pragma mark - Undo/Redo

- (void)performRedoDeleteTag:(SSTag * _Nonnull)tagToRedelete
{
    [self tagWasDeleted:tagToRedelete];
    
    [self.readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        [SSTag saveListItemIDsUsingTagToBeDeleted:db tag:tagToRedelete];
        
        BOOL success = [db deleteTagInDB:tagToRedelete];
        NSLog(@"Spend Stack - Successfully redeleted tag: %@", @(success));
        
        [[SSDataStore sharedInstance].ckManager.privateDB saveObjects:@[]
                                                       withSavePolicy:0
                                                        deleteObjects:@[tagToRedelete]
                                                       withCompletion:^(NSError * error) {
            NSLog(@"Spend Stack - Deleted tag %@. Error:(%@)", tagToRedelete, error.localizedDescription);
        }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_TAG_CRUD_FROM_TAG_MANAGER_CONTROLLER object:tagToRedelete];
    }];
}

- (void)performUndoDeleteTag:(SSTag * _Nonnull)tagToRestore
{
    // Register Undo the Undo
    [self.undoManager registerUndoWithTarget:self
                                    selector:@selector(performRedoDeleteTag:)
                                      object:tagToRestore];
    [self.undoManager setActionName:ss_Localized(@"tags.vc.undo")];
    [self newTagWasCreated:tagToRestore];
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        [SSTag restoreTagAndReassociateListItemForeignKeysToTag:tagToRestore database:db];
    }];
}

#pragma mark - Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (self.scenario == SSTagsScenarioAddingToItem && [tableView.indexPathForSelectedRow isEqual:indexPath])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView.delegate tableView:self.tableView didDeselectRowAtIndexPath:indexPath];
        
        return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.scenario == SSTagsScenarioManageTags)
    {
        SSTag *tagToEdit = self.tags[indexPath.item].underlyingTag;
        SSTagsManagerViewController *tagsManagerVC = [[SSTagsManagerViewController alloc] initWithTag:tagToEdit delegate:self];
        [self.navigationController pushViewController:tagsManagerVC animated:YES];
    }
    else if (self.scenario == SSTagsScenarioAddingToItem)
    {
        [self showSelectedTagDetails:self.tags[indexPath.row]];
        [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if (self.delegate)
        {
            [self.delegate onTagSelectionChanged:self.tags[indexPath.row] controller:self];
            
            if ([self.delegate respondsToSelector:@selector(shouldMakeTagLabelFirstResponderOnSelection)])
            {
                BOOL shouldMakeTagNameLabelFirstResponder = [self.delegate shouldMakeTagLabelFirstResponderOnSelection];
                
                if (shouldMakeTagNameLabelFirstResponder)
                {
                    __weak typeof(self) weakSelf = self;
                    cell.contentView.onAnimationFinished = ^{
                        [weakSelf.topLabel becomeFirstResponder];
                    };
                }
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.indexPathForSelectedRow == nil)
    {
        [self setDeselectedTagDetails];
    }
    
    if (self.delegate)
    {
        [self.delegate onTagSelectionChanged:nil controller:self];
    }
}

#pragma mark - Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SSListItemTagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SS_ITEM_TAG_CELL_ID forIndexPath:indexPath];
    
    // Small hack so we don't have to pass confiurations down to the cell which was built for list item VC.
    if (self.scenario == SSTagsScenarioAddingToItem)
    {
        cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        cell.dividerView.backgroundColor = [UIColor ssMutedColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.useCheckmarkForSelection = YES;
    }
    
    [cell setDataForTag:self.tags[indexPath.row]];
    
    return cell;
}

#pragma mark - Textfield Delegate

- (void)textFieldDidChangeNotification:(NSNotification *)note
{
    SSTextField *changedTextField = note.object;
    
    if ([changedTextField isKindOfClass:[SSTextField class]] == NO) return;
    
    NSInteger selectedTagIDPIndex = self.tableView.indexPathForSelectedRow.row;
    SSTagSelectionViewModel *selectedTag = self.tags[selectedTagIDPIndex];
    selectedTag.underlyingTag.name = changedTextField.text;
}

- (void)textFieldDidEndNotification:(NSNotification *)note
{
    NSIndexPath *selectedTagIDP = self.tableView.indexPathForSelectedRow;
    if (selectedTagIDP == nil) return;
    [self.tableView reloadRowsAtIndexPaths:@[selectedTagIDP] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView selectRowAtIndexPath:selectedTagIDP
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - Adding Tag to Item

- (void)showSelectedTagDetails:(SSTagSelectionViewModel *)tag
{
    self.topLabel.enabled = YES;
    self.topLabel.text = tag.name;
}

- (void)setDeselectedTagDetails
{
    self.topLabel.enabled = NO;
    self.topLabel.text = ss_Localized(@"tags.vc.choose");
}

#pragma mark - Tag Fetch

- (NSArray <SSTagSelectionViewModel *> *)fetchTags
{
    NSArray <SSTagSelectionViewModel *> *tags = [SSTagSelectionViewModel tagViewModelArrayFromTags:[[SSDataStore sharedInstance] queryAllMasterTags]];
    
    if (self.scenario == SSTagsScenarioAddingToItem)
    {
        NSArray <SSListTag *> *sharedTags = [self.delegate tagsFromListShare];
        NSArray <SSTagSelectionViewModel *> *sharedTagsViewModels = [SSTagSelectionViewModel tagViewModelArrayFromTags:sharedTags];
        tags = [[NSArray arrayWithArray:tags] arrayByAddingObjectsFromArray:sharedTagsViewModels];
    }
    
    return tags;
}

#pragma mark - Misc

- (void)setupNavigationBar
{
    self.title = ss_Localized(@"ex.util.tag");
    
    if ([self.navigationController isKindOfClass:[SSNavigationController class]])
    {
        [((SSNavigationController *)self.navigationController) styleNavigationBarAsPlainWhiteWithBoldText];
    }
    
    if (self.navigationController.viewControllers.count > 1 &&
        self.scenario == SSTagsScenarioAddingToItem)
    {
        // Let them use the back button on an iPad
        return;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissControllerAndNotifyDelegate)];
}

- (void)dismissControllerAndNotifyDelegate
{
    if ([self.delegate respondsToSelector:@selector(tagsControllerWillDismiss:)])
    {
        SSTagSelectionViewModel *tagVM;
        NSIndexPath *selectedIDP = [self.tableView indexPathForSelectedRow];
        NSUInteger selectedRow = selectedIDP ? selectedIDP.row : NSIntegerMax;
        if (self.tags.count > selectedRow)
        {
            tagVM = self.tags[selectedRow];
        }
        
        [self.delegate tagsControllerWillDismiss:tagVM];
    }
    
    [self dismissController];
}

@end
