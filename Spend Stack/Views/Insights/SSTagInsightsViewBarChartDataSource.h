//
//  SSTagInsightsViewBarChartDataSource.h
//  Spend Stack
//
//  Created by Jordan Morgan on 9/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORKBarGraphChartView.h"
#import "ORKChartTypes.h"

@interface SSTagInsightsViewBarChartDataSource : NSObject <ORKValueStackGraphChartViewDataSource, ORKGraphChartViewDelegate>

- (instancetype _Nonnull)initWithList:(SSList * _Nullable)list;
- (NSString * _Nonnull)listCurrencyID;

@end
