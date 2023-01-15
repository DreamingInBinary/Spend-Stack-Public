//
//  SSListTotalHeaderView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 1/8/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListTotalHeaderView.h"
#import "TaxUtility.h"
#import "SSConstants.h"
#import "SSCountingLabel.h"
#import "SSListBreakdownViewController.h"
#import "SSBottomNavigationViewController.h"
#import "UIView+Animations.h"
#import "UIImage+Utils.h"
#import "Spend_Stack_2-Swift.h"

@interface SSListTotalHeaderView() <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull) UIButton *pageLeft;
@property (strong, nonatomic, nonnull) UIButton *pageRight;
@property (strong, nonatomic, nonnull) SSLabel *displayTypeLabel;
@property (strong, nonatomic, nonnull) SSCountingLabel *listTotalLabel;
@property (strong, nonatomic, nonnull) UIView *bottomDividerView;
@property (strong, nonatomic, nonnull) TaxUtility *taxUtil;

@end

@implementation SSListTotalHeaderView

#pragma mark - Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.taxUtil = [[TaxUtility alloc] initWithLocaleID:nil];
        
        self.displayTypeLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleCaption1];
        self.displayTypeLabel.isAccessibilityElement = NO;
        [self.displayTypeLabel configureFontWeight:UIFontWeightSemibold];
        self.displayTypeLabel.textColor = [UIColor ssSecondaryColor];
        self.displayTypeLabel.text = ss_Localized(@"listHeader.allItems");
        
        self.listTotalLabel = [[SSCountingLabel alloc] initWithTextStyle:UIFontTextStyleTitle1];
        [self.listTotalLabel configureFontWeight:UIFontWeightBold];
        self.listTotalLabel.textAlignment = NSTextAlignmentCenter;
        self.listTotalLabel.method = SSLabelCountingMethodEaseOut;
        self.listTotalLabel.animationDuration = SSBriefAnimationDuration;
        self.listTotalLabel.text = @"";
        self.listTotalLabel.userInteractionEnabled = NO;
        [self.listTotalLabel configureFontWeight:UIFontWeightSemibold];
        
        __weak typeof(self) weakSelf = self;
        self.listTotalLabel.formatBlock = ^NSString * _Nullable(CGFloat value) {
            return [weakSelf.taxUtil guranteedCurrencyString:@(value).stringValue];
        };
        
        CGSize glyphSize = CGSizeMake(20, 20);
        
        self.pageLeft = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *imgLeft = [[[UIImage systemImageNamed:@"chevron.left.circle.fill"] imageScaledToSize:glyphSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *imgLeftHightlighted = [[[UIImage systemImageNamed:@"chevron.left.circle"] imageScaledToSize:glyphSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.pageLeft setImage:imgLeft forState:UIControlStateNormal];
        [self.pageLeft setImage:imgLeftHightlighted forState:UIControlStateHighlighted];
        [self.pageLeft addTarget:self action:@selector(displayTypePageLeft:) forControlEvents:UIControlEventTouchUpInside];
        self.pageLeft.tintColor = [UIColor systemGray3Color];
        
        self.pageRight = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *imgRight = [[[UIImage systemImageNamed:@"chevron.right.circle.fill"] imageScaledToSize:glyphSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *imgRightHightlighted = [[[UIImage systemImageNamed:@"chevron.right.circle"] imageScaledToSize:glyphSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.pageRight setImage:imgRight forState:UIControlStateNormal];
        [self.pageRight setImage:imgRightHightlighted forState:UIControlStateHighlighted];
        [self.pageRight addTarget:self action:@selector(displayTypePageRight:) forControlEvents:UIControlEventTouchUpInside];
        self.pageRight.tintColor = [UIColor systemGray3Color];
        
        self.bottomDividerView = [UIView new];
        self.bottomDividerView.layer.cornerRadius = 1.0f;
        self.bottomDividerView.userInteractionEnabled = NO;
        self.bottomDividerView.backgroundColor = [UIColor ssSecondaryColor];
        
        [self addSubviews:@[self.displayTypeLabel,
                            self.listTotalLabel,
                            self.pageLeft,
                            self.pageRight,
                            self.bottomDividerView]];
        
        UITapGestureRecognizer *tapToShowBreakDown = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBreakdownOnIphone:)];
        self.listTotalLabel.userInteractionEnabled = YES;
        self.listTotalLabel.accessibilityTraits = UIAccessibilityTraitButton;
        self.listTotalLabel.accessibilityHint = ss_Localized(@"listHeader.lbl.hint");
        [self.listTotalLabel addGestureRecognizer:tapToShowBreakDown];
        
        [self setConstraints];
        self.pageLeft.pointerInteractionEnabled = YES;
        self.pageRight.pointerInteractionEnabled = YES;
        [self addPointerInteraction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Display Type Toggle

- (void)displayTypePageLeft:(UIButton *)sender
{
    [self commitNewListDisplayType:[self nextTotalDisplayType:NO]];
}

- (void)displayTypePageRight:(UIButton *)sender
{
    [self commitNewListDisplayType:[self nextTotalDisplayType:YES]];
}

- (ListTotalDisplayType)nextTotalDisplayType:(BOOL)pageRight
{
    ListTotalDisplayType type;
    switch (self.list.totalDisplayType)
    {
        case ListTotalDisplayAll:
            if (pageRight) type = ListTotalDisplayOnlyChecked;
            if (!pageRight) type = ListTotalDisplayOnlyUnchecked;
            break;
        case ListTotalDisplayOnlyChecked:
            if (pageRight) type = ListTotalDisplayOnlyUnchecked;
            if (!pageRight) type = ListTotalDisplayAll;
            break;
        case ListTotalDisplayOnlyUnchecked:
            if (pageRight) type = ListTotalDisplayAll;
            if (!pageRight) type = ListTotalDisplayOnlyChecked;
            break;
        default:
            type = ListTotalDisplayAll;
            break;
    }
    
    return type;
}

- (void)commitNewListDisplayType:(ListTotalDisplayType)type
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeSelectionChanged];
    self.list.totalDisplayType = type;
    [self refreshListUIWithDisplayOption:type
                        currentTotalCost:[self.list calcTotalCostFromDisplayType]
                         preferAnimation:YES];
    
    // Debounce it
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.list.totalDisplayType == type)
        {
            [[DataStore new] updateWithList:self.list completion:^{
                
            }];
        }
    });
}

