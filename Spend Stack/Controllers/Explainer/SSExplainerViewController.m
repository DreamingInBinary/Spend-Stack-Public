//
//  SSExplainerViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/11/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSExplainerViewController.h"
#import "ExplainerDataUtil.h"
#import "EmailSender.h"
#import <AVFoundation/AVFoundation.h>

@interface SSExplainerViewController ()

@property (nonatomic) ExplainFeature featureToExplain;
@property (strong, nonatomic, nonnull) EmailSender *emailer;
@property (strong, nonatomic, nonnull) ExplainerDataUtil *dataUtil;
@property (strong, nonatomic, nonnull) SSVerticalView *verticalView;

@end

@implementation SSExplainerViewController

#pragma mark - Custom Setters

- (void)setShowDoneButton:(BOOL)showDoneButton
{
    _showDoneButton = showDoneButton;
    if (showDoneButton)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissWithCompletionHandler)];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Initializer

- (instancetype)initWithExplainedFeature:(ExplainFeature)feature
{
    self = [super init];
    
    if (self)
    {
        self.featureToExplain = feature;
        self.emailer = [[EmailSender alloc] initWithContainingController:self];
        self.dataUtil = [[ExplainerDataUtil alloc] initWithExplainedFeature:self.featureToExplain];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [self.dataUtil featureViewControllerTitle];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.verticalView = [[SSVerticalView alloc] initWithSecondaryBackgroundColor];
    self.verticalView.backgroundColor = [UIColor systemBackgroundColor];
    self.verticalView.hidesSeparatorsByDefault = YES;
    self.verticalView.rowInset = UIEdgeInsetsMake(SSTopBigElementMargin, SSLeftBigElementMargin, SSBottomBigElementMargin, SSRightBigElementMargin);
    [self.view addSubview:self.verticalView];
    
    // View setup
    SSLabel *headerLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
    [headerLabel configureFontWeight:UIFontWeightSemibold];
    headerLabel.text = [self.dataUtil featureHeading];
    
    SSLabel *detailLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
    detailLabel.text = [self.dataUtil featureDescription];
    
    SSButton *button = [[SSButton alloc] initWithText:ss_Localized(@"general.contactSupport")];
    [button addTarget:self action:@selector(showHelp) forControlEvents:UIControlEventTouchUpInside];
    
    [self.verticalView addRows:@[headerLabel, detailLabel, button] animated:NO];
    
    // Constraints
    [self.verticalView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.and.bottom.equalTo(self.view);
    }];
}

#pragma mark - Private Methods

- (void)showHelp
{
    [self.emailer sendSupportEmail];
}

- (void)dismissWithCompletionHandler
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onDismiss) self.onDismiss();
    }];
}

@end
