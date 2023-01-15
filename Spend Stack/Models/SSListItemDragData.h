//
//  SSListItemDragData.h
//  Spend Stack
//
//  Created by Jordan Morgan on 10/22/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSIndexPath;

NS_ASSUME_NONNULL_BEGIN

@interface SSListItemDragData : NSObject

@property (strong, nonatomic, nullable) NSIndexPath *indexPathToReselect;
@property (strong, nonatomic, nonnull) NSIndexPath *indexPath;
@property (strong, nonatomic, nonnull) NSMutableArray <SSListItem *> *listItems;
@property (strong, nonatomic, nonnull) SSList *list;

@end

NS_ASSUME_NONNULL_END
