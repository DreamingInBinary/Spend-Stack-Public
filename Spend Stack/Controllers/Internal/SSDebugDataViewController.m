//
//  SSDebugDataViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/29/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSDebugDataViewController.h"

static NSString * _Nonnull const SS_CELL_DEBUG_ID = @"SSDebugCell";

@interface SSDebugDataViewController ()

@property (strong, nonatomic, nullable) __kindof SSObject *parentObj;
@property (nonatomic) SSDebugData displayCase;
@property (strong, nonatomic, nonnull) NSArray <id> *data;

@end

@implementation SSDebugDataViewController

#pragma mark - Initializer

- (instancetype)initWithDebugDataCase:(SSDebugData)displayCase parentItem:(__kindof SSObject *)parentObj
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self)
    {
        self.displayCase = displayCase;
        self.parentObj = parentObj;
        
        if (self.displayCase == SSDebugDataShowLists)
        {
            self.data = [[SSDataStore sharedInstance] queryAllLists];
        }
        else if (self.displayCase == SSDebugDataShowListItems)
        {
            [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
                FMResultSet *result = [db executeQuery:sql_ListItemSelectByListID, parentObj.dbID];
                
                NSMutableArray <SSListItem *> *listItems = [NSMutableArray new];
                while ([result next])
                {
                    [listItems addObject:[[SSListItem alloc] initWithResultSet:result]];
                }
                
                self.data = [[NSArray alloc] initWithArray:listItems];
                
                [self.tableView reloadData];
            }];
        }
        else if (self.displayCase == SSDebugDataShowAllListItems)
        {
            [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
                FMResultSet *result = [db executeQuery:sql_ListItemSelectAll];
                
                NSMutableArray <SSListItem *> *listItems = [NSMutableArray new];
                while ([result next])
                {
                    [listItems addObject:[[SSListItem alloc] initWithResultSet:result]];
                }
                
                self.data = [[NSArray alloc] initWithArray:listItems];
                [self.tableView reloadData];
            }];
        }
        else if (self.displayCase == SSDebugDataShowTags)
        {
            [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
                FMResultSet *result = [db executeQuery:sql_TagSelectAll];
                
                NSMutableArray <SSTag *> *tags = [NSMutableArray new];
                while ([result next])
                {
                    [tags addObject:[[SSTag alloc] initWithResultSet:result]];
                }
                
                self.data = [[NSArray alloc] initWithArray:tags];
                [self.tableView reloadData];
            }];
        }
        else if (self.displayCase == SSDebugDataShowListTags)
        {
            [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
                FMResultSet *result = [db executeQuery:sql_ListTagSelectByListID, parentObj.dbID];
                
                NSMutableArray <SSListTag *> *listTags = [NSMutableArray new];
                while ([result next])
                {
                    [listTags addObject:[[SSListTag alloc] initWithResultSet:result]];
                }
                
                self.data = [[NSArray alloc] initWithArray:listTags];
                [self.tableView reloadData];
            }];
        }
        else if (self.displayCase == SSDebugDataShowAllListTags)
        {
            [[SSDataStore sharedInstance].readWriteQueue inDatabase:^(FMDatabase * _Nonnull db) {
                FMResultSet *result = [db executeQuery:sql_ListTagSelectAll];
                
                NSMutableArray <SSListTag *> *listTags = [NSMutableArray new];
                while ([result next])
                {
                    [listTags addObject:[[SSListTag alloc] initWithResultSet:result]];
                }
                
                self.data = [[NSArray alloc] initWithArray:listTags];
                [self.tableView reloadData];
            }];
        }
        else if (self.displayCase == SSDebugDataShowOptions)
        {
            self.data = @[@"Show all lists",
                          @"Show all list items",
                          @"Show all master tags",
                          @"Show all list tags"];
        }
        
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    switch (self.displayCase)
    {
        case SSDebugDataShowLists:
            self.title = @"Lists";
            break;
        case SSDebugDataShowListItems:
            self.title = [NSString stringWithFormat:@"List Items - %@", ((SSList *)self.parentObj).name];
            break;
        case SSDebugDataShowAllListItems:
            self.title = @"All List Items";
            break;
        case SSDebugDataShowTags:
            self.title = @"Tags";
            break;
        case SSDebugDataShowListTags:
            self.title = [NSString stringWithFormat:@"List Tags - %@", ((SSList *)self.parentObj).name];
            break;
        case SSDebugDataShowAllListTags:
            self.title = @"All List Tags";
            break;
        case SSDebugDataShowOptions:
            self.title = @"Options";
            break;
        default:
            break;
    }

    if (self.navigationController.viewControllers.count == 1)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeDebugMenu)];
    }
    
    // Custom nav bar items to avoid using multiple sections in the table view
    if (self.displayCase == SSDebugDataShowListItems)
    {
        UIBarButtonItem *showListTags = [[UIBarButtonItem alloc] initWithTitle:@"List Tags" style:UIBarButtonItemStylePlain target:self action:@selector(showAllListTags)];
        self.navigationItem.rightBarButtonItem = showListTags;
    }
}

