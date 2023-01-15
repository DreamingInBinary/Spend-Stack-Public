//
//  SSQuickFindViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/2/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
#import "SSQuickFindResult.h"

static NSString * const _Nonnull SS_SHOW_OR_HIDE_SEARCH = @"ssShowOrHideSearch";

@protocol SSQuickFindViewControllerDelegate <NSObject>

@optional
- (void)ss_searchTermWasTapped:(SSQuickFindResult * _Nonnull)result;

@end

@interface SSQuickFindViewController : SSBaseViewController <UISearchResultsUpdating,
                                                             UISearchControllerDelegate,
                                                             UISearchBarDelegate>

@property (weak, nonatomic, nullable) id <SSQuickFindViewControllerDelegate> delegate;
@property (weak, nonatomic, nullable) UISearchController *searchController;

- (instancetype _Nonnull)initWithDelegate:(id <SSQuickFindViewControllerDelegate> _Nonnull)delegate;

@end

