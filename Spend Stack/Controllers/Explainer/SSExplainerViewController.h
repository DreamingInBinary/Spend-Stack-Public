//
//  SSExplainerViewController.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSBaseViewController.h"
#import "ExplainerDataUtil.h"

@interface SSExplainerViewController : SSBaseViewController

@property (nonatomic, getter=shouldShowDoneButton) BOOL showDoneButton;
@property (copy) void (^ _Nullable onDismiss)(void);
- (instancetype _Nonnull)initWithExplainedFeature:(ExplainFeature)feature;

@end
