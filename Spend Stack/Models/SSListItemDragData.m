//
//  SSListItemDragData.m
//  Spend Stack
//
//  Created by Jordan Morgan on 10/22/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListItemDragData.h"

@implementation SSListItemDragData

#pragma mark - Lazy Loads

- (NSMutableArray <SSListItem *> *)listItems
{
    if (_listItems == nil) _listItems = [NSMutableArray new];
    return _listItems;
}

@end
