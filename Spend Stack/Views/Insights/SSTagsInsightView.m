//
//  SSTagsInsightView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/4/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTagsInsightView.h"
#import "SSEmptyStateView.h"
#import "SSTagInsightsViewBarChartDataSource.h"
#import "SSTagInsightsViewPieChartDataSource.h"
#import "ORKBarGraphChartView.h"
#import "ORKPieChartView.h"
#import "ORKChartTypes.h"

@implementation SSTagsInsightLegendView

- (CGFloat)tagSize
{
    return [SSCitizenship accessibilityFontsEnabled] ? TAG_HEIGHT_WIDTH_ACCESSIBILITY : TAG_HEIGHT_WIDTH_REGULAR;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeDotView)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)resizeDotView
{
    self.dotView.layer.cornerRadius = self.tagSize/2;
    [self.dotView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@(self.tagSize));
    }];
}

@end

@interface SSTagsInsightView()

@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nonnull) SSLabel *tagLabel;
@property (strong, nonatomic, nonnull) UISegmentedControl *segmentControl;
@property (strong, nonatomic, nonnull) ORKBarGraphChartView *barChartView;
@property (strong, nonatomic, nonnull) ORKPieChartView *pieChartView;
@property (strong, nonatomic, nonnull) SSHorizontalStackView *chartLegendStackView;
@property (strong, nonatomic, nonnull) SSTagInsightsViewBarChartDataSource *barChartDataSource;
@property (strong, nonatomic, nonnull) SSTagInsightsViewPieChartDataSource *pieChartDataSource;
@property (strong, nonatomic, nonnull) UIScrollView *legendScrollView;
@property (strong, nonatomic, nonnull) SSHorizontalStackView *chartsLegendView;

@end

@implementation SSTagsInsightView

static inline CGAffineTransform ss_insightsChartScaleDownTransform ()
{
    return CGAffineTransformMakeScale(0.80f, 0.80f);
}

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list frame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.list = list;
        self.barChartDataSource = [[SSTagInsightsViewBarChartDataSource alloc] initWithList:self.list];
        self.pieChartDataSource = [[SSTagInsightsViewPieChartDataSource alloc] initWithList:self.list];
        [self setConstraints];
        [self.barChartView animateWithDuration:SSFastAnimationDuration];
    }
    
    return self;
}

#pragma mark - Layout

- (void)setConstraints
{
    BOOL userHasNoTags = self.list.datasourceAdapter.userCreatedTags.count == 0;
    
    // Tag label
    self.tagLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
    [self.tagLabel configureFontWeight:UIFontWeightSemibold];
    self.tagLabel.text = ss_Localized(@"firstRun.vc.tags");
    
    // Stepper
    self.segmentControl = [[UISegmentedControl alloc] initWithItems:@[ss_Localized(@"tagInsights.bar"), ss_Localized(@"tagInsights.pie")]];
    [self.segmentControl addTarget:self action:@selector(onSegmentChange:) forControlEvents:UIControlEventValueChanged];
    [self.segmentControl setSelectedSegmentIndex:0];
    
    // Bar Chart
    self.barChartView = [ORKBarGraphChartView new];
    self.barChartView.dataSource = self.barChartDataSource;
    self.barChartView.delegate = self.barChartDataSource;
    self.barChartView.showsVerticalReferenceLines = YES;
    self.barChartView.showsHorizontalReferenceLines = YES;
    self.barChartView.decimalPlaces = 0;
    self.barChartView.referenceLineColor = [UIColor ssMutedColor];
    self.barChartView.tintColor = [UIColor ssMainFontColor];
    self.barChartView.axisColor = [UIColor ssMutedColor];
    self.barChartView.scrubberLineColor = [UIColor ssMainFontColor];
    self.barChartView.verticalAxisTitleColor = [UIColor ssMutedColor];
    self.barChartView.yAxisLabelFactors = @[@0, @0.25, @0.50, @0.75, @1];
    self.barChartView.noDataText = ss_Localized(@"tagInsights.noData");
    
    // Pie chart
    self.pieChartView = [ORKPieChartView new];
    self.pieChartView.dataSource = self.pieChartDataSource;
    self.pieChartView.lineWidth = SSSpacingBigMargin;
    self.pieChartView.noDataText =ss_Localized(@"tagInsights.noData");
    self.pieChartView.alpha = 0.0f;
    self.pieChartView.transform = ss_insightsChartScaleDownTransform();
    
    // Legend View
    self.chartsLegendView = [self createLegendView];
    self.legendScrollView = [UIScrollView new];
    self.legendScrollView.showsHorizontalScrollIndicator = NO;
    self.legendScrollView.alwaysBounceHorizontal = NO;
    [self.legendScrollView addSubview:self.chartsLegendView];
    
    // Constraints
    [self addSubviews:@[self.tagLabel, self.segmentControl, self.barChartView, self.pieChartView, self.legendScrollView]];
    
    [self.tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
    }];
    
    [self.segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.top.equalTo(self.tagLabel.mas_bottom).with.offset(SSTopBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.height.equalTo(self.segmentControl.mas_height);
    }];
    
    [self.barChartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentControl.mas_bottom).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.height.equalTo(self.mas_width);
    }];
    
    [self.pieChartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentControl.mas_bottom).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.height.equalTo(self.pieChartView.mas_width);
    }];
    
    NSNumber *legendHeight = @([UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize + SSTopBigElementMargin);
    if (legendHeight.integerValue < SSUIKitMinimumTapHeight) legendHeight = @(SSUIKitMinimumTapHeight);
    if (userHasNoTags) legendHeight = @(0);
    
    [self.legendScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.barChartView.mas_bottom);
        make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
        make.height.equalTo(legendHeight);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom);
    }];
    
    [self.chartsLegendView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.legendScrollView);
        make.height.equalTo(legendHeight);
    }];
    
    if (userHasNoTags)
    {
        self.legendScrollView.hidden = YES;
        self.chartsLegendView.hidden = YES;
        self.pieChartView.hidden = YES;
        self.barChartView.hidden = YES;
        self.segmentControl.hidden = YES;
        
        [self.segmentControl mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).with.offset(SSLeftBigElementMargin);
            make.top.equalTo(self.tagLabel.mas_bottom).with.offset(SSTopBigElementMargin);
            make.right.equalTo(self.mas_right).with.offset(SSRightBigElementMargin);
            make.height.equalTo(@(0));
        }];
        
        SSEmptyStateView *emptyView = [[SSEmptyStateView alloc] initWithStateText:ss_Localized(@"tagInsights.empty")];
        [self addSubview:emptyView];
        
        [emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.barChartView);
        }];
    }
}

