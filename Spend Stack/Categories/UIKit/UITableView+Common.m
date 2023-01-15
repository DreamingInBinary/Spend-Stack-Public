//
//  UITableView+Common.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "UITableView+Common.h"

@implementation UITableView (Common)

- (void)batchUpdateWithPreviousNumberOfRows:(NSInteger)previousCount updatedNumberOfRows:(NSInteger)newCount inSection:(NSInteger)section
{
    BOOL rowsShouldBeAdded = newCount > previousCount;
    NSMutableArray <NSIndexPath *> *reloadIDPs = [NSMutableArray new];
    
    if (previousCount == newCount)
    {
        NSMutableArray <NSIndexPath *> *sectionIDPs = [NSMutableArray new];
        
        for (NSInteger row = 0; row < newCount; row++)
        {
            [sectionIDPs addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
        
        [self performBatchUpdates:^{
            [self reloadRowsAtIndexPaths:sectionIDPs withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:nil];
        
        return;
    }
    
    if (rowsShouldBeAdded)
    {
        NSMutableArray <NSIndexPath *> *newIDPS = [NSMutableArray new];
        
        // Row 0 is the segment control, which should be left alone
        for (NSInteger idx = 1; idx < newCount; idx++)
        {
            BOOL isNewRow = idx >= previousCount;
            
            if (isNewRow)
            {
                [newIDPS addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
            }
            else
            {
                [reloadIDPs addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
            }
        }
        
        [self performBatchUpdates:^{
            [self reloadRowsAtIndexPaths:reloadIDPs withRowAnimation:UITableViewRowAnimationAutomatic];
            [self insertRowsAtIndexPaths:newIDPS withRowAnimation:UITableViewRowAnimationMiddle];
        } completion:nil];
    }
    else
    {
        // Deletions here
        NSMutableArray <NSIndexPath *> *deletedIDPS = [NSMutableArray new];
        
        // Row 0 is the segment control, which should be left alone
        for (NSInteger idx = 1; idx < previousCount; idx++)
        {
            BOOL isDeletedRow = idx >= newCount;
            
            if (isDeletedRow)
            {
                [deletedIDPS addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
            }
            else
            {
                [reloadIDPs addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
            }
        }
        
        [self performBatchUpdates:^{
            [self reloadRowsAtIndexPaths:reloadIDPs withRowAnimation:UITableViewRowAnimationAutomatic];
            [self deleteRowsAtIndexPaths:deletedIDPS withRowAnimation:UITableViewRowAnimationFade];
        } completion:nil];
        
    }
}

@end
