//
//  SSAboutViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 12/29/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSAboutViewController.h"
#import "TwitterLinkOpener.h"
#import "UIView+Animations.h"

static const NSInteger SS_APP_ICON_SIZE = 60;

@interface SSAboutViewController () <UIPointerInteractionDelegate>

@end

@implementation SSAboutViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = ss_Localized(@"about.vc.title");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissController)];
    
    self.scrollView = [UIScrollView new];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.scrollView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    UIImageView *appIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppIconDisplay"]];
    appIconImageView.backgroundColor = [UIColor ssPrimaryColor];
    appIconImageView.layer.cornerRadius = 8;
    appIconImageView.clipsToBounds = YES;
    appIconImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    SSLabel *versionLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    [versionLabel configureFontWeight:UIFontWeightMedium];
    versionLabel.text = [ss_Localized(@"about.vc.version") stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    versionLabel.textAlignment = NSTextAlignmentCenter;

    SSLabel *buildLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCallout];
    [buildLabel configureFontWeight:UIFontWeightMedium];
    buildLabel.textColor = [UIColor ssSecondaryColor];
    buildLabel.text = [ss_Localized(@"about.vc.build") stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey]];
    buildLabel.textAlignment = NSTextAlignmentCenter;
    
    SSLabel *narcassisticLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCallout];
    [narcassisticLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [narcassisticLabel configureFontWeight:UIFontWeightMedium];
    narcassisticLabel.textColor = [UIColor ssSecondaryColor];
    narcassisticLabel.text = ss_Localized(@"about.vc.design");
    narcassisticLabel.textAlignment = NSTextAlignmentCenter;
    [self addPointerInteraction:narcassisticLabel];
    
//    NSMutableAttributedString *narcissisticText = [[NSMutableAttributedString alloc] initWithString:narcassisticLabel.text];
//    NSRange nameRange = [narcissisticText.string rangeOfString:@"Dreaming In Binary LLC"];
//    [narcissisticText addAttributes:@{NSForegroundColorAttributeName:[UIColor ssPrimaryColor]} range:NSMakeRange(nameRange.location, nameRange.length)];
//    //narcassisticLabel.attributedText = narcissisticText;
//    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openTwitter:)];
//    narcassisticLabel.userInteractionEnabled = YES;
//    //[narcassisticLabel addGestureRecognizer:tap];
    
    [self.scrollView addSubviews:@[appIconImageView, versionLabel, buildLabel, narcassisticLabel]];
    
    [appIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@(SS_APP_ICON_SIZE));
        make.top.equalTo(self.scrollView.mas_top).with.offset(SSSpacingJumboMargin);
        make.centerX.equalTo(self.view.mas_centerX);
    }];
    
    [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(appIconImageView.mas_bottom).with.offset(SSSpacingJumboMargin);
        make.left.equalTo(self.view.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.view.mas_right).with.offset(SSRightBigElementMargin);
    }];
    
    [buildLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(versionLabel.mas_bottom).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.view.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.view.mas_right).with.offset(SSRightBigElementMargin);
    }];
    
    [narcassisticLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(buildLabel.mas_bottom).with.offset(SSTopBigElementMargin);
        make.left.equalTo(self.view.mas_left).with.offset(SSLeftBigElementMargin);
        make.right.equalTo(self.view.mas_right).with.offset(SSRightBigElementMargin);
        make.bottom.equalTo(self.scrollView.mas_bottom).with.offset(SSBottomBigElementMargin);
    }];
}

#pragma mark - Open Twitter

- (void)openTwitter:(UITapGestureRecognizer *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    sender.view.onAnimationFinished = ^{
        [TwitterLinkOpener openJordansTwitter];
    };
    
    [sender.view dimInFromTapAnimationWithHighlightCenteringToParent:SSSpacingBigMargin];
}

#pragma mark - Cursor

- (void)addPointerInteraction:(UIView *)view API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [view addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UIPreviewParameters *params = [(SSLabel *)interaction.view paremetersHuggingText];
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:interaction.view
                                                                      parameters:params];
    
    UIPointerHoverEffect *hover = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}


@end
