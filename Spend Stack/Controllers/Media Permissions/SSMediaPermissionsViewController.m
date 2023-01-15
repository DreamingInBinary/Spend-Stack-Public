//
//  SSMediaPermissionsViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/25/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSMediaPermissionsViewController.h"

@interface SSMediaPermissionsViewController ()

@property (strong, nonatomic, nonnull) SSLabel *mediaromptLabel;
@property (strong, nonatomic, nonnull) __kindof UIView *effectView;
@property (strong, nonatomic, nonnull) UIStackView *contentStackView;
@property (strong, nonatomic, nonnull) SSButton *denyPermissionButton;

@end

@implementation SSMediaPermissionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.effectView = [SSCitizenship transparentViewIfPossible];
    self.effectView.mas_key = @"EffectView";
    
    self.mediaromptLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.mediaromptLabel.text = @"Spend Stack needs your permission to view your media. We'll only use whatever you choose to add and nothing else.\n\nIf that sounds good, please grant us permissions within settings.";
    self.mediaromptLabel.textAlignment = NSTextAlignmentCenter;
    self.mediaromptLabel.adjustsFontSizeToFitWidth = YES;
    self.mediaromptLabel.mas_key = @"MediaPromptLabel";
    [self.mediaromptLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];

    UIImage *cameraIcon = [[UIImage systemImageNamed:@"photo.fill.on.rectangle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:cameraIcon];
    [iconImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    iconImageView.tintColor = [UIColor ssPrimaryColor];
    iconImageView.mas_key = @"IconImageView";
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    SSButton *grantPermissionButton = [[SSButton alloc] initWithText:@"Grant Permission"];
    [grantPermissionButton addTarget:self action:@selector(didGrantPermissions:) forControlEvents:UIControlEventTouchUpInside];
    grantPermissionButton.mas_key = @"GrantPermissionView";
    
    self.denyPermissionButton = [[SSButton alloc] initWithLabelStyle:@"No Thanks"];
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
    [self.contentStackView addArrangedSubview:self.mediaromptLabel];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
        [SSCitizenship setViewFadeOutAnimation:self.effectView];
        self.contentStackView.transform = CGAffineTransformIdentity;
        self.denyPermissionButton.transform = CGAffineTransformIdentity;
    } completion:^(BOOL done) {
        [self.effectView removeFromSuperview];
    }];
}

#pragma mark - Misc

- (void)didGrantPermissions:(SSButton *)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{@"":@""} completionHandler:nil];
}

- (void)didDenyPermissions:(SSButton *)sender
{
    [self dismissController];
}

@end
