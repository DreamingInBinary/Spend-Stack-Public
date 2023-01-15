//
//  SSListTagTotalFooterView.h
//  Spend Stack
//
//  Created by Jordan Morgan on 3/30/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "SSListSectionFooterUpdate.h"

static NSString * const _Nonnull SS_LIST_SECTION_FOOTER_ID = @"SSSectionFooter";

@interface SSListSectionFooterView : UITableViewHeaderFooterView

- (CGFloat)estimatedHeightForHeaderInView:(UIView * _Nonnull)view;
- (void)setTotalWithTag:(SSListTag * _Nonnull)tag
               tagItems:(NSArray <SSListItem *> * _Nonnull)taggedItems
                taxInfo:(SSTaxRateInfo * _Nonnull)taxInfo
             currencyID:(NSString * _Nonnull)currencyID;

@end
