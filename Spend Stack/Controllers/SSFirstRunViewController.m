//
//  SSFirstRunViewController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSFirstRunViewController.h"
#import "SSConstants.h"
#import "SSVerticalViewCell.h"
#import "SSFirstRunTransitioningDelegate.h"
#import "UIView+Animations.h"
#import "NSLocale+Utils.h"

static const NSInteger SS_APP_ICON_SIZE = 66;

@interface SSFirstRunViewController ()

@property (strong, nonatomic, nonnull) SSFirstRunTransitioningDelegate *customTransitionDelegate;
@property (strong, nonatomic, nonnull) __kindof UIView *effectView;
@property (strong, nonatomic, nonnull) UIActivityIndicatorView *spinner;
@property (strong, nonatomic, nonnull) UILabel *headerLabel;
@property (strong, nonatomic, nonnull) UIImageView *iconImageView;
@property (strong, nonatomic, nonnull) UIStackView *geoStackView;
@property (strong, nonatomic, nonnull) UIStackView *costStackView;
@property (strong, nonatomic, nonnull) UIStackView *flexibilityStackView;
@property (strong, nonatomic, nonnull) SSButton *continueButton;
@property (nonatomic, getter=introAnimationIsFinished) BOOL introAnimationFinished;

@end

@implementation SSFirstRunViewController

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
    self.scrollView = [UIScrollView new];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.effectView = [SSCitizenship transparentViewIfPossible];
    self.effectView.mas_key = @"EffectView";
    
    self.iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AppIconDisplay"]];
    [self.iconImageView notchifyCornerRadius];
    self.iconImageView.backgroundColor = [UIColor ssPrimaryColor];
    self.iconImageView.layer.cornerRadius = 10;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.headerLabel = [UILabel new];
    self.headerLabel.numberOfLines = 0;
    self.headerLabel.attributedText = [self headerTextForViewWidth];
    
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle1];
    
    // Lists
    self.geoStackView = [self benefitsStackViewWithIcon:[UIImage systemImageNamed:@"doc.circle.fill" withConfiguration:symbolConfig] iconColor:[UIColor appleGreen] headerText:ss_Localized(@"firstRun.vc.flexibile") descriptionText:ss_Localized(@"firstRun.vc.share")];
    
    // To the penny
    self.costStackView = [self benefitsStackViewWithIcon:[UIImage systemImageNamed:@"dollarsign.circle.fill" withConfiguration:symbolConfig] iconColor:[UIColor appleDarkPurple] headerText:ss_Localized(@"firstRun.vc.accurate") descriptionText:ss_Localized(@"firstRun.vc.accurate2")];
    
    // Tags
    self.flexibilityStackView = [self benefitsStackViewWithIcon:[UIImage systemImageNamed:@"tag.circle.fill" withConfiguration:symbolConfig] iconColor:[UIColor appleBlue] headerText:ss_Localized(@"firstRun.vc.tags") descriptionText:ss_Localized(@"firstRun.vc.organize")];
    
    self.continueButton = [[SSButton alloc] initWithText:ss_Localized(@"general.continue")];
    [self.continueButton addTarget:self action:@selector(confirmFirstRun) forControlEvents:UIControlEventTouchUpInside];
    
    // Spinner
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    
    [self.view addSubviews:@[self.scrollView,
                             self.continueButton,
                             self.effectView]];
    
    [self.scrollView addSubviews:@[self.iconImageView,
                                   self.headerLabel,
                                   self.geoStackView,
                                   self.costStackView,
                                   self.flexibilityStackView]];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.continueButton.mas_top).with.offset(SSBottomBigElementMargin);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.width.lessThanOrEqualTo(@400).with.priorityHigh();
    }];
    
    [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@(SS_APP_ICON_SIZE));
        make.leading.equalTo(self.headerLabel.mas_leading);
        make.bottom.equalTo(self.headerLabel.mas_top).with.offset(SSBottomBigElementMargin);
    }];
    
    [self.headerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view.mas_centerY);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.lessThanOrEqualTo(self.scrollView.mas_width);
        make.height.equalTo(self.headerLabel.mas_height);
    }];
    
    // These all start offscreen
    CGFloat offscreenViewPadOffset = SSTopGiantElementMargin;
    [self.geoStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom).with.offset(offscreenViewPadOffset);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.height.equalTo(self.geoStackView.mas_height);
    }];
    
    offscreenViewPadOffset += offscreenViewPadOffset;
    
    [self.costStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom).with.offset(offscreenViewPadOffset);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.height.equalTo(self.costStackView.mas_height);
    }];
    
    offscreenViewPadOffset += offscreenViewPadOffset;
    
    [self.flexibilityStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom).with.offset(offscreenViewPadOffset);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.height.equalTo(self.flexibilityStackView.mas_height);
    }];
    
    offscreenViewPadOffset += offscreenViewPadOffset;

    [self.continueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom).with.offset(offscreenViewPadOffset);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.equalTo(self.headerLabel.mas_width);
    }];
    
    if ([SSCitizenship prefersReducedMotion] || [SSCitizenship voiceOverOn])
    {
        [SSCitizenship setViewFadeOutAnimation:self.effectView];
        [self positionSpinner:NO];
    }
    else
    {
        self.iconImageView.transform = CGAffineTransformMakeScale(0.7, 0.7);
        self.headerLabel.transform = CGAffineTransformMakeScale(0.7, 0.7);
        self.iconImageView.alpha = 0.5f;
        self.headerLabel.alpha = 0.5f;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    CGFloat randomCloudKitLoadDelay = arc4random_uniform(1.5f) + 1.0;
    
    if ([SSCitizenship prefersReducedMotion] || [SSCitizenship voiceOverOn])
    {
        [UIView animateWithDuration:SSBriefAnimationDuration delay:randomCloudKitLoadDelay + 2.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            // Now put everything in the right position
            [SSCitizenship setViewFadeInAnimation:self.effectView];
        } completion:^(BOOL finished) {
            if (finished)
            {
                // Now put everything in the final position
                [self.effectView removeFromSuperview];
                
                // We made the root's alpha 0.0f to avoid a flicker presenting this
                self.view.window.rootViewController.view.alpha = 1.0f;
                
                // Move up icon and header
                [self finalHeaderLabelConstraints];
                
                [self finalIconImageHeaderSpinnerAppearance:self.spinner];
                
                [self finalGeoStackViewConstaints];
                [self finalTagStackViewConstraints];
                [self finalCostStackViewConstraints];
                [self finalContinueButtonConstraints];
                
                self.introAnimationFinished = YES;
            }
        }];
    }
    else
    {
        [self positionSpinner:YES];
        [self performIntroductionAnimations:randomCloudKitLoadDelay spinner:self.spinner];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.headerLabel.attributedText = [self headerTextForViewWidth];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.viewLoaded == NO) return;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.introAnimationIsFinished)
        {
            [self.geoStackView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.headerLabel.mas_bottom).with.offset([self calculateTopStackViewOffset]);
            }];
            
            [self.flexibilityStackView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.scrollView.mas_bottom).with.offset(-[self calculateTopStackViewOffset]);
            }];
        }
    } completion:nil];
}

