//
//  SSBetaExpiredViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 4/24/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

#import "SSBetaExpiredViewController.h"
#import "SSFirstRunViewController.h"
#import "SSConstants.h"
#import "SSVerticalViewCell.h"
#import "SSFirstRunTransitioningDelegate.h"
#import "UIView+Animations.h"
#import "NSLocale+Utils.h"
#import "TaxRateDataLoader.h"

static const NSInteger SS_APP_ICON_SIZE = 66;

@interface SSBetaExpiredViewController ()

@property (strong, nonatomic, nonnull) SSFirstRunTransitioningDelegate *customTransitionDelegate;
@property (strong, nonatomic, nonnull) UILabel *headerLabel;
@property (strong, nonatomic, nonnull) UILabel *demoLabel;
@property (strong, nonatomic, nonnull) UIImageView *iconImageView;
@property (strong, nonatomic, nonnull) SSButton *continueButton;

@end

@implementation SSBetaExpiredViewController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.customTransitionDelegate = [SSFirstRunTransitioningDelegate new];
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self.customTransitionDelegate;
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppIconDisplay"]];
    [self.iconImageView notchifyCornerRadius];
    self.iconImageView.backgroundColor = [UIColor ssPrimaryColor];
    self.iconImageView.layer.cornerRadius = 10;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.headerLabel = [UILabel new];
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.attributedText = [self headerTextForViewWidth];
    
    self.demoLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.demoLabel.text = ss_Localized(@"betaExpired.detail");
    self.demoLabel.textAlignment = NSTextAlignmentNatural;
    
    self.continueButton = [[SSButton alloc] initWithText:ss_Localized(@"betaExpired.download")];
    [self.continueButton addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    

    [self.view addSubviews:@[self.iconImageView,
                             self.headerLabel,
                             self.demoLabel,
                             self.continueButton]];
        
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@(SS_APP_ICON_SIZE));
        make.leading.equalTo(self.headerLabel.mas_leading);
        make.bottom.equalTo(self.headerLabel.mas_top).with.offset(SSBottomBigElementMargin);
    }];
    
    [self.headerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.demoLabel.mas_top).with.offset(SSBottomJumboElementMargin);
        make.leading.equalTo(self.demoLabel.mas_leading);
        make.height.equalTo(self.headerLabel.mas_height);
    }];
    
    [self.demoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width).multipliedBy(self.isiPad ? 0.50f : 0.74);
        make.centerY.equalTo(self.view.mas_centerY);
        make.centerX.equalTo(self.view.mas_centerX);
    }];

    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.demoLabel.mas_bottom).with.offset(SSSpacingJumboMargin);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.equalTo(self.demoLabel.mas_width);
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // We made the root's alpha 0.0f to avoid a flicker presenting this
    self.view.window.rootViewController.view.alpha = 1.0f;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.headerLabel.attributedText = [self headerTextForViewWidth];
}

#pragma mark - Utils

- (NSAttributedString *)headerTextForViewWidth
{
    NSString *headerText = [self.view isLandscape] ? ss_Localized(@"betaExpired.headerText") : ss_Localized(@"betaExpired.headerText2");

    NSMutableAttributedString *headerAttributedText = [[NSMutableAttributedString alloc] initWithString:headerText];
    UIFont *headerFont = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle].pointSize + 2 weight:UIFontWeightHeavy];
    UIColor *headerFontBlackColor = [UIColor ssMainFontColor];
    UIColor *headerFontBlueColor = [UIColor ssPrimaryColor];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentNatural;
    [headerAttributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, headerText.length)];
    [headerAttributedText addAttribute:NSFontAttributeName value:headerFont range:NSMakeRange(0, headerText.length)];
    
    NSRange spendStackRange = [headerText rangeOfString:ss_Localized(@"Spend Stack")];
    [headerAttributedText addAttribute:NSForegroundColorAttributeName value:headerFontBlackColor range:NSMakeRange(0, spendStackRange.location - 1)];
    [headerAttributedText addAttribute:NSForegroundColorAttributeName value:headerFontBlueColor range:NSMakeRange(spendStackRange.location, spendStackRange.length)];
    
    return headerAttributedText;
}

- (void)confirm
{
    NSString *spendStackAppStoreID = @"1329068268";
    NSURL *reviewURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", spendStackAppStoreID]];
    [[UIApplication sharedApplication] openURL:reviewURL options:@{} completionHandler:nil];
}

@end