- (void)showAllLists
{
    [self.navigationController pushViewController:[[SSDebugDataViewController alloc] initWithDebugDataCase:SSDebugDataShowLists parentItem:nil] animated:YES];
}

- (void)showAllListItems
{
    [self.navigationController pushViewController:[[SSDebugDataViewController alloc] initWithDebugDataCase:SSDebugDataShowAllListItems parentItem:nil] animated:YES];
}

- (void)showAllTags
{
    [self.navigationController pushViewController:[[SSDebugDataViewController alloc] initWithDebugDataCase:SSDebugDataShowTags parentItem:nil] animated:YES];
}

- (void)showAllListTags
{
    [self.navigationController pushViewController:[[SSDebugDataViewController alloc] initWithDebugDataCase:SSDebugDataShowAllListTags parentItem:self.parentObj] animated:YES];
}

- (void)closeDebugMenu
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SS_CELL_DEBUG_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SS_CELL_DEBUG_ID];
        cell.detailTextLabel.numberOfLines = 0;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (self.displayCase == SSDebugDataShowLists)
    {
        cell.textLabel.text = ((SSList *)self.data[indexPath.row]).name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (self.displayCase == SSDebugDataShowListItems || self.displayCase == SSDebugDataShowAllListItems)
    {
        cell.textLabel.text = ((SSListItem *)self.data[indexPath.row]).title;
    }
    else if (self.displayCase == SSDebugDataShowTags)
    {
        cell.textLabel.text = ((SSTag *)self.data[indexPath.row]).name;
    }
    else if (self.displayCase == SSDebugDataShowListTags)
    {
        cell.textLabel.text = ((SSListTag *)self.data[indexPath.row]).name;
    }
    else if (self.displayCase == SSDebugDataShowAllListTags)
    {
        cell.textLabel.text = ((SSListTag *)self.data[indexPath.row]).name;
    }
    else if (self.displayCase == SSDebugDataShowOptions)
    {
        cell.textLabel.text = (NSString *)self.data[indexPath.row];
    }
    
    if (self.displayCase != SSDebugDataShowOptions)
    {
        __kindof SSObject *ssObj = (SSObject *)self.data[indexPath.row];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Database ID:%@\nRecordName:%@\nzoneId:%@",
                                     ssObj.dbID,
                                     ssObj.objCKRecord.recordID.recordName,
                                     ssObj.objCKRecord.recordID.zoneID.zoneName];
    }
    
    return cell;
}

#pragma mark - Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SSDebugDataViewController *debuggerVC;
    
    if (self.displayCase == SSDebugDataShowOptions)
    {
        switch (indexPath.row)
        {
            case 0:
                [self showAllLists];
                break;
            case 1:
                [self showAllListItems];
                break;
            case 2:
                [self showAllTags];
                break;
            case 3:
                [self showAllListTags];
                break;
            default:
                break;
        }
    }
    
    if (self.displayCase == SSDebugDataShowLists)
    {
        debuggerVC = [[SSDebugDataViewController alloc] initWithDebugDataCase:SSDebugDataShowListItems parentItem:self.data[indexPath.row]];
        [self.navigationController pushViewController:debuggerVC animated:YES];
    }
    else if (self.displayCase == SSDebugDataShowListItems)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *itemData = [NSString new];
        SSListItem *listItem = self.data[indexPath.row];
        NSMutableDictionary *listItemData = [[NSMutableDictionary alloc] initWithDictionary:[listItem dictionaryRepresentation]];
        listItemData[@"dbID"] = listItem.dbID;
        listItemData[@"fkListID"] = listItem.fkListID;
        listItemData[@"fkTagID"] = listItem.fkTagID;
        
        for (NSString *propertyKey in listItemData)
        {
            if ([listItemData[propertyKey] isKindOfClass:[CKReference class]])
            {
                CKReference *listItemReference = (CKReference*)listItemData[propertyKey];
                NSString *referenceData = [NSString stringWithFormat:@"(RecordID Name): %@", listItemReference.recordID.recordName];
                itemData = [itemData stringByAppendingString:[NSString stringWithFormat:@"%@ - %@\n\n", propertyKey, referenceData]];
            }
            else
            {
                itemData = [itemData stringByAppendingString:[NSString stringWithFormat:@"%@ - %@\n\n", propertyKey, listItemData[propertyKey]]];
            }
        }
        
        [self showAlertControllerWithTitle:@"List Item Data" message:itemData];
    }
    else if (self.displayCase == SSDebugDataShowTags || self.displayCase == SSDebugDataShowListTags)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *tagDataString = [NSString new];
        SSTag *tag = self.data[indexPath.row];
        NSMutableDictionary *tagData = [[NSMutableDictionary alloc] initWithDictionary:[tag dictionaryRepresentation]];
        tagData[@"dbID"] = tag.dbID;
        
        for (NSString *propertyKey in tagData)
        {
            tagDataString = [tagDataString stringByAppendingString:[NSString stringWithFormat:@"%@ - %@\n\n", propertyKey, tagData[propertyKey]]];
        }
        
        [self showAlertControllerWithTitle:self.displayCase == SSDebugDataShowTags ? @"Master Tag Data" : @"List Tag Data" message:tagDataString];
    }
}

@end