#pragma mark - Animations

- (void)positionSpinner:(BOOL)aboveEffectView
{
    if (aboveEffectView)
    {
        [self.view insertSubview:self.spinner aboveSubview:self.effectView];
    }
    else
    {
        [self.view insertSubview:self.spinner belowSubview:self.effectView];
    }
    
    
    [self.spinner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomJumboElementMargin);
    }];
    [self.spinner startAnimating];
}

- (NSArray *)finalGeoStackViewConstaints
{
    return [self.geoStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerLabel.mas_bottom).with.offset([self calculateTopStackViewOffset]);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.height.equalTo(self.geoStackView.mas_height);
    }];
}

- (NSArray *)finalTagStackViewConstraints
{
    return [self.costStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.geoStackView.mas_bottom).with.offset(SSTopJumboElementMargin);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.height.equalTo(self.costStackView.mas_height);
    }];
}

- (NSArray *)finalCostStackViewConstraints
{
    return [self.flexibilityStackView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.costStackView.mas_bottom).with.offset(SSTopJumboElementMargin);
        make.left.equalTo(self.view.mas_readableContentGuideLeft);
        make.right.equalTo(self.view.mas_readableContentGuideRight);
        make.bottom.equalTo(self.scrollView.mas_bottom).with.offset(-[self calculateTopStackViewOffset]);
    }];
}

