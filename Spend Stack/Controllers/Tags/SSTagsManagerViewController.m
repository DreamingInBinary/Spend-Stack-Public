//
//  SSTagManagerViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/1/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTagsManagerViewController.h"
#import "SSHeaderCollectionReusableView.h"
#import "UIView+Animations.h"
#import "UIView+SSUtils.h"

typedef NS_ENUM(NSUInteger, SSTagsManagerScenario) {
    SSTagsManagerScenarioCreate,
    SSTagsManagerScenarioEdit
};

static NSString * _Nonnull const CELL_ID = @"CellID";

@interface SSTagsManagerViewController () <UICollectionViewDataSource,
                                           UICollectionViewDelegate,
                                           UIPointerInteractionDelegate>

@property (weak, nonatomic, nullable) id <SSTagsManagerViewControllerDelegate> tagsManagerDelegate;
@property (strong, nonatomic, nullable) SSTag *tagToEdit;
@property (strong, nonatomic, nonnull) SSTextField *topTextField;
@property (strong, nonatomic, nonnull) NSString *selectedTagColorString;
@property (strong, nonatomic, nonnull) UIView *selectedColorTagCircle;
@property (strong, nonatomic, nonnull) UICollectionView *collectionView;
@property (strong, nonatomic, nonnull) SSToolbar *controllerTB;
@property (nonatomic) SSTagsManagerScenario scenario;
@property (strong, nonatomic, nonnull) NSArray <UIColor *> *colors;
@property (strong, nonatomic, readonly, nonnull) NSString *collectionViewHeaderText;

@end

@implementation SSTagsManagerViewController

#pragma mark - Computed Properties

- (NSString *)collectionViewHeaderText
{
    return ss_Localized(@"tags.vc.color");
}

#pragma mark - Initializer

