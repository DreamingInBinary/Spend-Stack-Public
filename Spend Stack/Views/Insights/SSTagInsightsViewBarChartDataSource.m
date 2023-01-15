//
//  SSTagInsightsViewBarChartDataSource.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTagInsightsViewBarChartDataSource.h"

@interface SSTagInsightsViewBarChartDataSource()

@property (weak, nonatomic, nullable) SSList *list;

@end

@implementation SSTagInsightsViewBarChartDataSource

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

#pragma mark - Public Methods

- (NSString *)listCurrencyID
{
    return self.list.currencyIdentifier;
}

#pragma mark - Bar Graph Data Source

- (NSInteger)numberOfPlotsInGraphChartView:(nonnull ORKGraphChartView *)graphChartView
{
    return 1;
}

- (nonnull ORKValueStack *)graphChartView:(nonnull ORKGraphChartView *)graphChartView dataPointForPointIndex:(NSInteger)pointIndex plotIndex:(NSInteger)plotIndex
{
    SSListTag *currentTagKey = self.list.datasourceAdapter.sortedTags[pointIndex];
    
    double total = 0.0;
    for (SSListItem *listItem in self.list.datasourceAdapter.itemsByTag[currentTagKey])
    {
        total += [listItem calcTotalAmount:self.list.taxInfo taxUtil:self.list.taxUtil].doubleValue;
    }
    total = round(total);
    
    return [[ORKValueStack alloc] initWithStackedValues:@[@(total)]];
}

- (NSInteger)graphChartView:(nonnull ORKGraphChartView *)graphChartView numberOfDataPointsForPlotIndex:(NSInteger)plotIndex
{
    return self.list.datasourceAdapter.sortedTags.count;
}

- (NSString *)graphChartView:(ORKGraphChartView *)graphChartView titleForXAxisAtPointIndex:(NSInteger)pointIndex
{
    SSListTag *currentTagKey = self.list.datasourceAdapter.sortedTags[pointIndex];
    return [currentTagKey isEqual:self.list.datasourceAdapter.miscTag] ? @"Misc." : currentTagKey.name;
}

- (UIColor *)graphChartView:(ORKGraphChartView *)graphChartView colorForPlotIndex:(NSInteger)plotIndex
{
    // Single plot graphs always report a 0 index here. We have to do manual book keeping.
    static NSInteger pseudoIdx = 0;
    if (pseudoIdx >= self.list.datasourceAdapter.sortedTags.count) pseudoIdx = 0;
    
    SSListTag *tag = self.list.datasourceAdapter.sortedTags[pseudoIdx];
    UIColor *tagColor = [SSTag rawColorFromColor:tag.color];
    pseudoIdx++;
    
    return tagColor;
}

- (NSString *)graphChartView:(ORKGraphChartView *)graphChartView accessibilityUnitLabelForPlotIndex:(NSInteger)plotIndex
{
    return [self.list.taxUtil.currencyLocale currencySymbol];
}

- (NSString *)graphChartView:(ORKGraphChartView *)graphChartView accessibilityLabelForXAxisAtPointIndex:(NSInteger)pointIndex
{
    SSListTag *currentTagKey = self.list.datasourceAdapter.sortedTags[pointIndex];
    return currentTagKey.name;
}

#pragma mark - Graph Delegate

- (void)graphChartView:(ORKGraphChartView *)graphChartView touchesMovedToXPosition:(CGFloat)xPosition
{
    // If I can figure out snap points, this would be nice to have
    //[UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
}

@end
