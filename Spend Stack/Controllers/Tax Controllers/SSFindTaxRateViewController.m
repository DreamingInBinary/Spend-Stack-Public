//
//  SSFindTaxRateViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 3/3/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSFindTaxRateViewController.h"
#import "SSEnterTaxRateViewController.h"
#import "SSAddListViewController.h"
#import "SSConstants.h"
#import "TaxRateDataLoader.h"
#import "SSDisplayPin.h"
#import "SSNoConnectionViewController.h"
#import "UIView+Animations.h"
#import "UIView+SSUtils.h"
#import "Spend_Stack_2-Swift.h"
#import <MapKit/MapKit.h>

static NSString * const MAP_ANNOTATION_ID = @"Location";
static const NSUInteger MAP_BLUR_TAG = (NSUInteger)(INTMAX_MAX - 1);
static const NSUInteger MAP_ACTIVITY_TAG = (NSUInteger)(INTMAX_MAX - 2);

@interface SSFindTaxRateViewController () <MKMapViewDelegate, UIPointerInteractionDelegate>

@property (weak, nonatomic, nullable) SSTaxRateInfo *taxInfo;
@property (strong, nonatomic, nonnull) SSLabel *mapTopLabel;
@property (strong, nonatomic, nonnull) MKMapView *mapView;
@property (strong, nonatomic, nonnull) SSLabel *taxRateAmountLabel;
@property (strong, nonatomic, nonnull) UIStackView *buttonsStackView;
@property (strong, nonatomic, nonnull) SSButton *confirmTaxRateButton;
@property (strong, nonatomic, nonnull) SSButton *denyTaxRateButton;

@end

@implementation SSFindTaxRateViewController

#pragma mark - Initializers