- (instancetype)initWithTag:(SSTag *)tag delegate:(id<SSTagsManagerViewControllerDelegate>)tagsManagerDelegate
{
    self = [super init];
    
    if (self)
    {
        self.tagsManagerDelegate = tagsManagerDelegate;
        self.tagToEdit = tag;
        self.scenario = tag ? SSTagsManagerScenarioEdit : SSTagsManagerScenarioCreate;
        self.title = tag ? ss_Localized(@"tagsManager.vc.edit") : ss_Localized(@"tagsManager.vc.create");
        self.colors = [SSTag tagColors];
        
        self.topTextField = [[SSTextField alloc] initWithTextStyle:UIFontTextStyleBody];
        self.topTextField.placeholder = ss_Localized(@"tagsManager.vc.name");
        self.topTextField.text = tag ? tag.name : @"";
        self.topTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.topTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.selectedColorTagCircle = [UIView new];
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout new]];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.allowsMultipleSelection = NO;
        self.collectionView.backgroundColor = [UIColor systemBackgroundColor];
        [self.collectionView registerClass:[SSHeaderCollectionReusableView class]
                forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                       withReuseIdentifier:SS_HEADER_ID];
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:CELL_ID];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    if ([self.navigationController isKindOfClass:[SSNavigationController class]])
    {
        [((SSNavigationController *)self.navigationController) styleNavigationBarAsPlainWhiteWithBoldText];
    }
    
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    UIBarButtonItem *saveOrDoneBarButton;
    
    if (self.scenario == SSTagsManagerScenarioCreate)
    {
        self.selectedTagColorString = @"";
        saveOrDoneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    }
    else
    {
        self.selectedTagColorString = self.tagToEdit.color;
        self.selectedColorTagCircle.backgroundColor = [self.tagToEdit rawColor];
        self.selectedColorTagCircle.layer.cornerRadius = 10;
        saveOrDoneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(done:)];
    }
    
    self.navigationItem.leftBarButtonItem = cancelBarButton;
    self.navigationItem.rightBarButtonItem = saveOrDoneBarButton;
    
    __weak typeof(self) weakSelf = self;
    self.onPreferredContentSizeChanged = ^{
        [weakSelf.collectionView.collectionViewLayout invalidateLayout];
        [weakSelf.collectionView setCollectionViewLayout:[weakSelf ssFlowLayout]];
        [weakSelf.collectionView reloadData];
    };
    
    SSToolbar *tb = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeFlexSpace, SSToolBarItemTypeKeyboardDown]];
    tb.onKeyboardDown = ^{
        [weakSelf.topTextField resignFirstResponder];
    };
    tb.clipsToBounds = NO;
    self.topTextField.inputAccessoryView = tb;
    
    if (self.scenario == SSTagsManagerScenarioEdit)
    {
        self.controllerTB = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeDelete, SSToolBarItemTypeFlexSpace]];
        self.controllerTB.onDelete = ^{
            [weakSelf deleteEditingTag];
        };
        
        [self.view addSubviews:@[self.collectionView, self.selectedColorTagCircle, self.topTextField, self.controllerTB]];
    }
    else
    {
        [self.view addSubviews:@[self.collectionView, self.selectedColorTagCircle, self.topTextField]];
    }
    
    [self.selectedColorTagCircle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.topTextField.mas_centerY);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(SSLeftBigElementMargin);
        
        if (weakSelf.scenario == SSTagsManagerScenarioEdit)
        {
            make.width.and.height.equalTo(@20);
        }
        else
        {
            make.width.and.height.equalTo(@0);
        }
    }];
    
    [self.topTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(SSTopBigElementMargin);
        make.right.equalTo(self.view.mas_rightMargin);
        
        if (weakSelf.scenario == SSTagsManagerScenarioEdit)
        {
            make.left.equalTo(self.selectedColorTagCircle.mas_right).with.offset(SSLeftElementMargin);
        }
        else
        {
            make.left.equalTo(self.selectedColorTagCircle.mas_right);
        }
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.top.equalTo(self.topTextField.mas_bottom).with.offset(SSSpacingBigMargin);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
    }];
    
    if (self.controllerTB)
    {
        [self.controllerTB mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.view.mas_width);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.centerX.equalTo(self.view.mas_centerX);
        }];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadChangedIndices:)
                                                 name:SS_NOTE_DATA_CHANGED
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView setCollectionViewLayout:[self ssFlowLayout]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.scenario == SSTagsManagerScenarioCreate)
    {
        [self.topTextField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.tagToEdit = nil;
}

#pragma mark - Diffing and Reloadable

- (void)loadChangedIndices:(NSNotification *)notification
{
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:sql_TagSelectByTagID,self.tagToEdit.dbID];
        SSTag *freshTag;
        
        while([result next])
        {
            freshTag = [[SSTag alloc] initWithResultSet:result];
        }
        
        if (freshTag == nil)
        {
            UIAlertAction *actionRestore = [UIAlertAction actionWithTitle:ss_Localized(@"tagsManager.vc.restore") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self restoreTag];
            }];
            
            UIAlertAction *actionLeaveDeleted = [UIAlertAction actionWithTitle:ss_Localized(@"tagsManager.vc.leave") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
            
            [self showAlertControllerWithTitle:ss_Localized(@"tagsManager.vc.deleted")
                                       message:ss_Localized(@"tagsManager.vc.choice")
                                       actions:@[actionRestore, actionLeaveDeleted]];
        }
        else
        {
            [self performDiffAndAssignNewDataFromLists:@[freshTag]];
        }
    }];
}

- (void)performDiffAndAssignNewDataFromLists:(NSArray<__kindof SSObject *> *)freshData
{
    dispatch_sync(self.diffQueue, ^{
        SSTag *newTagData = freshData.firstObject;
        
        if ([newTagData isEqualToDiffableObject:self.tagToEdit] == NO)
        {
            [self updateTagEditingViewConstraintsIfNeeded:[self.selectedColorTagCircle.backgroundColor isEqual:[newTagData rawColor]] == NO];
            self.selectedColorTagCircle.backgroundColor = [newTagData rawColor];
            self.topTextField.text = newTagData.name;
            self.tagToEdit = newTagData;
        }
    });
}

- (void)restoreTag {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            [SSTag restoreTagAndReassociateListItemForeignKeysToTag:self.tagToEdit database:db];
        }];
    });
}

#pragma mark - Datasource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        SSHeaderCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                    withReuseIdentifier:SS_HEADER_ID
                                                                                           forIndexPath:indexPath];
        header.label.text = self.collectionViewHeaderText;
        
        return header;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.colors.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_ID forIndexPath:indexPath];
    cell.backgroundColor = self.colors[indexPath.item];
    cell.layer.cornerRadius = SSSpacingMargin;
    cell.layer.masksToBounds = YES;
    [cell addPointerInteractionWithDelegate:self];
    
    
    return cell;
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:interaction.view];
    
    UIPointerLiftEffect *hover = [UIPointerLiftEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

#pragma mark - Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
    
    self.selectedColorTagCircle.backgroundColor = self.colors[indexPath.item];
    self.selectedTagColorString = [SSTag tagColorStrings][indexPath.item];
    BOOL tagColorViewIsShowing = self.selectedColorTagCircle.boundsHeight > 0.0f;
    
    [self updateTagEditingViewConstraintsIfNeeded:tagColorViewIsShowing];
}