- (NSArray *)finalContinueButtonConstraints
{
    return [self.continueButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(SSBottomBigElementMargin);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.equalTo(self.headerLabel.mas_width);
        make.height.greaterThanOrEqualTo(@44).with.priorityHigh();
    }];
}

- (void)finalHeaderLabelConstraints
{
    [self.headerLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView.mas_top).with.offset(SSTopBigElementMargin);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.lessThanOrEqualTo(self.scrollView.mas_width);
        make.height.equalTo(self.headerLabel.mas_height);
    }];
}

- (void)finalIconImageHeaderSpinnerAppearance:(UIActivityIndicatorView *)spinner
{
    self.continueButton.alpha = 1.0f;
    self.iconImageView.alpha = 0.0f;
    spinner.alpha = 0.0f;
}

- (void)performIntroductionAnimations:(CGFloat)randomCloudKitLoadDelay spinner:(UIActivityIndicatorView *)spinner
{
    [UIView animateWithDuration:SSFastAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
        [SSCitizenship setViewFadeOutAnimation:self.effectView];
        self.iconImageView.transform = CGAffineTransformIdentity;
        self.headerLabel.transform = CGAffineTransformIdentity;
        self.iconImageView.alpha = 1.0f;
        self.headerLabel.alpha = 1.0f;
    } completion:^(BOOL done) {
        [self.effectView removeFromSuperview];
        
        // We made the root's alpha 0.0f to avoid a flicker presenting this
        self.view.window.rootViewController.view.alpha = 1.0f;
        
        // Move up icon and header
        [self finalHeaderLabelConstraints];
        
        CGFloat firstAnimationDuration = 1.0f;
        [UIView animateWithDuration:firstAnimationDuration delay:randomCloudKitLoadDelay usingSpringWithDamping:0.8f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction animations:^{
            [self finalIconImageHeaderSpinnerAppearance:spinner];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (finished) [spinner removeFromSuperview];
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((randomCloudKitLoadDelay)* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Top stackview - middle stackview - bottom stackview - button
            CGFloat staggerViewDelay = 0.0f;
            CGFloat animationDuration = 1.0f;
            for(NSInteger count = 0; count < 4; count++)
            {
                if (count == 0)
                {
                    [self finalGeoStackViewConstaints];
                }
                else if (count == 1)
                {
                    [self finalTagStackViewConstraints];
                }
                else if (count == 2)
                {
                    [self finalCostStackViewConstraints];
                }
                else if (count == 3)
                {
                    [self finalContinueButtonConstraints];
                }
                
                [UIView animateWithDuration:animationDuration delay:staggerViewDelay usingSpringWithDamping:0.9f initialSpringVelocity:0.9f options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction animations:^{
                    [self.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                    if (count == 3) self.introAnimationFinished = YES;
                }];
                
                animationDuration += 0.35f;
            }
        });
    }];
}

#pragma mark - Utils

- (NSInteger)calculateTopStackViewOffset
{
    // Safe area + padding from button + button's size
    NSInteger scrollviewContentHeight = self.view.safeAreaLayoutGuide.layoutFrame.size.height - (SSTopBigElementMargin + self.continueButton.ss_height);
    NSInteger centerPoint = scrollviewContentHeight/2;
    NSInteger topStackViewY = centerPoint - self.geoStackView.ss_height - SSTopJumboElementMargin;
    
    // What's the difference between that Y, and the label's bottom
    NSInteger padding = topStackViewY - self.headerLabel.ss_height;
    if (self.isiPad == NO && [self.view isLandscape] && [SSCitizenship accessibilityFontsEnabled] == NO)
    {
        padding = SSTopBigElementMargin;
    }

    return padding > 0 ? padding : SSTopJumboElementMargin;
}

- (NSAttributedString *)headerTextForViewWidth
{
    NSString *headerText = [self.view isLandscape] ? ss_Localized(@"firstRun.vc.headerText") : ss_Localized(@"firstRun.vc.headerText2");
    NSMutableAttributedString *headerAttributedText = [[NSMutableAttributedString alloc] initWithString:headerText];
    UIFont *headerFont = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle].pointSize + 2 weight:UIFontWeightHeavy];
    UIColor *headerFontBlackColor = [UIColor ssMainFontColor];
    UIColor *headerFontBlueColor = [UIColor ssPrimaryColor];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentNatural;
    [headerAttributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, headerText.length)];
    [headerAttributedText addAttribute:NSFontAttributeName value:headerFont range:NSMakeRange(0, headerText.length)];
    
    NSRange spendStackRange = [headerText rangeOfString:@"Expense App"];
    [headerAttributedText addAttribute:NSForegroundColorAttributeName value:headerFontBlackColor range:NSMakeRange(0, spendStackRange.location - 1)];
    [headerAttributedText addAttribute:NSForegroundColorAttributeName value:headerFontBlueColor range:NSMakeRange(spendStackRange.location, spendStackRange.length)];
    
    return headerAttributedText;
}