- (instancetype)initWithTaxInfo:(SSTaxRateInfo *)taxInfo
{
    self = [super init];
    
    if (self)
    {
        self.taxInfo = taxInfo;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = ss_Localized(@"findTax.vc.title");
    [[LocationUtil sharedInstance] triggerLocationUpdate];
    __weak SSFindTaxRateViewController *weakSelf = self;
    [LocationUtil sharedInstance].onLocationFetched = ^ {
        [weakSelf fetchTaxRate];
    };
    
    [SSCitizenship setViewAsTransparentIfPossible:self.view];
    
    self.scrollView = [UIScrollView new];
    self.scrollView.mas_key = @"Scrollview";
    [self.view addSubview:self.scrollView];
    
    self.mapTopLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.mapTopLabel.mas_key = @"MapTopLabel";
    [self.scrollView addSubview:self.mapTopLabel];
    
    self.mapView = [MKMapView new];
    self.mapView.clipsToBounds = YES;
    self.mapView.layer.cornerRadius = SSSpacingMargin;
    self.mapView.delegate = self;
    self.mapView.mas_key = @"MapView";
    [self.scrollView addSubview:self.mapView];
    
    self.buttonsStackView = [UIStackView new];
    self.buttonsStackView.axis = UILayoutConstraintAxisVertical;
    self.buttonsStackView.alignment = UIStackViewAlignmentCenter;
    self.buttonsStackView.distribution = UIStackViewDistributionEqualSpacing;
    self.buttonsStackView.mas_key = @"ButtonStackView";
    self.buttonsStackView.spacing = SSSpacingBigMargin;
    [self.scrollView addSubview:self.buttonsStackView];
    
    self.taxRateAmountLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.taxRateAmountLabel.mas_key = @"TaxRateAmountLabel";
    
    self.confirmTaxRateButton = [[SSButton alloc] initWithText:ss_Localized(@"findTax.vc.good")];
    [self.confirmTaxRateButton addTarget:self action:@selector(confirmTaxRate) forControlEvents:UIControlEventTouchUpInside];
    self.confirmTaxRateButton.mas_key = @"ConfirmTaxRateButton";
    
    self.denyTaxRateButton = [[SSButton alloc] initWithLabelStyle:ss_Localized(@"findTax.vc.manual")];
    [self.denyTaxRateButton addTarget:self action:@selector(enterTaxRateManually) forControlEvents:UIControlEventTouchUpInside];
    self.denyTaxRateButton.mas_key = @"DenyRaxRateButton";
    self.denyTaxRateButton.pointerInteractionEnabled = YES;
    
    [self.buttonsStackView addArrangedSubview:self.taxRateAmountLabel];
    [self.buttonsStackView addArrangedSubview:self.confirmTaxRateButton];
    [self.buttonsStackView addArrangedSubview:self.denyTaxRateButton];
    
    self.mapTopLabel.text = ss_Localized(@"findTax.vc.locating");
    
    // Sale-Tax acknowledgement
    SSLabel *taxSourceLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCallout];
    [taxSourceLabel configureFontWeight:UIFontWeightMedium];
    taxSourceLabel.textColor = [UIColor ssSecondaryColor];
    taxSourceLabel.text = ss_Localized(@"findTax.vc.credit");;
    taxSourceLabel.textAlignment = NSTextAlignmentCenter;
    
    NSRange linkRange = [taxSourceLabel.text rangeOfString:ss_Localized(@"findTax.vc.credit2")];
    NSMutableAttributedString *attributedTaxSourceText = [[NSMutableAttributedString alloc] initWithString:taxSourceLabel.text];
    [attributedTaxSourceText addAttributes:@{NSForegroundColorAttributeName:[UIColor ssPrimaryColor]} range:NSMakeRange(linkRange.location, linkRange.length)];
    taxSourceLabel.attributedText = attributedTaxSourceText;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openSaleTax:)];
    taxSourceLabel.userInteractionEnabled = YES;
    taxSourceLabel.accessibilityTraits = UIAccessibilityTraitButton;
    [taxSourceLabel addGestureRecognizer:tap];
    [taxSourceLabel addPointerInteractionWithDelegate:self];
    
    [self.view addSubview:taxSourceLabel];
    
    //Constraints
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_leftMargin);
        make.bottom.equalTo(taxSourceLabel.mas_top).with.offset(SSBottomElementMargin);
        make.right.equalTo(self.view.mas_rightMargin);
    }];
    
    [self.mapTopLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mapView.mas_left);
        make.right.equalTo(self.scrollView.mas_safeAreaLayoutGuideRight).with.offset(SSRightBigElementMargin);
        make.top.equalTo(self.scrollView.mas_top).with.offset(SSTopBigElementMargin);
    }];
    
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.scrollView.mas_width);
        make.top.equalTo(self.mapTopLabel.mas_bottom).with.offset(SSTopBigElementMargin);
        make.centerX.equalTo(self.scrollView.mas_centerX);
        make.height.equalTo(self.view.mas_height).multipliedBy(.25f);
    }];
    
    [self.buttonsStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.scrollView.mas_width);
        make.centerX.equalTo(self.scrollView.mas_centerX);
        make.top.equalTo(self.mapView.mas_bottom).with.offset(SSTopBigElementMargin);
        make.bottom.equalTo(self.scrollView.mas_bottom).with.offset(SSBottomBigElementMargin);
    }];
    
    [taxSourceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leadingMargin.equalTo(self.view.mas_leadingMargin);
        make.trailingMargin.equalTo(self.view.mas_trailingMargin);
        make.height.equalTo(taxSourceLabel.mas_height);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
    }];
    
    [self addBlurViewOverMapview];
    
    self.buttonsStackView.alpha = 0.0f;
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    SSLabel *label = (SSLabel *)interaction.view;
    
    UIPreviewParameters *params = [label paremetersHuggingText];
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:interaction.view parameters:params];
    
    UIPointerLiftEffect *hover = [UIPointerLiftEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

#pragma mark - Confirmation

- (void)confirmTaxRate
{
    if (self.onConfirmation)
    {
        [[DataStore new] updateWithList:self.editingList completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_REQUEST_RELOAD_LIST object:self.editingList.dbID];
            self.onConfirmation(self.taxInfo);
        }];
    }
    else
    {
        // Must have come from permissions view if the block isn't set
        NSMutableArray *currentNavStack = self.navigationController.viewControllers.mutableCopy;
        if (currentNavStack.count == 3) {
            // This might be an Xcode 12 beta bug, but the nav stack isn't removing the tax perms
            // VC before this is shown. Manually take it out :-/
            [currentNavStack removeObjectAtIndex:0];
            [self.navigationController setViewControllers:currentNavStack animated:NO];
        }
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - Data Fetch

- (void)fetchTaxRate
{
    [TaxRateDataLoader findLocaSalesTaxWithCompletion:^ (NSError *error, NSDecimalNumber *taxRate) {
        if (error == nil || error.code == SS_WARNING_TAX_LOADER_LOCATION_SAME_CODE)
        {
            [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSuccess];
            [self showTaxRateInfoSuccess:taxRate];
        }
        else
        {
            [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeError];
            NSLog(@"Spend Stack - Error getting location:%@", error.localizedDescription);
            [self showErrorOccurred];
        }
    }];
}

#pragma mark - UI Animations

- (void)showTaxRateInfoSuccess:(NSDecimalNumber *)taxRate
{
    self.taxInfo.taxRate = taxRate;
    self.taxInfo.localSalesTaxLocation = [LocationUtil sharedInstance].recentLocationFormattedTitle;
    self.taxInfo.taxEnabled = YES;
    
    [self addPointAnnotationFromLocation:[LocationUtil sharedInstance].recentLocation title:[LocationUtil sharedInstance].recentLocationFormattedTitle];
    [self removeBlurViewOverMapview];
    
    [UIView animateWithDuration:SSBriefAnimationDuration delay:0.0f options:UIViewAnimationOptionTransitionNone animations:^ {
        self.mapTopLabel.alpha = 0.0f;
    } completion: ^(BOOL done) {
        [UIView animateWithDuration:SSBriefAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
            self.mapTopLabel.alpha = 1.0f;
            self.buttonsStackView.alpha = 1.0f;
            self.mapTopLabel.text = [LocationUtil sharedInstance].recentLocationFormattedTitle;
            self.taxRateAmountLabel.text = [NSString stringWithFormat:ss_Localized(@"findTax.vc.found"), [[[TaxUtility alloc] initWithLocaleID:@"en_US"] displayTaxStringFromString:taxRate.stringValue]];
            self.confirmTaxRateButton.hidden = NO;
        } completion:nil];
    }];
}

