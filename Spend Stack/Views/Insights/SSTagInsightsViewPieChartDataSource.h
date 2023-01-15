//
//  SSTagInsightsViewPieChartDataSource.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORKPieChartView.h"
#import "ORKChartTypes.h"

@interface SSTagInsightsViewPieChartDataSource : NSObject <ORKPieChartViewDataSource>

- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list;

@end