- (UIStackView *)benefitsStackViewWithIcon:(UIImage *)icon iconColor:(UIColor *)iconColor headerText:(NSString *)headerText descriptionText:(NSString *)descriptionText
{
    SSHorizontalStackView *benefitsStackView = [SSHorizontalStackView new];
    [benefitsStackView setVerticalAlignment:UIStackViewAlignmentTop];
    benefitsStackView.spacing = SSSpacingBigMargin;
    
    icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:icon];
    iconImageView.isAccessibilityElement = NO;
    iconImageView.tintColor = iconColor;
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [iconImageView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                   forAxis:UILayoutConstraintAxisHorizontal];
    [benefitsStackView addArrangedSubview:iconImageView];
    
    SSLabel *headerLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    headerLabel.text = headerText;
    headerLabel.textColor = [UIColor labelColor];
    headerLabel.isAccessibilityElement = NO;
    [headerLabel configureFontWeight:UIFontWeightHeavy];
    
    SSLabel *descriptionLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    descriptionLabel.text = descriptionText;
    descriptionLabel.textColor = [UIColor labelColor];
    descriptionLabel.isAccessibilityElement = NO;
    [descriptionLabel configureFontWeight:UIFontWeightLight];
    
    UIStackView *labelsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[headerLabel, descriptionLabel]];
    labelsStackView.axis = UILayoutConstraintAxisVertical;
    labelsStackView.alignment = UIStackViewAlignmentLeading;
    labelsStackView.distribution = UIStackViewDistributionFill;
    labelsStackView.spacing = SSSpacingMargin;
    [benefitsStackView addArrangedSubview:labelsStackView];
    
    benefitsStackView.accessibilityLabel = [NSString stringWithFormat:@"%@%@", headerText, descriptionText];
    
    return benefitsStackView;
}

- (void)confirmFirstRun
{
    [self setUserDefaultsForFirstRun];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUserDefaultsForFirstRun
{
    NSUserDefaults *defaults = ss_defaults();
    [defaults setBool:YES forKey:SS_HAS_SEEN_FIRST_RUN];
    [defaults setBool:YES forKey:Show_List_Total];
    [defaults setBool:YES forKey:Show_Tag_Footers];
    [defaults setBool:[NSLocale isWholeNumberRegion] ? YES : NO forKey:Use_Whole_Numbers];
    [defaults synchronize];
}

@end
