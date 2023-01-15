//
//  SSTaxPermissionsViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSTaxPermissionsViewController.h"
#import "SSFindTaxRateViewController.h"
#import "SSAddListViewController.h"
#import "SSListSettingsViewController.h"
#import "LocationUtil.h"

@interface SSTaxPermissionsViewController ()

@property (strong, nonatomic, nonnull) SSLabel *taxPromptLabel;
@property (strong, nonatomic, nonnull) __kindof UIView *effectView;
@property (strong, nonatomic, nonnull) UIStackView *contentStackView;
@property (strong, nonatomic, nonnull) SSButton *denyPermissionButton;

@end

@implementation SSTaxPermissionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.effectView = [SSCitizenship transparentViewIfPossible];
    self.effectView.mas_key = @"EffectView";
    
    self.taxPromptLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.taxPromptLabel.text = ss_Localized(@"taxPerm.main");
    self.taxPromptLabel.textAlignment = NSTextAlignmentCenter;
    self.taxPromptLabel.adjustsFontSizeToFitWidth = YES;
    self.taxPromptLabel.mas_key = @"TaxPromptLabel";
    [self.taxPromptLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    
    UIImage *locationIcon = [[UIImage systemImageNamed:@"mappin.and.ellipse" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:33]]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:locationIcon];
    iconImageView.tintColor = [UIColor ssPrimaryColor];
    [iconImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    iconImageView.mas_key = @"IconImageView";
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    SSButton *grantPermissionButton = [[SSButton alloc] initWithText:ss_Localized(@"taxPerm.grant")];
    [grantPermissionButton addTarget:self action:@selector(didGrantPermissions:) forControlEvents:UIControlEventTouchUpInside];
    grantPermissionButton.mas_key = @"GrantPermissionView";
    
    self.denyPermissionButton = [[SSButton alloc] initWithLabelStyle:ss_Localized(@"general.noThanks")];
    self.denyPermissionButton.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    [self.denyPermissionButton addTarget:self action:@selector(didDenyPermissions:) forControlEvents:UIControlEventTouchUpInside];
    self.denyPermissionButton.mas_key = @"DenyPermissionButton";
    
    self.contentStackView = [UIStackView new];
    self.contentStackView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStackView.axis = UILayoutConstraintAxisVertical;
    self.contentStackView.alignment = UIStackViewAlignmentCenter;
    self.contentStackView.spacing = SSSpacingJumboMargin;
    self.contentStackView.distribution = UIStackViewDistributionEqualSpacing;
    [self.contentStackView addArrangedSubview:self.taxPromptLabel];
    [self.contentStackView addArrangedSubview:iconImageView];
    [self.contentStackView addArrangedSubview:grantPermissionButton];
    self.contentStackView.mas_key = @"ContentStackView";
    
    [self.view addSubview:self.contentStackView];
    [self.view addSubview:self.denyPermissionButton];
    [self.view addSubview:self.effectView];
    
    [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.contentStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(SSTopJumboElementMargin);
        make.width.equalTo(self.view).multipliedBy(0.84f);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.denyPermissionButton.mas_top).with.offset(SSBottomBigElementMargin);
    }];

    [self.denyPermissionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.and.height.equalTo(self.denyPermissionButton);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
        [SSCitizenship setViewFadeOutAnimation:self.effectView];
        self.contentStackView.transform = CGAffineTransformIdentity;
        self.denyPermissionButton.transform = CGAffineTransformIdentity;
    } completion:^(BOOL done) {
        [self.effectView removeFromSuperview];
        
        [LocationUtil sharedInstance].onPermissionGranted = ^ {
            __kindof SSBaseViewController *rootVC = self.navigationController.viewControllers.firstObject;
            NSAssert([rootVC isKindOfClass:[SSAddListViewController class]] || [rootVC isKindOfClass:[SSListSettingsViewController class]], @"Unexpected view controller (%@), expected SSAddListViewController.", rootVC);
            
            SSTaxRateInfo *listTaxInfoToEdit;
            
            if ([rootVC isKindOfClass:[SSAddListViewController class]])
            {
                SSAddListViewController *addListVC = (SSAddListViewController *)self.navigationController.viewControllers.firstObject;
                listTaxInfoToEdit = addListVC.workingList.taxInfo;
            }
            else if ([rootVC isKindOfClass:[SSListSettingsViewController class]])
            {
                SSListSettingsViewController *listSettingsVC = (SSListSettingsViewController *)self.navigationController.viewControllers.firstObject;
                listTaxInfoToEdit = listSettingsVC.list.taxInfo;
            }
            
            SSFindTaxRateViewController *findTaxRateVC = [[SSFindTaxRateViewController alloc] initWithTaxInfo:listTaxInfoToEdit];
            NSMutableArray *currentNavStack = self.navigationController.viewControllers.mutableCopy;
            [currentNavStack replaceObjectAtIndex:currentNavStack.count - 1 withObject:findTaxRateVC];
            [self.navigationController setViewControllers:currentNavStack animated:YES];
        };
        
        [LocationUtil sharedInstance].onPermissionNeeded = ^ (CLAuthorizationStatus authStatus) {
            UIAlertAction *openSettingsActions = [UIAlertAction actionWithTitle:ss_Localized(@"general.openSettings") style:UIAlertActionStyleDefault handler:^ (UIAlertAction *handler) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{@"":@""} completionHandler:nil];
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:ss_Localized(@"general.noThanks") style:UIAlertActionStyleCancel handler:nil];
            
            NSString *device = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? ss_Localized(@"general.iPhone.possessive") : ss_Localized(@"general.iPad.possessive");
            NSString *errorMessage = [NSString stringWithFormat:ss_Localized(@"taxPerm.steps"), device];
            [self showAlertControllerWithTitle:ss_Localized(@"taxPerm.disabled") message:errorMessage actions:@[openSettingsActions, cancelAction]];
        };
    }];
}

#pragma mark - Misc

- (void)didGrantPermissions:(SSButton *)sender
{
    [[LocationUtil sharedInstance] requestPermissions];
}

- (void)didDenyPermissions:(SSButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
