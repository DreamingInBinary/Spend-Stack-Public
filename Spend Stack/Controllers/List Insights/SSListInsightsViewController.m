//
//  SSListStatsViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 7/15/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListInsightsViewController.h"
#import "SSTagsInsightView.h"
#import "SSAllItemsInsightView.h"
#import "SSTotalCostInsightsView.h"

@interface SSListInsightsViewController ()

@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nullable) SSTagsInsightView *tagsInsightView;
@property (strong, nonatomic, nullable) SSAllItemsInsightView *allItemsInsightView;
@property (strong, nonatomic, nullable) SSTotalCostInsightsView *totalCostsInsightView;
@property (strong, nonatomic, nonnull) SSToolbar *tb;
@property (nonatomic) BOOL hasCreatedConstraints;

@end

@implementation SSListInsightsViewController

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list
{
    self = [super init];
    
    if (self)
    {
        self.list = list;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Nav bar
    NSAssert([self.navigationController isKindOfClass:[SSModalCardNavigationController class]], @"Spend Stack - Wrong navigation controller supplied.");
    [((SSModalCardNavigationController *)self.navigationController) prepareForDownChevron:@selector(dismissController)];
    
    self.scrollView = [UIScrollView new];
    self.scrollView.clipsToBounds = NO;
    
    // Tags Info
    self.tagsInsightView = [[SSTagsInsightView alloc] initWithList:self.list frame:self.view.bounds];
    
    // All items
    self.allItemsInsightView = [[SSAllItemsInsightView alloc] initWithList:self.list frame:self.view.bounds];
    
    // Total
    self.totalCostsInsightView = [[SSTotalCostInsightsView alloc] initWithList:self.list frame:self.view.bounds];
    
    self.tb = [[SSToolbar alloc] initWithItemTypes:@[SSToolBarItemTypeShare,
                                                     SSToolBarItemTypeFlexSpace,
                                                     SSToolBarItemTypeDone]];
    
    __weak typeof(self) weakSelf = self;
    self.tb.onShare = ^{
        [weakSelf presentShareSheet:weakSelf.tb.items.firstObject];
    };
    
    self.tb.onDone = ^{
        [weakSelf dismissController];
    };
    
    [self.view addSubviews:@[self.scrollView, self.tb]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.hasCreatedConstraints) return;
    
    UIView *container = [UIView new];
    [container addSubviews:@[self.tagsInsightView, self.allItemsInsightView, self.totalCostsInsightView]];
    [self.scrollView addSubviews:@[container]];
    
    // Constraints, because in these modal views on iPad it reports the base controller's huge width in viewDidLoad
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.tb.mas_top).with.offset(SSBottomBigElementMargin);
        
        make.edges.equalTo(container);
    }];
    
    [self.tb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.scrollView.mas_width);
    }];
    
    // Dummy view to hide safe area insets
    UIView *dummyView = [UIView new];
    dummyView.backgroundColor = self.view.backgroundColor;
    [self.view insertSubview:dummyView aboveSubview:container];
    
    [dummyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.and.bottom.equalTo(self.view);
        make.top.equalTo(self.tb.mas_bottom);
    }];
    
    [self.tagsInsightView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.and.trailing.equalTo(container);
    }];
    
    [self.allItemsInsightView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.and.trailing.equalTo(container);
        make.top.equalTo(self.tagsInsightView.mas_bottom);
    }];
    
    [self.totalCostsInsightView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.leading.and.trailing.equalTo(container);
        make.top.equalTo(self.allItemsInsightView.mas_bottom);
    }];
    
    self.hasCreatedConstraints = YES;
}

#pragma mark - Popover Presentation

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    popoverPresentationController.barButtonItem = self.tb.items.firstObject;
}

#pragma mark - Present Share

- (void)presentShareSheet:(UIBarButtonItem *)sender
{
    UIActivityViewController *activityItemVC = [[UIActivityViewController alloc] initWithActivityItems:@[[self imageOfInsights]] applicationActivities:nil];
    activityItemVC.popoverPresentationController.delegate = self;
    [self presentViewController:activityItemVC animated:YES completion:nil];
}

- (UIImage *)imageOfInsights
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:self.scrollView.contentSize];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGPoint savedContentOffset = self.scrollView.contentOffset;
        CGRect savedFrame = self.scrollView.frame;
        
        self.scrollView.contentOffset = CGPointZero;
        self.scrollView.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
        
        [self.scrollView.layer renderInContext:ctx.CGContext];
        
        self.scrollView.contentOffset = savedContentOffset;
        self.scrollView.frame = savedFrame;
    }];
}

@end