- (void)showErrorOccurred
{
    if (self.connectionIsAvailable == NO)
    {
        SSNoConnectionViewController *connectionVC = [SSNoConnectionViewController new];
        [SSPopupModalPresentationController presentPresentationControllerFromController:self
                                                                    presentedController:connectionVC];
    }
    else
    {
        [self removeBlurViewOverMapview];
        
        [UIView animateWithDuration:SSBriefAnimationDuration delay:0.0f options:UIViewAnimationOptionTransitionNone animations:^ {
            self.mapTopLabel.alpha = 0.0f;
        } completion: ^(BOOL done) {
            self.mapTopLabel.text = ss_Localized(@"findTax.vc.error");
            self.taxRateAmountLabel.text = @"";
            self.confirmTaxRateButton.hidden = YES;
            [UIView animateWithDuration:SSBriefAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
                self.mapTopLabel.alpha = 1.0f;
                self.buttonsStackView.alpha = 1.0f;
            } completion:nil];
        }];
    }
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
        annotationView.canShowCallout = YES;
    }

    return annotationView;
}

- (void)addPointAnnotationFromLocation:(CLLocation *)location title:(NSString *)title;
{
    SSDisplayPin *annotation = [SSDisplayPin new];
    annotation.coordinate = location.coordinate;
    annotation.title = title;
    [self.mapView addAnnotation:annotation];
    [self.mapView setSelectedAnnotations:self.mapView.annotations];
    
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(location.coordinate, 800, 800)];
    adjustedRegion.span.longitudeDelta  = 0.05;
    adjustedRegion.span.latitudeDelta  = 0.05;
    [self.mapView setRegion:adjustedRegion animated:YES];
}

#pragma mark - Misc

- (void)addBlurViewOverMapview
{
    __kindof UIView *effectView = [SSCitizenship transparentViewIfPossible];
    effectView.tag = MAP_BLUR_TAG;
    effectView.userInteractionEnabled = NO;
    effectView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mapView addSubview:effectView];
    
    UIActivityIndicatorView *activityView = [UIActivityIndicatorView new];
    activityView.tag = MAP_ACTIVITY_TAG;
    activityView.translatesAutoresizingMaskIntoConstraints = NO;
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
    [activityView startAnimating];
    [self.mapView addSubview:activityView];
    
    [effectView anchorToEdgesWithoutLeadingTrailing:self.mapView];
    [activityView.centerXAnchor constraintEqualToAnchor:self.mapView .centerXAnchor].active = YES;
    [activityView.centerYAnchor constraintEqualToAnchor:self.mapView .centerYAnchor].active = YES;
}

- (void)removeBlurViewOverMapview
{
    [((UIActivityIndicatorView *)[self.mapView viewWithTag:MAP_ACTIVITY_TAG]) stopAnimating];
    [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
        [SSCitizenship setViewFadeOutAnimation:[self.mapView viewWithTag:MAP_BLUR_TAG]];
        ((UIActivityIndicatorView *)[self.mapView viewWithTag:MAP_ACTIVITY_TAG]).alpha = 0.0f;
    } completion:nil];
}

- (void)openSaleTax:(UITapGestureRecognizer *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    sender.view.onAnimationFinished = ^{
        NSURL *saleTaxURL = [NSURL URLWithString:@"http://www.Sale-Tax.com"];
        [[UIApplication sharedApplication] openURL:saleTaxURL options:@{} completionHandler:nil];
    };
    
    [sender.view dimInFromTapAnimationWithHighlight:SSSpacingMargin];
}

#pragma mark - Enter Manually

- (void)enterTaxRateManually
{
    SSEnterTaxRateViewController *enterTaxRateVC;
    NSMutableArray *currentNavStack = self.navigationController.viewControllers.mutableCopy;
    
    // If we're adding a list, let's keep the transparent background which is shown by default in the enterVC. Otherwise, keep it white.
    if ([currentNavStack.firstObject isKindOfClass:[SSAddListViewController class]])
    {
        enterTaxRateVC = [[SSEnterTaxRateViewController alloc] initWithTaxInfo:self.taxInfo];
    }
    else
    {
        enterTaxRateVC = [[SSEnterTaxRateViewController alloc] initWithTaxInfoAndWhiteBackground:self.taxInfo];
        enterTaxRateVC.editingList = self.editingList;
    }
    
    [currentNavStack replaceObjectAtIndex:currentNavStack.count - 1 withObject:enterTaxRateVC];
    [self.navigationController setViewControllers:currentNavStack animated:YES];
}

@end
