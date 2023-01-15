//
//  SSListItemCheckBox.m
//  Spend Stack
//
//  Created by Jordan Morgan on 5/31/19.
//  Copyright © 2019 Jordan Morgan. All rights reserved.
//

#import "SSListItemCheckBox.h"
#import "UIView+Animations.h"
#import "UIView+SSShimmer.h"

@interface SSListItemCheckBox() <UIPointerInteractionDelegate>

@property (strong, nonatomic, readwrite, nonnull) UIImageView *checkbox;
@property (strong, nonatomic, nonnull) UIImage *checkboxImage;
@property (nonatomic, readwrite, getter=isChecked) BOOL checked;

@end

@implementation SSListItemCheckBox

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.checkbox = [UIImageView new];
        self.checkbox.tintColor = [UIColor systemBackgroundColor];
        self.checkbox.contentMode = UIViewContentModeCenter;
        self.checkbox.userInteractionEnabled = NO;
        [self addSubview:self.checkbox];
        [self.checkbox mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo([SSCitizenship accessibilityFontsEnabled] ? @33 : @18);
            make.leading.equalTo(self.mas_leading).with.offset(SSLeftBigElementMargin).with.priorityHigh();
            make.centerY.equalTo(self.mas_centerY);
        }];
        
        [self.checkbox notchifyCornerRadius];
        self.checkbox.layer.cornerRadius = 6.0f;
        self.checkbox.backgroundColor = [UIColor systemBackgroundColor];
        self.checkbox.layer.borderWidth = 2.0f;
        
        CGFloat size = [SSCitizenship accessibilityFontsEnabled] ? 18 : 10;
        self.checkboxImage = [[[UIImage imageNamed:@"checkNoBackground"] imageScaledToSize:CGSizeMake(size, size)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [self toggleChecked:NO];

        // Debugging constraints
        self.checkbox.mas_key = @"checkboxImageView";
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [self addGestureRecognizer:tap];
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityLabel = @"Checkbox";
        self.accessibilityHint = @"Tap to toggle this item as checked off.";
        
        [self addPointerInteraction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Accessibility Sizing

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    CGFloat imageViewSize = self.isChecked ? ([SSCitizenship accessibilityFontsEnabled] ? 33 : 18) : 0;
    
    [self.checkbox mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@(imageViewSize));
        make.leading.equalTo(self.mas_leading).with.offset(SSLeftBigElementMargin);
        make.centerY.equalTo(self.mas_centerY);
    }];
    
    CGFloat size = [SSCitizenship accessibilityFontsEnabled] ? 18 : 10;
    self.checkboxImage = [[[UIImage imageNamed:@"checkNoBackground"] imageScaledToSize:CGSizeMake(size, size)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (self.isChecked) self.checkbox.image = self.checkboxImage;
}

#pragma mark - Public Methods

- (void)toggleChecked:(BOOL)checked
{
    self.accessibilityValue = checked ? ss_Localized(@"checkbox.checked") : ss_Localized(@"checkbox.unchecked");
    self.checked = checked;
    
    if (checked)
    {
        self.checkbox.image = self.checkboxImage;
        self.checkbox.backgroundColor = [UIColor ssPrimaryColor];
        self.checkbox.layer.borderColor = [UIColor ssPrimaryColor].CGColor;
    }
    else
    {
        self.checkbox.image = nil;
        self.checkbox.backgroundColor = [UIColor systemBackgroundColor];
        self.checkbox.layer.borderColor = [UIColor ssMutedColor].CGColor;
    }
}

- (void)setHightlightedSelected:(BOOL)highlightedOrSelected
{
    self.checkbox.backgroundColor = self.isChecked ? [UIColor ssPrimaryColor] : [UIColor systemBackgroundColor];
    self.checkbox.layer.borderColor = self.isChecked ? [UIColor ssPrimaryColor].CGColor : [UIColor ssMutedColor].CGColor;
}

#pragma mark - Private methods

- (void)handleTap
{
    if (self.isCheckHandlerEnabled == NO) return;
    
    self.checked = !self.checked;
    
    NSString *accessibilityNote = [NSString stringWithFormat:@"Item is %@", self.checked ? @"checked off." : @"unchecked."];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, accessibilityNote);
    
    if (self.onCheck) self.onCheck(self.isChecked);
    [self toggleChecked:self.checked];
    
    if (self.delegate == nil || self.checked == NO) return;
    
    // Haptics
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleHeavy];
    
    // Bobble and shimmer views
    NSArray <UIView *> *subviews = [self.delegate parentContentView].subviews;
    NSArray <UIView *> *subviewsToExludeShimmer = [self.delegate viewsToExcludeDuringCheckAnimation];
    for (UIView *view in subviews)
    {
        [view bobble];
        // Image views don't come back after shimmering, possible bug. Band aid for now.
        if ([subviewsToExludeShimmer containsObject:view] == NO &&
            [view isKindOfClass:[UIImageView class]] == NO) [view startShimmeringWithRepitions:1];
    }
    
    //Animate light view expanding
    __block UIView *selectedView = [[UIView alloc] initWithFrame:[self.delegate parentContentView].bounds];
    selectedView.ss_width = 0.0f;
    selectedView.backgroundColor = [UIColor ssPrimaryColor];
    selectedView.alpha = 0.0f;
    selectedView.userInteractionEnabled = NO;
    [selectedView notchifyCornerRadius];
    selectedView.layer.cornerRadius = 8.0f;
    [[self.delegate parentContentView] addSubview:selectedView];
    
    // Box around checkbox to expand
    __block UIView *expandView = [[UIView alloc] initWithFrame:CGRectZero];
    expandView.userInteractionEnabled = NO;
    expandView.backgroundColor = [UIColor ssPrimaryColor];
    expandView.alpha = 0.0f;
    [expandView notchifyCornerRadius];
    expandView.layer.cornerRadius = self.checkbox.layer.cornerRadius;
    [[self.delegate parentContentView] addSubview:expandView];
    [expandView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.height.and.width.equalTo(self.checkbox);
        // Offset due to the transform moving the checkbox's center
        CGFloat offset = [SSCitizenship accessibilityFontsEnabled] ? 3 : 1.25;
        make.centerX.equalTo(self.checkbox.mas_centerX).with.offset(offset);
    }];
    
    [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
        selectedView.frame = CGRectInset([self.delegate parentContentView].bounds, 6.0f, 2.0f);
        selectedView.alpha = 0.15f;
        expandView.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
        expandView.alpha = 0.25f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:SSFasterThanFastestAnimationDuration animations:^{
            selectedView.alpha = 0.05f;
            expandView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            if (finished)
            {
                [selectedView removeFromSuperview];
                [expandView removeFromSuperview];
                selectedView = nil;
                expandView = nil;
            }
        }];
    }];
}

#pragma mark - Cursor

- (void)addPointerInteraction API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.checkbox];

    UIPointerHighlightEffect *hover = [UIPointerHighlightEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

@end