#pragma mark - Segment Callbacks

- (void)onSegmentChange:(UISegmentedControl *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
    
    [UIView animateWithDuration:SSFastAnimationDuration animations:^{
        self.pieChartView.alpha = self.pieChartView.alpha == 0 ? 1.0f : 0.0f;
        self.barChartView.alpha = self.barChartView.alpha == 0 ? 1.0f : 0.0f;
        
        self.pieChartView.transform = self.pieChartView.alpha == 0 ? ss_insightsChartScaleDownTransform() : CGAffineTransformIdentity;
        self.barChartView.transform = self.barChartView.alpha == 0 ? ss_insightsChartScaleDownTransform() : CGAffineTransformIdentity;
    }];
}

#pragma mark - Legend Setup

- (SSHorizontalStackView *)createLegendView
{
    SSHorizontalStackView *contentStackView = [SSHorizontalStackView new];
    contentStackView.verticalAlignment = UIStackViewAlignmentCenter;
    contentStackView.spacing = SSSpacingMargin;
    
    CGFloat tagSize = [SSCitizenship accessibilityFontsEnabled] ? TAG_HEIGHT_WIDTH_ACCESSIBILITY : TAG_HEIGHT_WIDTH_REGULAR;
    
    for (SSListTag *tag in self.list.datasourceAdapter.sortedTags)
    {
        SSTagsInsightLegendView *legendView = [SSTagsInsightLegendView new];
        
        legendView.dotView = [UIView new];
        legendView.dotView.layer.cornerRadius = tagSize/2;
        legendView.dotView.backgroundColor = [SSTag rawColorFromColor:tag.color];
        legendView.dotView.isAccessibilityElement = NO;
        
        legendView.tagLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        legendView.tagLabel.textColor = [UIColor ssMainFontColor];
        legendView.tagLabel.text = tag.name;
        legendView.tagLabel.numberOfLines = 1;
        legendView.tagLabel.isAccessibilityElement = NO;
        [legendView.tagLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [legendView.tagLabel configureFontWeight:UIFontWeightSemibold];
        [legendView.tagLabel sizeToFit];
        
        [legendView addSubviews:@[legendView.dotView, legendView.tagLabel]];
        
        [legendView.dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(legendView.mas_leading);
            make.centerY.equalTo(legendView.mas_centerY);
            make.height.and.width.equalTo(@(tagSize));
        }];
        
        [legendView.tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(legendView.dotView.mas_trailing).with.offset(SSLeftElementMargin);
            make.width.equalTo(legendView.tagLabel.mas_width);
            make.top.and.bottom.equalTo(legendView);
            make.trailing.equalTo(legendView.mas_trailing).with.offset(SSRightBigElementMargin);
        }];
        
        legendView.accessibilityLabel = [NSString stringWithFormat:ss_Localized(@"tagInsights.acc"), tag.name, tag.color];
        
        [contentStackView addArrangedSubview:legendView];
    }
    
    return contentStackView;
}

@end
