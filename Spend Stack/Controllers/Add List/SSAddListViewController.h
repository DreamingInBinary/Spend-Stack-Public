//
//  SSAddListViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 1/28/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
@class SSListBuilder;

@interface SSAddListViewController : SSBaseViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic, nonnull) SSList *workingList;

@end
