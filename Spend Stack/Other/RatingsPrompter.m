//
//  RatingsPrompter.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/23/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "RatingsPrompter.h"
#import "Spend_Stack_2-Swift.h"
#import <StoreKit/StoreKit.h>

static NSString * const _Nonnull RatingsPromptAppLaunches = @"RatingsPromptAppLaunces";
static NSString * const _Nonnull RatingsPromptDateInstalled = @"RatingsPromptDateInstalled";
static NSString * const _Nonnull RatingsPromptSigEvents = @"RatingsPromptSigEvents";
static NSString * const _Nonnull RatingsPromptVersionRequested = @"RatingsPromptVersionRequested";

@implementation RatingsPrompter

#pragma mark - Initializers

+ (instancetype)sharedInstance {
    static RatingsPrompter *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    
    return sharedManager;
}

#pragma mark - Private Methods

- (NSInteger)daysBetweenDate:(NSDate *)fromDateTime andDate:(NSDate *)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay
                startDate:&fromDate
                 interval:NULL
                  forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay
                startDate:&toDate
                 interval:NULL
                  forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    
    return [difference day];
}

- (NSInteger)calculateDaysInstalled
{
    NSDate *installDate = (NSDate *)[ss_defaults() objectForKey:RatingsPromptDateInstalled];
    NSUInteger daysSinceInstall = [self daysBetweenDate:installDate andDate:[NSDate date]];
    return daysSinceInstall;
}

#pragma mark - Public API

- (void)logSignificantEventWithName:(NSString *)eventName
{
    // Significant events are stored in an array, with the key count being the number
    // Of significant events that have occurred.
    NSMutableArray <NSString *> *existingEvents = [[ss_defaults() arrayForKey:RatingsPromptSigEvents] mutableCopy];
    if (existingEvents == nil) existingEvents = [NSMutableArray new];
    
    // Format the date with it
    NSDate *currentDate = [NSDate date];
    NSString *eventEntry = [NSString stringWithFormat:@"%@ - %@", eventName, currentDate];
    
    // Add the events
    [existingEvents addObject:eventEntry];
    
    [ss_defaults() setObject:[NSArray arrayWithArray:existingEvents] forKey:RatingsPromptSigEvents];
}

- (void)logAppLaunchAndInstallDateIfNeeded
{
    NSNumber *launches = [ss_defaults() objectForKey:RatingsPromptAppLaunches];
    if (launches == nil) launches = @(0);
    launches = @(launches.integerValue + 1);
    
    NSDate *installDate = [ss_defaults() objectForKey:RatingsPromptDateInstalled];
    if (installDate == nil) installDate = [NSDate date];
    
    [ss_defaults() setObject:launches forKey:RatingsPromptAppLaunches];
    [ss_defaults() setObject:installDate forKey:RatingsPromptDateInstalled];
}

- (void)showRatingsPromptIfNeeded
{
    BOOL launchesMet = YES;
    
    // Launch criteria met?
    NSNumber *launches = (NSNumber *)[ss_defaults() objectForKey:RatingsPromptAppLaunches] ?: @0;
    launchesMet = launches.integerValue >= self.numberOfAppLaunchesRequired;
    
    UIWindowScene *connectedScene = [UIWindow firstActiveScene];
    if (launchesMet && connectedScene)
    {
        if (@available(iOS 14.0, *)) {
            [SKStoreReviewController requestReviewInScene:connectedScene];
        } else {
            [SKStoreReviewController requestReview];
        }
    }
}

- (void)debug_consoleLogoutCurrentRatingEventValues
{
    NSNumber *launches = (NSNumber *)[ss_defaults() objectForKey:RatingsPromptAppLaunches];
    NSDate *installDate = (NSDate *)[ss_defaults() objectForKey:RatingsPromptDateInstalled];
    NSArray <NSString *> *significantEvents = [ss_defaults() arrayForKey:RatingsPromptSigEvents];
    
    NSLog(@"Spend Stack - Ratings Prompt Values:\n\nLaunches: %@\nInstall Date: %@\nDays Installed:%@\nEvents:%@\n", launches, installDate, @([self calculateDaysInstalled]), significantEvents);
}

@end