#pragma mark - Frame Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
    if (self.superview) [self updateSizeWithView:self.superview];
}

- (void)setConstraints
{
    BOOL showingCheckboxes = self.list.isShowingCheckboxes;
    [self.displayTypeLabel sizeToFit];
    [self.listTotalLabel sizeToFit];
    
    [self.displayTypeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.displayTypeLabel.mas_width);
        make.centerX.equalTo(self.mas_centerX);
        
        if (showingCheckboxes)
        {
            make.height.equalTo(self.displayTypeLabel.mas_height);
            make.top.equalTo(self.mas_top).with.offset(SSTopElementMargin);
        }
        else
        {
            make.height.equalTo(@0);
            make.top.equalTo(self.mas_top);
        }
    }];
    
    [self.listTotalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.displayTypeLabel.mas_bottom).with.offset(SSTopElementMargin);
        make.width.equalTo(self.listTotalLabel.mas_width);
        make.centerX.equalTo(self.mas_centerX);
        make.height.equalTo(self.listTotalLabel.mas_height);
    }];
    
    [self.pageLeft mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(showingCheckboxes ? @44 : @0);
        make.right.equalTo(self.listTotalLabel.mas_leftMargin).with.offset(SSRightElementMargin);
        make.centerY.equalTo(self.listTotalLabel.mas_centerY);
    }];
    
    [self.pageRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(showingCheckboxes ? @44 : @0);
        make.left.equalTo(self.listTotalLabel.mas_rightMargin).with.offset(SSLeftElementMargin);
        make.centerY.equalTo(self.listTotalLabel.mas_centerY);
    }];
    
    [self.bottomDividerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.listTotalLabel.mas_bottom).with.offset(SSTopElementMargin + 2);
        make.height.equalTo(@2);
        make.width.equalTo(@32);
        make.centerX.equalTo(self.mas_centerX);
        make.bottom.equalTo(self.mas_bottom).with.offset(SSBottomElementMargin);
    }];
}

