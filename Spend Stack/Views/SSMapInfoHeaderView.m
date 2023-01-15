//
//  SSMapInfoHeaderView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 8/7/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSMapInfoHeaderView.h"
#import "TaxRateDataLoader.h"
#import "UIView+SSShimmer.h"
#import "SSDisplayPin.h"
#import <MapKit/MapKit.h>

static NSString * const MAP_ANNOTATION_ID = @"Location";

@interface SSMapInfoHeaderView() <MKMapViewDelegate>

@property (strong, nonatomic, nonnull) MKMapView *mapView;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;
@property (strong, nonatomic, nonnull) SSLabel *label;
@property (strong, nonatomic, nonnull) SSLabel *secondaryLabel;
@property (strong, nonatomic, nullable) NSString *topLabelText; //We keep this around so if the animation cancels, we still have this set
@property (strong, nonatomic, nullable) NSString *bottomLabelText; //We keep this around so if the animation cancels, we still have this set
@property (nonatomic, readonly, getter=locationFetchIsEnabled) BOOL locationFetchEnabled;

@end

@implementation SSMapInfoHeaderView

#pragma mark - Custom Getters

- (BOOL)locationFetchIsEnabled
{
    return [LocationUtil sharedInstance].fetchedUserLocale != SSFetchedUserLocaleNotFound
    && [LocationUtil sharedInstance].locationServicesEnabled;
}

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.userInteractionEnabled = NO;

        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:@"en_US"];
        self.mapView = [[MKMapView alloc] initWithFrame:self.bounds];
        self.mapView.layer.cornerRadius = 33.0f;
        self.mapView.delegate = self;
        
        self.label = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleFootnote];
        [self.label configureFontWeight:UIFontWeightBold];
        self.label.textColor = [UIColor ssMainFontColor];
        self.label.textAlignment = NSTextAlignmentLeft;
        
        self.secondaryLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleFootnote];
        self.secondaryLabel.textColor = [UIColor ssTextPlaceholderColor];
        self.secondaryLabel.textAlignment = NSTextAlignmentLeft;
        
        [self addSubviews:@[self.mapView, self.label, self.secondaryLabel]];
        
        [self updateTaxRateForLocation];
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateTaxRateForLocation)
                                                     name:SS_LOCATION_CHANGED
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [NSLayoutConstraint deactivateConstraints:self.constraints];
    [self setConstraints];
}

- (void)setConstraints
{
    BOOL accessibilitySizesOn = [SSCitizenship accessibilityFontsEnabled];
    
    [self.mapView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_leftMargin).with.offset(SSLeftElementMargin);
        make.top.equalTo(self.mas_top).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.mas_bottom).with.offset(SSBottomBigElementMargin);
        make.width.and.height.equalTo(@66).with.priorityMedium();
    }];
    
    [self.label mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (accessibilitySizesOn)
        {
            make.left.equalTo(self.mapView.mas_left);
            make.top.equalTo(self.mapView.mas_bottom).with.offset(SSTopBigElementMargin);
        }
        else
        {
            make.left.equalTo(self.mapView.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.mapView.mas_top);
        }
        make.right.equalTo(self.mas_safeAreaLayoutGuideRight).with.offset(SSRightElementMargin);
    }];

    [self.secondaryLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (accessibilitySizesOn)
        {
            make.top.equalTo(self.label.mas_bottom).with.offset(SSTopBigElementMargin);
        }
        else
        {
            make.top.greaterThanOrEqualTo(self.label.mas_bottom);
            make.centerY.equalTo(self.mapView.mas_centerY).with.priorityMedium();
        }
        make.left.equalTo(self.label.mas_left);
        make.right.equalTo(self.label.mas_right);
    }];
}

#pragma mark - Map View

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[SSDisplayPin class]] == NO) return nil;
    
    MKPinAnnotationView *annotationView;
    if (annotationView == nil)
    {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MAP_ANNOTATION_ID];
        annotationView.pinTintColor = [UIColor ssPrimaryColor];
        annotationView.canShowCallout = NO;
        annotationView.transform = CGAffineTransformMakeScale(0.6, 0.6);
    }
    
    return annotationView;
}

- (void)addPointAnnotationFromCoordinate:(CLLocationCoordinate2D)location
{
    SSDisplayPin *annotation = [SSDisplayPin new];
    annotation.coordinate = location;

    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:annotation];
    [self.mapView setSelectedAnnotations:self.mapView.annotations];
    
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(location, 800, 800)];
    adjustedRegion.span.longitudeDelta  = 0.05;
    adjustedRegion.span.latitudeDelta  = 0.05;
    [self.mapView setRegion:adjustedRegion animated:YES];
}

#pragma mark - Location Changes

