//
//  RatingsPrompter.h
//  Spend Stack
//
//  Created by Jordan Morgan on 4/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RatingsPrompter : NSObject

@property (nonatomic) NSUInteger numberOfAppLaunchesRequired;
@property (nonatomic) NSUInteger numberOfDaysInstalledRequired;
@property (nonatomic) NSUInteger numberOfSignificantEventsRequired;

+ (instancetype _Nonnull)sharedInstance;
- (void)logSignificantEventWithName:(NSString * _Nonnull)eventName;
- (void)logAppLaunchAndInstallDateIfNeeded;
- (void)showRatingsPromptIfNeeded;
- (void)debug_consoleLogoutCurrentRatingEventValues;

@end
