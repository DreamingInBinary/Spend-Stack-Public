//
//  UITableView+Common.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (Common)

- (void)batchUpdateWithPreviousNumberOfRows:(NSInteger)previousCount updatedNumberOfRows:(NSInteger)newCount inSection:(NSInteger)section;

@end