- (CGFloat)estimatedHeightForListTotalHeaderInView:(UIView *)view
{
    CGFloat totalHeight = 0;
    CGFloat labelWidth = view == nil ? self.boundsWidth : view.boundsWidth;
    CGFloat distanceFromTopToLabel = SSTopElementMargin;
    CGFloat labelDisplayTypeHeight = [self.listTotalLabel.text boundingRectWithWidth:labelWidth
                                                                     text:self.displayTypeLabel.text
                                                                     font:self.displayTypeLabel.font].size.height;
    CGFloat labelHeight = [self.listTotalLabel.text boundingRectWithWidth:labelWidth
                                                                     text:self.listTotalLabel.text
                                                                     font:self.listTotalLabel.font].size.height;
    CGFloat distanceFromLabelToDivider = SSTopElementMargin + 2;
    CGFloat dividerHeight = 2.0f;
    CGFloat distanceFromDividerToBottom = SSTopElementMargin;
    
    totalHeight = distanceFromTopToLabel + labelDisplayTypeHeight + distanceFromTopToLabel + labelHeight + distanceFromLabelToDivider + dividerHeight + distanceFromDividerToBottom;
    
    if (self.list.isShowingCheckboxes == NO)
    {
        totalHeight -= distanceFromTopToLabel + labelDisplayTypeHeight;
    }
    
    return ceilf(totalHeight);
}

- (void)updateSizeWithView:(UIView *)view
{
    if ([ss_defaults() boolForKey:Show_List_Total])
    {
        self.pageLeft.hidden = NO;
        self.pageRight.hidden = NO;
        CGFloat height = [self estimatedHeightForListTotalHeaderInView:view];
        self.ss_size = CGSizeMake(view.boundsWidth, height);
    }
    else
    {
        self.pageLeft.hidden = YES;
        self.pageRight.hidden = YES;
        self.ss_size = CGSizeZero;
    }
}

#pragma mark - Header Toggling

- (void)showBreakdownOnIphone:(UITapGestureRecognizer *)sender
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    
    __weak SSListTotalHeaderView *weakSelf = self;
    weakSelf.listTotalLabel.onAnimationFinished = ^{
        [UIView animateWithDuration:SSBriefAnimationDuration animations:^ {
            weakSelf.bottomDividerView.alpha = 1.0f;
        }];
        
        SSListBreakdownViewController *breakDownVC = [[SSListBreakdownViewController alloc] initWithList:self.list];
        SSBottomNavigationViewController *navVC = [[SSBottomNavigationViewController alloc] initWithRootViewController:breakDownVC];
        [[self closestViewController] presentViewController:navVC animated:YES completion:nil];
    };
    
    self.bottomDividerView.alpha = 0.0f;
    [self.listTotalLabel dimInFromTapAnimationWithHighlight:SSSpacingMargin];
}

#pragma mark - Accessibility


- (void)updateAccessibilityValuesForLabels
{
    NSString *itemModifier = self.list.totalDisplayType == ListTotalDisplayAll ? @"" : ss_Localized(@"allItems.items");
    NSString *itemModifierPageLeft = [self nextTotalDisplayType:NO] == ListTotalDisplayAll ? @"" : ss_Localized(@"allItems.items");
    NSString *itemModifierPageRight = [self nextTotalDisplayType:YES] == ListTotalDisplayAll ? @"" : ss_Localized(@"allItems.items");
    
    self.listTotalLabel.accessibilityLabel = [NSString stringWithFormat:ss_Localized(@"listHeader.lbl.acVal"), self.listTotalLabel.text, ListTotalDisplayTypeToString(self.list.totalDisplayType), itemModifier];
    self.pageLeft.accessibilityLabel = [NSString stringWithFormat:ss_Localized(@"listHeader.btnPage.acVal"), ListTotalDisplayTypeToString([self nextTotalDisplayType:NO]), itemModifierPageLeft];
    self.pageRight.accessibilityLabel = [NSString stringWithFormat:ss_Localized(@"listHeader.btnPage.acVal"), ListTotalDisplayTypeToString([self nextTotalDisplayType:YES]), itemModifierPageRight];
}