- (void)updateTagEditingViewConstraintsIfNeeded:(BOOL)tagColorViewIsShowing {
    if (tagColorViewIsShowing)
    {
        [self.selectedColorTagCircle bobble];
    }
    else
    {
        // Here, we're animating it in from being hidden
        [self.selectedColorTagCircle mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@20);
        }];
        
        [self.topTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.selectedColorTagCircle.mas_right).with.offset(SSLeftElementMargin);
        }];
        
        [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f usingSpringWithDamping:0.8f initialSpringVelocity:0.8f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.view layoutIfNeeded];
            self.selectedColorTagCircle.layer.cornerRadius = 10;
        } completion:nil];
    }
}

#pragma mark - Collection View Flow Layout

- (UICollectionViewFlowLayout *)ssFlowLayout
{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    
    NSInteger desiredItemsPerRow = 6;
    NSInteger leftRightCollectionViewMargins = (SSSpacingBigMargin * 2);
    NSInteger spacingPerItemsInRow = (SSSpacingMargin * 1);
    
    CGFloat size = floorf((self.view.boundsWidth - leftRightCollectionViewMargins)/desiredItemsPerRow) - spacingPerItemsInRow;
    CGSize itemSize = CGSizeMake(size, size);
    if ([SSCitizenship accessibilityFontsEnabled]) itemSize = CGSizeMake(UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, SSSpacingBigMargin, 0, SSSpacingBigMargin)).size.width, size);
    layout.itemSize = itemSize;
    layout.minimumInteritemSpacing = SSSpacingMargin;
    layout.minimumLineSpacing = SSSpacingBigMargin;
    layout.sectionInset = UIEdgeInsetsMake(SSSpacingMargin, SSSpacingBigMargin, SSSpacingMargin, SSSpacingBigMargin);
    layout.headerReferenceSize = [SSHeaderCollectionReusableView estimatedSizeHeaderInView:self.collectionView
                                                                                  withText:self.collectionViewHeaderText];
    return layout;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView setCollectionViewLayout:[self ssFlowLayout] animated:YES];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - Tab and Bar Button Actions

- (void)deleteEditingTag
{
    UIAlertAction *delete = [UIAlertAction actionWithTitle:ss_Localized(@"general.delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
            [SSTag saveListItemIDsUsingTagToBeDeleted:db tag:self.tagToEdit];
            
            // If it's shared, the reference with .deleteSelf will be outside of their database so manually delete them.
            NSArray <SSListTag *> *sharedListTags = [SSTag tagsByCloudDB:self.tagToEdit
                                                       localDBConnection:db][SS_TAGS_IN_SHARED_DB];
            
            BOOL success = [db deleteTagInDB:self.tagToEdit];
            NSLog(@"Spend Stack - Successfully deleted tag in database: (%@)", @(success));
            
            [self resignFirstResponderOfTextFieldIfNeeded];
            
            // Locally, listTags are nuked via a trigger and on the server via .deleteSelf references.
            [[SSDataStore sharedInstance].ckManager.privateDB saveObjects:@[]
                                                           withSavePolicy:0
                                                            deleteObjects:@[self.tagToEdit]
                                                           withCompletion:^(NSError * error) {
                NSLog(@"Spend Stack - Deleted tag %@. Error:(%@)", self.tagToEdit, error.localizedDescription);
            }];
            
            if (sharedListTags.count > 0)
            {
                [[SSDataStore sharedInstance].ckManager.sharedDB saveObjects:@[]
                                                              withSavePolicy:0
                                                               deleteObjects:sharedListTags
                                                              withCompletion:^(NSError * error) {
                                                                  NSLog(@"Spend Stack - Deleted shared list tags. Error:(%@)", error.localizedDescription);
                                                              }];
            }
            
            if ([self.tagsManagerDelegate respondsToSelector:@selector(tagWasDeleted:)])
            {
                [self.navigationController popViewControllerAnimated:YES];
                [self.tagsManagerDelegate tagWasDeleted:self.tagToEdit];
            }
            else
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
        
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:nil];
    
    [self showAlertControllerWithTitle:ss_Localized(@"tags.vc.undo") message:ss_Localized(@"tagsManager.vc.confirmDelete") actions:@[delete, cancel]];
}

- (void)cancel:(UIBarButtonItem *)sender
{
    [self resignFirstResponderOfTextFieldIfNeeded];
    
    if (self.navigationController.viewControllers.count > 1)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self dismissAndNotifyDelegate:nil];
    }
}

