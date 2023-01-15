//
//  SSEditListNameViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/19/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSEditNameViewController.h"
#import "Spend_Stack_2-Swift.h"

@interface SSEditNameViewController ()

@property (strong, nonatomic, nonnull) SSTextField *nameTextField;
@property (weak, nonatomic, nullable) SSList *listToRename;
@property (weak, nonatomic, nullable) SSListItem *listItemToRename;
@property (strong, nonatomic, nonnull) DataStore *swiftDataStore;

@end

@implementation SSEditNameViewController

#pragma argument mark - Initializer

- (instancetype)initWithList:(SSList *)list
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.listToRename = list;
    }
    
    return self;
}

- (instancetype)initWithListItem:(SSListItem *)listItem
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        self.listItemToRename = listItem;
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithList:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithList:nil];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.swiftDataStore = [DataStore new];
    
    self.nameTextField = [[SSTextField alloc] initWithTextStyle:UIFontTextStyleTitle1];
    self.nameTextField.textColor = [UIColor ssTextPlaceholderColor];
    self.nameTextField.placeholder = ss_Localized(@"createList.vc.untitled");
    self.nameTextField.clearButtonMode = UITextFieldViewModeAlways;
    self.nameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    [self.nameTextField configureFontWeight:UIFontWeightBold];
    [self.view addSubview:self.nameTextField];
    
    if (self.listToRename)
    {
        self.nameTextField.text = self.listToRename.name;
        self.title = ss_Localized(@"listName.vc.title");
        self.nameTextField.placeholder = ss_Localized(@"createList.vc.untitled");
    }
    
    if (self.listItemToRename)
    {
        self.nameTextField.text = self.listItemToRename.title;
        self.title = ss_Localized(@"listName.vc.titleItem");
        self.nameTextField.placeholder = ss_Localized(@"quickAdd.defaultItem");
    }
    
    [self.nameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(SSRightBigElementMargin);
        make.centerY.equalTo(self.view.mas_centerY);
    }];
    
    SSToolbar *toolBar = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeFlexSpace, SSToolBarItemTypeDone]];
    __weak typeof(self)weakSelf = self;
    toolBar.onDone = ^{
        [weakSelf commitEdits];
    };
    toolBar.clipsToBounds = NO;
    
    self.nameTextField.inputAccessoryView = toolBar;
    
    if (self.navigationController.viewControllers.count > 1)
    {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
    else
    {
        [SSCitizenship setViewAsTransparentIfPossible:self.view];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissOrPopControllerKeyAction)];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(commitEdits)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.nameTextField becomeFirstResponder];
}

#pragma mark - List & List Item Rename

- (void)commitEdits
{
    if (self.listToRename) [self commitListRename];
    if (self.listItemToRename) [self commitListItemRename];
}

- (void)commitListRename
{
    NSString *newName = self.nameTextField.text.length > 0 ? self.nameTextField.text : self.nameTextField.placeholder;
    self.listToRename.name = newName;
    [self.swiftDataStore updateWithList:self.listToRename completion:nil];
    
    if (self.onItemRenamed)
    {
        self.onItemRenamed(newName);
    }
    
    [self dismissOrPopControllerKeyAction];
}

- (void)commitListItemRename
{
    NSString *newTitle = self.nameTextField.text.length > 0 ? self.nameTextField.text : self.nameTextField.placeholder;
    self.listItemToRename.title = newTitle;
    
    if (self.onItemRenamed)
    {
        self.onItemRenamed(newTitle);
    }
    
    [self dismissOrPopControllerKeyAction];
}

@end
