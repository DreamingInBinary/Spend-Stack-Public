//
//  SSListSectionHeaderView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/17/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const _Nonnull SS_LIST_SECTION_HEADER_ID = @"SSSectionHeader";

@interface SSListSectionHeaderView : UITableViewHeaderFooterView

@property (strong, nonatomic, readwrite, nullable) NSString *titleString;
- (CGFloat)estimatedHeightForHeaderInView:(UIView * _Nonnull)view;

@end