- (void)done:(UIBarButtonItem *)sender
{
    // Apply edits
    self.tagToEdit.name = self.topTextField.text;
    self.tagToEdit.color = self.selectedTagColorString;
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase *db) {
        BOOL success = [db updateTagInDB:self.tagToEdit];
        NSLog(@"Spend Stack - Successfully updated tag in database: (%@)", @(success));
        
        [self resignFirstResponderOfTextFieldIfNeeded];
        
        iCloudTagsDictionary *tagsByDB = [SSTag tagsByCloudDB:self.tagToEdit
                                            localDBConnection:db];
        
        [[SSDataStore sharedInstance].ckManager.privateDB saveObjects:tagsByDB[SS_TAGS_IN_MY_DB]
                                                       withSavePolicy:CKRecordSaveChangedKeys
                                                        deleteObjects:@[]
                                                       withCompletion:^(NSError * error) {
            NSLog(@"Spend Stack - Updated tag %@ and list tags. Error:(%@)", self.tagToEdit, error.localizedDescription);
        }];
        
        if (tagsByDB[SS_TAGS_IN_SHARED_DB].count > 0)
        {
            [[SSDataStore sharedInstance].ckManager.sharedDB saveObjects:tagsByDB[SS_TAGS_IN_SHARED_DB]
                                                           withSavePolicy:CKRecordSaveChangedKeys
                                                            deleteObjects:@[]
                                                           withCompletion:^(NSError * error) {
                                                               NSLog(@"Spend Stack - Updated shared list tags. Error:(%@)", error.localizedDescription);
                                                           }];
        }
        
        if ([self.tagsManagerDelegate respondsToSelector:@selector(tagWasEdited:)])
        {
            [self.navigationController popViewControllerAnimated:YES];
            [self.tagsManagerDelegate tagWasEdited:self.tagToEdit];
        }
        else
        {
            if (self.navigationController.viewControllers.count == 1)
            {
                [self dismissAndNotifyDelegate:nil];
            }
            else
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }];
}

- (void)save:(UIBarButtonItem *)sender
{
    NSString *tagColorName = [self.selectedTagColorString isEqualToString:@""] ? AppleRed : self.selectedTagColorString;
    NSString *tagName = [self.topTextField.text isEqualToString:@""] ? ss_Localized(@"tagsManager.vc.newTag") : self.topTextField.text;
    
    [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSUInteger currentHighestOrderingIndex = [db mostRecentOrderingIndexForTags];
        SSTag *newTag = [[SSTag alloc] initWithColor:tagColorName
                                                name:tagName
                                               order:@(currentHighestOrderingIndex)];
        BOOL success = [db insertTagIntoDB:newTag];
        NSLog(@"Spend Stack - Inserted new tag into database:%@.", @(success));
        
        [[SSDataStore sharedInstance].ckManager.privateDB saveObjects:@[newTag]
                                                       withSavePolicy:CKRecordSaveIfServerRecordUnchanged
                                                        deleteObjects:@[]
                                                       withCompletion:^(NSError * error) {
            NSLog(@"Spend Stack - Saved new tag %@. Error:(%@)", tagName, error.localizedDescription);
        }];
        
        [self resignFirstResponderOfTextFieldIfNeeded];
        
        if ([self.tagsManagerDelegate respondsToSelector:@selector(newTagWasCreated:)])
        {
            if (self.navigationController.viewControllers.count > 1)
            {
                [self.tagsManagerDelegate newTagWasCreated:newTag];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                [self dismissAndNotifyDelegate:newTag];
            }
        }
        else
        {
            [self dismissAndNotifyDelegate:nil];
        }
    }];
}

- (void)resignFirstResponderOfTextFieldIfNeeded
{
    if (self.topTextField.isFirstResponder)
    {
        [self.topTextField resignFirstResponder];
    }
}

- (void)dismissAndNotifyDelegate:(SSTag *)newTag
{
    if ([self.tagsManagerDelegate respondsToSelector:@selector(tagEditorWillDismiss)])
    {
        [self.topTextField resignFirstResponder];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:^{
                [self.tagsManagerDelegate tagEditorWillDismiss];
                if (newTag) [self.tagsManagerDelegate newTagWasCreated:newTag];
            }];
        });
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            if (newTag) [self.tagsManagerDelegate newTagWasCreated:newTag];
        }];
    }
}

@end
