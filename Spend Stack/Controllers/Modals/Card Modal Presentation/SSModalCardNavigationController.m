//
//  ModalCardNavigationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/16/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSModalCardNavigationController.h"
#import "ModalCardTransitioningDelegate.h"

@interface SSModalCardNavigationController () <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull) ModalCardTransitioningDelegate *customTransitionDelegate;
@property (weak, nonatomic, nullable) UIView *cursorInteractionView;

@end

@implementation SSModalCardNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    
    if (self)
    {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            self.modalPresentationStyle = UIModalPresentationAutomatic;
            self.preferBlackStatusBar = NO;
        }
        else
        {
            self.customTransitionDelegate = [ModalCardTransitioningDelegate new];
            self.modalPresentationStyle = UIModalPresentationCustom;
            self.transitioningDelegate = self.customTransitionDelegate;
            self.view.clipsToBounds = YES;
            self.view.layer.cornerRadius = 17.0f;
        }
    
        // Fixes the bug where setting the navbar as non translucent would mess up with the table view insets
        UIView *dummyView = [UIView new];
        dummyView.backgroundColor = [UIColor systemBackgroundColor];
        dummyView.userInteractionEnabled = NO;
        [self.view insertSubview:dummyView belowSubview:self.navigationBar];
        [dummyView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(self.navigationBar.ss_height));
            make.top.equalTo(@0);
            make.left.and.right.equalTo(self.view);
        }];
    }
    
    return self;
}

- (BOOL)modalPresentationCapturesStatusBarAppearance
{
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return self.preferBlackStatusBar ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
}

#pragma mark - Public Methods

- (void)resetCornerRadius
{
    self.view.clipsToBounds = NO;
    self.view.layer.cornerRadius = 0.0f;
}

- (void)prepareForDownChevron:(SEL)selector
{
    if ([SSCitizenship voiceOverOn] == NO)
    {
        UIImage *down = [[UIImage systemImageNamed:@"chevron.compact.down" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:30 weight:UIImageSymbolWeightMedium]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *downChevron = [[UIImageView alloc] initWithImage:down];
        downChevron.tintColor = [UIColor ssSecondaryColor];
        
        __kindof SSBaseViewController *sender = self.childViewControllers.firstObject;
        sender.navigationItem.titleView = downChevron;
        self.cursorInteractionView = sender.navigationItem.titleView;
        
        downChevron.userInteractionEnabled = YES;
        [downChevron addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:sender action:selector]];
        [self addHighlightInteraction];
    }
    
    self.navigationBar.barTintColor = [UIColor systemBackgroundColor];
    self.navigationBar.backgroundColor = [UIColor systemBackgroundColor];
}

#pragma mark - Pointer Interaction

- (void)addHighlightInteraction API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self.cursorInteractionView addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.cursorInteractionView parameters:[self previewParametersForTitleView]];

    UIPointerHighlightEffect *highlight = [UIPointerHighlightEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:highlight
                                                             shape:nil];
    return pointerStyle;
}

- (UIPreviewParameters *)previewParametersForTitleView
{
    CGRect contentRect = CGRectInset(self.cursorInteractionView.bounds, -8, -8);
    UIPreviewParameters *params = [UIPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return params;
}

@end
