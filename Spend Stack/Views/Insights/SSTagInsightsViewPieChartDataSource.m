//
//  SSTagInsightsViewPieChartDataSource.m
//  Spend Stack
//
//  Created by Jordan Morgan on 9/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSTagInsightsViewPieChartDataSource.h"

@interface SSTagInsightsViewPieChartDataSource()

@property (weak, nonatomic, nullable) SSList *list;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSTagInsightsViewPieChartDataSource 

#pragma mark - Initializer

- (instancetype)initWithList:(SSList *)list
{
    self = [super init];
    
    if (self)
    {
        self.list = list;
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:self.list.currencyIdentifier];
    }
    
    return self;
}

#pragma mark - Pie Chart Datasource

- (NSInteger)numberOfSegmentsInPieChartView:(nonnull ORKPieChartView *)pieChartView
{
    return self.list.datasourceAdapter.sortedTags.count;
}

- (CGFloat)pieChartView:(nonnull ORKPieChartView *)pieChartView valueForSegmentAtIndex:(NSInteger)index
{
    SSListTag *currentTagKey = self.list.datasourceAdapter.sortedTags[index];
    return [self.list itemTotalForTag:currentTagKey];
}

- (UIColor *)pieChartView:(ORKPieChartView *)pieChartView colorForSegmentAtIndex:(NSInteger)index
{
    SSListTag *tag = self.list.datasourceAdapter.sortedTags[index];
    return [SSTag rawColorFromColor:tag.color];
}

- (NSString *)pieChartView:(ORKPieChartView *)pieChartView titleForSegmentAtIndex:(NSInteger)index
{
    SSListTag *currentTagKey = self.list.datasourceAdapter.sortedTags[index];
    double total = [self.list itemTotalForTag:currentTagKey];
    
    return [NSString stringWithFormat:@"%@ (%@)", currentTagKey.name, [self.taxUtil guranteedCurrencyString:@(total).stringValue]];
}

@end