#pragma mark - Data

- (void)updateUIForList:(SSList *)list
{
    self.list = list;
    self.taxUtil = [[TaxUtility alloc] initWithLocaleID:list.currencyIdentifier];
    
    if ([ss_defaults() boolForKey:Show_List_Total])
    {
        [self setConstraints];
        [self refreshListUIWithDisplayOption:self.list.totalDisplayType
                            currentTotalCost:[list calcTotalCostFromDisplayType]
                                    preferAnimation:NO];
    }
}

- (void)refreshListUIWithDisplayOption:(ListTotalDisplayType)displayOption currentTotalCost:(NSDecimalNumber *)currentTotalCost preferAnimation:(BOOL)prefersAnimation
{
    BOOL priceIsTheSameAsWhatsShowing = [self.listTotalLabel.text isEqualToString:[self.taxUtil guranteedCurrencyString:currentTotalCost.stringValue]];
    
    self.displayTypeLabel.hidden = !self.list.isShowingCheckboxes;
    self.pageLeft.hidden = !self.list.isShowingCheckboxes;
    self.pageRight.hidden = !self.list.isShowingCheckboxes;
    
    if (self.list.isShowingCheckboxes)
    {
        BOOL animate = [SSCitizenship voiceOverOn] == NO && [SSCitizenship lowPowerOn] == NO;
        if (prefersAnimation == NO) animate = NO;
        
        if (animate)
        {
            [UIView animateWithDuration:0.10f animations:^{
                self.displayTypeLabel.alpha = 0.0f;
                self.displayTypeLabel.transform = CGAffineTransformMakeScale(0.40f, 0.40f);
            }];
        }
        
        switch (self.list.totalDisplayType)
        {
            case ListTotalDisplayAll:
                self.displayTypeLabel.text = ss_Localized(@"listHeader.allItems");
                break;
            case ListTotalDisplayOnlyChecked:
                self.displayTypeLabel.text = ss_Localized(@"listHeader.checked");
                break;
            case ListTotalDisplayOnlyUnchecked:
                self.displayTypeLabel.text = ss_Localized(@"listHeader.unchecked");
                break;
            default:
                self.displayTypeLabel.text = ss_Localized(@"listHeader.allItems");
                break;
        }
        
        if (animate)
        {
            [UIView animateWithDuration:0.10f animations:^{
                self.displayTypeLabel.alpha = 1.0f;
                self.displayTypeLabel.transform = CGAffineTransformIdentity;
            }];
        }
    }
    
    [self updateAccessibilityValuesForLabels];
    
    if (priceIsTheSameAsWhatsShowing && self.list.totalDisplayType == displayOption)
    {
        return;
    }
    
    if ([self.listTotalLabel.text isEqualToString:@""])
    {
        self.listTotalLabel.text = [self.taxUtil guranteedCurrencyString:currentTotalCost.stringValue];;
        [self.listTotalLabel updateCurrentValue:currentTotalCost.floatValue];
    }
    else
    {
        [self.listTotalLabel countFromCurrentValueTo:currentTotalCost.floatValue];
    }
    
    // Update again if we returned
    [self updateAccessibilityValuesForLabels];
}

#pragma mark - Cursor

- (void)addPointerInteraction API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self.listTotalLabel addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.listTotalLabel parameters:[self previewParametersForLabel]];
    
    UIPointerHoverEffect *highlight = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    highlight.prefersScaledContent = NO;
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:highlight
                                                             shape:nil];
    return pointerStyle;
}

- (UIPreviewParameters *)previewParametersForLabel
{
    CGRect contentRect = CGRectInset(self.listTotalLabel.bounds, -6, -6);
    UIPreviewParameters *params = [UIPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return params;
}

@end

