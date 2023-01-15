//
//  SSNoConnectionViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/22/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSNoConnectionViewController.h"

@interface SSNoConnectionViewController ()

@property (strong, nonatomic, nonnull) SSLabel *mediaromptLabel;
@property (strong, nonatomic, nonnull) __kindof UIView *effectView;
@property (strong, nonatomic, nonnull) UIStackView *contentStackView;

@end

@implementation SSNoConnectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Connection Unavailable";
    self.effectView = [SSCitizenship transparentViewIfPossible];
    self.effectView.mas_key = @"EffectView";
    
    self.mediaromptLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.mediaromptLabel.text = @"Please try this once again when you're back on WiFi or have a cellular connection.";
    self.mediaromptLabel.textAlignment = NSTextAlignmentCenter;
    self.mediaromptLabel.adjustsFontSizeToFitWidth = YES;
    self.mediaromptLabel.mas_key = @"MediaPromptLabel";
    [self.mediaromptLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    
    UIImage *cameraIcon = [[UIImage systemImageNamed:@"wifi.slash" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:38]]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:cameraIcon];
    [iconImageView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    iconImageView.tintColor = [UIColor ssPrimaryColor];
    iconImageView.mas_key = @"IconImageView";
    
    SSButton *grantPermissionButton = [[SSButton alloc] initWithText:@"Ok"];
    [grantPermissionButton addTarget:self action:@selector(dismissController) forControlEvents:UIControlEventTouchUpInside];
    grantPermissionButton.mas_key = @"GrantPermissionView";
    
    self.contentStackView = [UIStackView new];
    self.contentStackView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStackView.axis = UILayoutConstraintAxisVertical;
    self.contentStackView.alignment = UIStackViewAlignmentCenter;
    self.contentStackView.spacing = SSSpacingJumboMargin;
    self.contentStackView.distribution = UIStackViewDistributionEqualCentering;
    [self.contentStackView addArrangedSubview:iconImageView];
    [self.contentStackView addArrangedSubview:self.mediaromptLabel];
    [self.contentStackView addArrangedSubview:grantPermissionButton];
    self.contentStackView.mas_key = @"ContentStackView";
    
    [self.view addSubview:self.contentStackView];
    [self.view addSubview:self.effectView];
    
    [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.contentStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view).multipliedBy(0.84f);
        make.height.equalTo(self.contentStackView.mas_height);
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.equalTo(self.view.mas_centerY);
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
        [SSCitizenship setViewFadeOutAnimation:self.effectView];
        self.contentStackView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL done) {
        [self.effectView removeFromSuperview];
    }];
}

@end
