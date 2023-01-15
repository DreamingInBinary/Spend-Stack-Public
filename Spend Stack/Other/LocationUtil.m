//
//  LocationUtil.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/3/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "LocationUtil.h"
#import "SSConstants.h"
#import <CoreLocation/CoreLocation.h>

@interface LocationUtil() <CLLocationManagerDelegate>

@property (strong, nonatomic, readwrite, nullable) NSString *recentCity;
@property (strong, nonatomic, readwrite, nullable) NSString *recentState;
@property (strong, nonatomic, readwrite, nullable) NSString *recentLocationFormattedTitle;;
@property (strong, nonatomic, nonnull) CLLocationManager *locationManager;

@end

@implementation LocationUtil

#pragma mark - Property Logic

- (CLLocation *)recentLocation
{
    if (self.locationManager == nil) return nil;
    return self.locationManager.location;
}

#pragma mark - Initializer

+ (instancetype)sharedInstance {
    static LocationUtil *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
        sharedManager.fetchedUserLocale = SSFetchedUserLocaleNotFound;
        sharedManager.locationManager = [CLLocationManager new];
        sharedManager.locationManager.delegate = sharedManager;
        sharedManager.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    });
    
    return sharedManager;
}

- (void)requestPermissions
{
    CLAuthorizationStatus status;
    
    if (@available(iOS 14.0, *)) {
        status = self.locationManager.authorizationStatus;
    } else {
        status = [CLLocationManager authorizationStatus];
    }
    
    if (status == kCLAuthorizationStatusDenied)
    {
        if (@available(iOS 14.0, *)) {
            [self locationManagerDidChangeAuthorization:self.locationManager];
        } else {
            [self locationManager:self.locationManager didChangeAuthorizationStatus:kCLAuthorizationStatusDenied];
        }
        
        return;
    }
    
    [self.locationManager requestWhenInUseAuthorization];
}

#pragma mark - Location Delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.locationManager requestLocation];
        if (self.onPermissionGranted) self.onPermissionGranted();
    }
    else if (status == kCLAuthorizationStatusDenied)
    {
        if (self.onPermissionNeeded) self.onPermissionNeeded(status);
    }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    if (@available(iOS 14.0, *)) {
        if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
            manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)
        {
            [self.locationManager requestLocation];
            if (self.onPermissionGranted) self.onPermissionGranted();
        }
        else if (manager.authorizationStatus == kCLAuthorizationStatusDenied)
        {
            if (self.onPermissionNeeded) self.onPermissionNeeded(manager.authorizationStatus);
            
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [[CLGeocoder new] reverseGeocodeLocation:manager.location completionHandler:^ (NSArray <CLPlacemark *> *placeMarks, NSError *error) {
        if (error != nil)
        {
            NSLog(@"Spend Stack - Error retrieving location: %@", error.localizedDescription);
            [manager stopUpdatingLocation];
            if (self.onPermissionNeeded) self.onPermissionNeeded(kCLAuthorizationStatusNotDetermined);
            return;
        }
        
        CLPlacemark *placeMark = placeMarks.firstObject;
        
        if([placeMark.ISOcountryCode isEqualToString:COUNTRY_CODE_US])
        {
            self.fetchedUserLocale = SSFetchedUserLocaleUnitedStates;
            self.recentCity = placeMark.locality;
            self.recentState = placeMark.administrativeArea;
            self.recentLocationFormattedTitle = [NSString stringWithFormat:@"%@, %@", self.recentCity, self.recentState];
            [ss_defaults() setObject:self.recentLocationFormattedTitle forKey:SS_RECENT_LOCATION_FORMATTED_KEY];
            [ss_defaults() setObject:@(placeMark.location.coordinate.latitude) forKey:SS_RECENT_LOCATION_LATITUDE_KEY];
            [ss_defaults() setObject:@(placeMark.location.coordinate.longitude) forKey:SS_RECENT_LOCATION_LONGITUDE_KEY];
            [ss_defaults() synchronize];
        }
        else
        {
            NSLog(@"Spend Stack - WARNING: Location is not inside the United States (%@)", placeMark.country);
        }
        
        NSLog(@"Spend Stack - Retrieved location: %@", self.recentLocationFormattedTitle);
        [manager stopUpdatingLocation];
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_LOCATION_CHANGED object:self.recentLocationFormattedTitle];
        if (self.onLocationFetched) self.onLocationFetched();
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Spend Stack - Location manager failed: %@", error.localizedDescription);
}

#pragma mark - Misc

- (void)triggerLocationUpdate
{
    if (self.locationServicesEnabled == NO) return;
    [self.locationManager requestLocation];
}

- (BOOL)locationServicesEnabled
{
    if ([CLLocationManager locationServicesEnabled])
    {
        CLAuthorizationStatus status;
        
        if (@available(iOS 14.0, *)) {
            status = self.locationManager.authorizationStatus;
        } else {
            status = [CLLocationManager authorizationStatus];
        }
        
        switch (status)
        {
            case kCLAuthorizationStatusNotDetermined:
                return NO;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                return YES;
            default:
                return NO;
        }
    }
    else
    {
        return NO;
    }
}

@end
