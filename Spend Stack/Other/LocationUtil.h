//
//  LocationUtil.h
//  Spend Stack
//
//  Created by Jordan Morgan on 2/3/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, SSFetchedUserLocale)
{
    SSFetchedUserLocaleUnitedStates,
    SSFetchedUserLocaleNotFound
};


static NSString * const _Nonnull SS_LOCATION_CHANGED = @"locationChanged";
static NSString * const _Nonnull SS_RECENT_LOCATION_FORMATTED_KEY = @"recentLocationFormatted";
static NSString * const _Nonnull SS_RECENT_LOCATION_LATITUDE_KEY = @"recentLocationLatitude";
static NSString * const _Nonnull SS_RECENT_LOCATION_LONGITUDE_KEY = @"recentLocationLongitude";

@interface LocationUtil : NSObject

@property (nonatomic) SSFetchedUserLocale fetchedUserLocale;
@property (strong, nonatomic, readonly, nullable) NSString *recentCity;
@property (strong, nonatomic, readonly, nullable) NSString *recentState;
@property (strong, nonatomic, readonly, nullable) NSString *recentLocationFormattedTitle;
@property (strong, nonatomic, readonly, nullable) CLLocation *recentLocation;
@property (copy) void (^ _Nullable onPermissionGranted)(void);
@property (copy) void (^ _Nullable onLocationFetched)(void);
@property (copy) void (^ _Nullable onPermissionNeeded)(CLAuthorizationStatus authStatus);

+ (instancetype _Nonnull)sharedInstance;
- (void)triggerLocationUpdate;
- (void)requestPermissions;
- (BOOL)locationServicesEnabled;

@end