- (void)updateTaxRateForLocation
{
    if (self.locationFetchIsEnabled == NO)
    {
        // Anything in the cache? Show that
        self.topLabelText = [ss_defaults() objectForKey:SS_RECENT_LOCATION_FORMATTED_KEY];
        
        NSDecimalNumber *taxRate = [ss_defaults() objectForKey:SS_LAST_FETCHED_CITY_TAX_RATE_KEY];
        if (taxRate)
        {
            self.bottomLabelText = [NSString stringWithFormat:@"%@ local sales tax", [self.taxUtil displayTaxStringFromString:taxRate.stringValue]];
        }
        
        if (self.topLabelText == nil)
        {
            return;
        }
        
        self.label.text = self.topLabelText;
        self.secondaryLabel.text = self.bottomLabelText;
        
        CGFloat latitude = ((NSNumber *)[ss_defaults() objectForKey:SS_RECENT_LOCATION_LATITUDE_KEY]).floatValue;
        CGFloat longitude = ((NSNumber *)[ss_defaults() objectForKey:SS_RECENT_LOCATION_LONGITUDE_KEY]).floatValue;
        
        [self addPointAnnotationFromCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
        return;
    }

    // If we got the location but we're already showing it then back out
    NSString *lastFetchedLocation = [ss_defaults() objectForKey:SS_RECENT_LOCATION_FORMATTED_KEY];
    if ([self.label.text isEqualToString:lastFetchedLocation])
    {
        NSLog(@"Spend Stack - Not updating map header, the updated location is the same as what's showing.");
        [self setNeedsLayout];
        return;
    }

    [self addPointAnnotationFromCoordinate:[LocationUtil sharedInstance].recentLocation.coordinate];

    [TaxRateDataLoader findLocaSalesTaxWithCompletion:^(NSError * _Nullable error, NSDecimalNumber * _Nullable taxRate) {
        // Anything changed?
        if (error.code == SS_WARNING_TAX_LOADER_LOCATION_SAME_CODE)
        {
            self.topLabelText = [NSString stringWithFormat:@"%@, %@", [LocationUtil sharedInstance].recentCity, [LocationUtil sharedInstance].recentState];
            self.bottomLabelText = [NSString stringWithFormat:@"%@ local sales tax", [self.taxUtil displayTaxStringFromString:taxRate.stringValue]];
            
            self.label.text = self.topLabelText;
            self.secondaryLabel.text = self.bottomLabelText;
        }
        else
        {
            // Change data
            self.topLabelText = [NSString stringWithFormat:@"%@, %@", [LocationUtil sharedInstance].recentCity, [LocationUtil sharedInstance].recentState];
            self.bottomLabelText = [NSString stringWithFormat:@"%@ local sales tax", [self.taxUtil displayTaxStringFromString:taxRate.stringValue]];
            
            if ([self closestViewController].presentedViewController == nil)
            {
                [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
            }
            
            self.label.text = self.topLabelText;
            self.secondaryLabel.text = self.bottomLabelText;
            [self startShimmeringWithRepitions:1];
        }
    }];
}

#pragma mark - Public

- (CGFloat)estimatedHeightForMapHeaderInView:(UIView *)view
{
    if (self.locationFetchEnabled == NO)
    {
        BOOL hasCachedValues = [ss_defaults() objectForKey:SS_RECENT_LOCATION_FORMATTED_KEY] != nil;
        if (hasCachedValues == NO)
        {
            return 0;
        }
    }
    
    CGFloat mapHeightWidth = 66;
    CGFloat elementTopPadding = SSTopBigElementMargin;
    NSInteger textAvailableWidth = view.boundsWidth - (mapHeightWidth + (SSSpacingMargin * 2));
    
    CGFloat topLabelHeight = [self.label.text boundingRectWithWidth:textAvailableWidth
                                                               text:self.label.text
                                                               font:self.label.font].size.height;
    CGFloat bottomLabelHeight = [self.secondaryLabel.text boundingRectWithWidth:textAvailableWidth
                                                                           text:self.secondaryLabel.text
                                                                           font:self.secondaryLabel.font].size.height;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        return mapHeightWidth + elementTopPadding + topLabelHeight + elementTopPadding + bottomLabelHeight + SSSpacingJumboMargin;
    }
    else
    {
        // Little bit more thought here. Accessibility isn't on but you can still have largish fonts. Most of the time,
        // the map size is bigger but we need to check for which is bigger.
        CGFloat bothLabelSizes = topLabelHeight + bottomLabelHeight + SSSpacingJumboMargin;
        CGFloat mapSize = mapHeightWidth + SSSpacingJumboMargin;
        return mapSize > bothLabelSizes ? mapSize : bothLabelSizes;
    }
}

- (void)updateSizeWithView:(UIView *)view
{
    CGFloat width = view.boundsWidth;
    CGFloat height = [self estimatedHeightForMapHeaderInView:view];
    self.ss_size = CGSizeMake(width, height);
}

- (void)forceUpdateUI
{
    [self updateTaxRateForLocation];
    if (self.superview == nil) return;
    [self updateSizeWithView:self.superview];
    [self setNeedsDisplay];
    [self setNeedsLayout];
}


@end
