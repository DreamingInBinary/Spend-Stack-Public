//
//  SSNavigationController.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/2/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSNavigationController.h"
#import "UIView+Animations.h"
#import "UITraitCollection+Utils.h"
#import "Spend_Stack_2-Swift.h"

@interface SSNavigationController () <UIPointerInteractionDelegate>

// If this is set, it overrides the non accessibility font attributes for the nav bar
@property (strong, nonatomic, nullable) NSDictionary *customTitleTextAttributes;
@property (copy) void (^ _Nullable onNavbarTap)(void);
@property (nonatomic, getter=doesPreferDyamicStyling) BOOL preferDynamicStyling;
@property (strong, nonatomic, nullable) SSLabel *tapLabel;

@end

@implementation SSNavigationController

#pragma mark - Overrides

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    if (self.onNavbarTap && self.navigationItem.titleView)
    {
        ((SSLabel *)self.navigationItem.titleView).text = title;
    }
}

#pragma mark - Initializer

- (instancetype)initForDynamicStlyingWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    
    if (self)
    {
        self.preferDynamicStyling = YES;
        [self commonInit];
    }
    
    return self;
}

#pragma mark - View Lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    [self configureStyling];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Lifecycle

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if ([self.traitCollection isDifferentThanTraitCollection:previousTraitCollection])
    {
        [self configureStyling];
    }
}

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self configureStyling];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    // Hide hairline
    [self setHairlineVisibility:YES];
}

- (void)configureStyling
{
    UINavigationBarAppearance *navBarAppearance = [UINavigationBarAppearance new];
    [navBarAppearance configureWithOpaqueBackground];
    
    if (self.doesPreferDyamicStyling)
    {
        UIColor *fill = [UIColor colorMDVCompact];
        if (self.viewControllers.firstObject.view)
        {
            fill = self.viewControllers.firstObject.view.backgroundColor;
        }
        navBarAppearance.backgroundColor = fill;
    }
    else
    {
        UIColor *fill = [UIColor systemBackgroundColor];
        navBarAppearance.backgroundColor = fill;
    }

    CGFloat newFontWeight = [SSCitizenship accessibilityFontsEnabled] ? UIFontWeightHeavy : UIFontWeightRegular;
    navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor ssMainFontColor],
                                                                  NSFontAttributeName:[UIFont systemFontOfSize:17 weight:newFontWeight]
                                                                 };
    if (self.customTitleTextAttributes) navBarAppearance.titleTextAttributes = self.customTitleTextAttributes;

    self.navigationBar.standardAppearance = navBarAppearance;
    self.navigationBar.compactAppearance = navBarAppearance;
    self.navigationBar.scrollEdgeAppearance = navBarAppearance;
}

#pragma mark - Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.preferBlackStatusBar ? UIStatusBarStyleDarkContent : UIStatusBarStyleDefault;
}

#pragma mark - Public Methods

- (void)setHairlineVisibility:(BOOL)shouldHide
{
    // Hide hairline
    UIView *hairline = [self findHairlineImage:self.navigationBar];
    hairline.hidden = shouldHide;
}

- (UIImageView *)findHairlineImage:(UIView *)view
{
    if ([view isKindOfClass:[UIImageView class]])
    {
        if (view.bounds.size.height <= 1)
        {
            return (UIImageView *)view;
        }
    }
    
    for (UIView *subview in view.subviews)
    {
        UIImageView *vw = [self findHairlineImage:subview];
        if (vw) return vw;
    }
    
    return nil;
}

- (void)styleNavigationBarAsPlainWhiteWithBoldText
{
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil]];
    
    self.customTitleTextAttributes = @{NSForegroundColorAttributeName:[UIColor ssMainFontColor],NSFontAttributeName:[UIFont systemFontOfSize:17 weight:UIFontWeightBold]};
    [self configureStyling];
}

- (void)addTappableNavbarLabel:(UIViewController *)sender onTap:(void (^)(void))onTap
{
    self.onNavbarTap = onTap;
    
    self.tapLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
    self.tapLabel.text = self.title;
    self.tapLabel.numberOfLines = 1;
    self.tapLabel.userInteractionEnabled = YES;
    self.tapLabel.isAccessibilityElement = NO;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(performOnNavbarTap:)];
    [self.tapLabel addGestureRecognizer:tap];
    [self addPointerInteraction];
    
    sender.navigationItem.titleView = self.tapLabel;
}
#pragma mark - Cursor

- (void)addPointerInteraction API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self.tapLabel addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.tapLabel parameters:[self previewParametersForTitleLabel]];
    
    UIPointerHoverEffect *hover = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    hover.prefersScaledContent = NO;
    
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

- (UIPreviewParameters *)previewParametersForTitleLabel
{
    CGRect contentRect = CGRectInset(self.tapLabel.bounds, -8, -8);
    UIPreviewParameters *params = [UIPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return params;
}


#pragma mark - Private Methods

- (void)performOnNavbarTap:(UITapGestureRecognizer *)sender
{
    __weak typeof(self) weakSelf = self;
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    [sender.view dimInFromTapAnimationWithHighlight:SSSpacingMargin];
    sender.view.onAnimationFinished = ^{
        weakSelf.onNavbarTap();
    };
}

@end
