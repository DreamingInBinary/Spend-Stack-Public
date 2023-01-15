//
//  SSListItemDetailSectionHeaderView.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemDetailSectionHeaderView.h"
#import "SSListItemAddAttachmentTableViewCell.h"
#import "UIView+Animations.h"
#import "SSConstants.h"
#import "Spend_Stack_2-Swift.h"

@interface SSListItemDetailSectionHeaderView() <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull) SSLabel *titleLabel;
@property (strong, nonatomic, nonnull) SSContextButton *labelButton;
@property (nonatomic, readonly, getter=isShowingRemovePhoto) BOOL showingRemovePhoto;
@property (nonatomic, readonly, getter=isShowingRemoveLink) BOOL showingRemoveLink;

@end

@implementation SSListItemDetailSectionHeaderView

#pragma mark - Custom Setters

- (void)setTitleString:(NSString *)titleString
{
    _titleString = titleString;
    _titleLabel.text = _titleString;
}

- (void)setButtonString:(NSString *)buttonString
{
    _buttonString = buttonString;
    _labelButton.buttonText = buttonString;
}

- (void)setButtonTextColor:(UIColor *)buttonTextColor
{
    _labelButton.buttonColor = buttonTextColor;
}

- (void)setTapScenario:(SSListItemDetailSectionHeaderViewTapScenario)tapScenario
{
    _tapScenario = tapScenario;
    __weak typeof(self) weakSelf = self;
    
    if (@available(iOS 14.0, *)) {
        if (_tapScenario == SSListItemDetailSectionHeaderViewTapScenarioToggleDiscount)
        {
            self.labelButton.items = [self createHandleTapForDiscountToggle];
        }
        else if (_tapScenario == SSListItemDetailSectionHeaderViewTapScenarioToggleMedia)
        {
            if (self.isShowingRemovePhoto)
            {
                UIAction *acRemovePhoto = [UIAction actionWithTitle:ss_Localized(@"listEdit.removePhoto") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self toggleMediaDisplayState];
                }];
                acRemovePhoto.attributes = UIMenuElementAttributesDestructive;
                self.labelButton.items = @[acRemovePhoto];
            }
            else
            {
                self.labelButton.items = @[];
                [self.labelButton setPrimaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                    [weakSelf handleTapForMediaToggle];
                }]];
            }
        }
        else if (_tapScenario == SSListItemDetailSectionHeaderViewTapScenarioToggleMediaLink)
        {
            if (self.isShowingRemoveLink)
            {
                UIAction *acRemoveLink = [UIAction actionWithTitle:ss_Localized(@"listEdit.removeLink") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    [self toggleLinkDisplayState];
                }];
                acRemoveLink.attributes = UIMenuElementAttributesDestructive;
                self.labelButton.items = @[acRemoveLink];
            }
            else
            {
                self.labelButton.items = @[];
                [self.labelButton setPrimaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
                    [weakSelf handleTapForMediaLinkToggle];
                }]];
            }
        }
    }
}

- (BOOL)isShowingRemovePhoto
{
    return [self.labelButton.buttonText isEqualToString:ss_Localized(@"listEdit.removePhoto")];
}

- (BOOL)isShowingRemoveLink
{
    return [self.labelButton.buttonText isEqualToString:ss_Localized(@"listEdit.removeLink")];
}

#pragma mark - Initializer

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.titleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleTitle2];
        [self.titleLabel configureFontWeight:UIFontWeightSemibold];
        
        self.labelButton = [[SSContextButton alloc] initWithFrame:CGRectZero];
        
        if ([NSProcessInfo processInfo].operatingSystemVersion.majorVersion < 14.0) {
            self.labelButton = [[SSContextButton alloc] initWithFrame:CGRectZero handler:^{
                if (self.tapScenario == SSListItemDetailSectionHeaderViewTapScenarioToggleDiscount)
                {
                    [self handleTapForDiscountToggle];
                }
                else if (self.tapScenario == SSListItemDetailSectionHeaderViewTapScenarioToggleMedia)
                {
                    [self handleTapForMediaToggle];
                }
                else if (self.tapScenario == SSListItemDetailSectionHeaderViewTapScenarioToggleMediaLink)
                {
                    [self handleTapForMediaLinkToggle];
                }
            }];
        }

        [self.contentView addSubviews:@[self.titleLabel, self.labelButton]];
        
        [self setConstraints];
        [self addShadowInteraction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAttachmentViewModeChangedNotification:)
                                                     name:SS_ATTACHMENT_VIEW_MODE_CHANGED
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [NSLayoutConstraint deactivateConstraints:self.constraints];
    [self setConstraints];
}

- (void)setConstraints
{
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
        }];
        
        [self.labelButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.titleLabel.mas_bottom).with.offset(SSTopElementMargin);
            make.bottom.equalTo(self.contentView.mas_bottom).with.offset(SSBottomElementMargin);
            make.height.and.width.equalTo(self.labelButton);
        }];
    }
    else
    {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.top.equalTo(self.contentView.mas_top);
            make.right.equalTo(self.labelButton.mas_left).with.offset(SSRightElementMargin);
            make.bottom.equalTo(self.contentView.mas_bottom).with.offset(SSBottomElementMargin);
        }];
        
        [self.labelButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(self.labelButton);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.centerY.equalTo(self.contentView.mas_centerY);
        }];
    }
}

- (CGFloat)estimatedHeightForHeaderInView:(UIView *)view
{
    CGFloat labelWidth = view == nil ? self.boundsWidth : view.boundsWidth;
    CGFloat distanceFromTopToLabel = 0;
    CGFloat labelHeight = [self.titleLabel.text boundingRectWithWidth:labelWidth
                                                         text:self.titleLabel.text
                                                         font:self.titleLabel.font].size.height;
    CGFloat distanceFromLabelToDivider = SSTopElementMargin;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        CGFloat buttonHeight = [self.labelButton.buttonText boundingRectWithWidth:labelWidth
                                                                       text:self.labelButton.buttonText
                                                                       font:self.labelButton.buttonFont].size.height;
        CGFloat titleLabelBottomPadding = SSSpacingMargin;
        
        return distanceFromTopToLabel + labelHeight + distanceFromLabelToDivider + titleLabelBottomPadding + buttonHeight + distanceFromLabelToDivider;
    }
    else
    {
        return distanceFromTopToLabel + labelHeight + distanceFromLabelToDivider;
    }
}

#pragma mark - Media Toggling

- (void)handleAttachmentViewModeChangedNotification:(NSNotification *)note
{
    // i.e. Attachments
    if ([self.titleLabel.text isEqualToString:ss_Localized(@"listEdit.header5")] &&
        self.delegate != nil)
    {
        self.buttonString = [self.delegate buttonText];
        self.buttonTextColor = [self.delegate buttonTextColor];
        self.tapScenario = [self.delegate tapScenario];
    }
}

#pragma mark - Label Button Action

- (NSArray <UIAction *> *)createHandleTapForDiscountToggle
{
    __weak SSListItemDetailSectionHeaderView *weakSelf = self;
    void (^completeChoice)(BOOL) = ^void(BOOL discountEnabled) {
        [UIView animateWithDuration:SSBriefAnimationDuration animations:^{
            if (discountEnabled)
            {
                weakSelf.labelButton.buttonText = ss_Localized(@"listEdit.remove");
                weakSelf.labelButton.buttonColor = [UIColor colorFromHexString:@"#F65E56"];
            }
            else
            {
                weakSelf.labelButton.buttonText = ss_Localized(@"listEdit.add");
                weakSelf.labelButton.buttonColor = [UIColor ssPrimaryColor];
            }
        }];
    };
    
    // Was a discount already on? Turn it off
    if ([self.labelButton.buttonText isEqualToString:ss_Localized(@"listEdit.remove")])
    {
        UIAction *acRemove = [UIAction actionWithTitle:ss_Localized(@"listEdit.remove") image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            completeChoice(NO);
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF object:nil];
        }];
        acRemove.attributes = UIMenuElementAttributesDestructive;
        
        self.labelButton.menuTitle = nil;
        return @[acRemove];
    }
    
    self.labelButton.menuTitle = ss_Localized(@"listEdit.discountType");
    UIAction *acAmountOff = [UIAction actionWithTitle:ss_Localized(@"listEdit.amountOff") image:[UIImage systemImageNamed:@"number"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        completeChoice(YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_DISCOUNT_AMOUNT_ON object:nil];
    }];

    UIAction *acPercentageOff = [UIAction actionWithTitle:ss_Localized(@"listEdit.percentOff") image:[UIImage systemImageNamed:@"percent"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        completeChoice(YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_DISCOUNT_PERCENTAGE_ON object:nil];
    }];
    
    return @[acAmountOff, acPercentageOff];
}

- (void)handleTapForDiscountToggle
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    
    __weak SSListItemDetailSectionHeaderView *weakSelf = self;
    void (^completeChoice)(BOOL) = ^void(BOOL discountEnabled) {
        [UIView animateWithDuration:SSBriefAnimationDuration animations:^{
            if (discountEnabled)
            {
                weakSelf.labelButton.buttonText = ss_Localized(@"listEdit.remove");
                weakSelf.labelButton.buttonColor = [UIColor colorFromHexString:@"#F65E56"];
            }
            else
            {
                weakSelf.labelButton.buttonText = ss_Localized(@"listEdit.add");
                weakSelf.labelButton.buttonColor = [UIColor ssPrimaryColor];
            }
        }];
    };
    
    // Was a discount already on? Turn it off
    if ([self.labelButton.buttonText isEqualToString:ss_Localized(@"listEdit.remove")])
    {
        completeChoice(NO);
        [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF object:nil];
        return;
    }
    
    weakSelf.labelButton.onAnimationFinished = ^{
        UIAlertAction *amountOff = [UIAlertAction actionWithTitle:ss_Localized(@"listEdit.amountOff") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completeChoice(YES);
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_DISCOUNT_AMOUNT_ON object:nil];
        }];
        
        UIAlertAction *percentageOff = [UIAlertAction actionWithTitle:ss_Localized(@"listEdit.percentOff") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completeChoice(YES);
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_DISCOUNT_PERCENTAGE_ON object:nil];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:ss_Localized(@"general.cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completeChoice(NO);
            [[NSNotificationCenter defaultCenter] postNotificationName:SS_PRICING_ADD_REMOVE_DISCOUNT_TOGGLED_OFF object:nil];
        }];

        UIViewController *topController = [self closestViewController];
        NSString *title = ss_Localized(@"listEdit.discountType");
        NSString *message = ss_Localized(@"listEdit.apply");
        NSArray <UIAlertAction *> *actions = @[amountOff, percentageOff, cancel];
        [topController showActionSheetWithTitle:title
                                       message:message
                                       actions:actions
                                     anchorView:weakSelf.labelButton];
    };
    
    [self.labelButton dimInFromTapAnimationWithHighlight:SSSpacingBigMargin];
}


- (void)handleTapForMediaToggle
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    
    __weak SSListItemDetailSectionHeaderView *weakSelf = self;

    self.labelButton.onAnimationFinished = ^{
        [weakSelf toggleMediaDisplayState];
    };
    
    [self.labelButton dimInFromTapAnimationWithHighlight:SSSpacingMargin];
}

- (void)toggleMediaDisplayState
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_MEDIA_WAS_TOGGLED object:@(self.isShowingRemovePhoto)];
    
    [UIView animateWithDuration:SSBriefAnimationDuration animations:^{
        if (self.isShowingRemovePhoto)
        {
            self.labelButton.buttonText = ss_Localized(@"listEdit.addPhoto");
            self.labelButton.buttonColor = [UIColor ssPrimaryColor];
        }
        else
        {
            self.labelButton.buttonText = ss_Localized(@"listEdit.removePhoto");
            self.labelButton.buttonColor = [UIColor colorFromHexString:@"#F65E56"];
        }
    }];
}

- (void)handleTapForMediaLinkToggle
{
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    
    __weak SSListItemDetailSectionHeaderView *weakSelf = self;

    self.labelButton.onAnimationFinished = ^{
        [weakSelf toggleLinkDisplayState];
    };
    
    [self.labelButton dimInFromTapAnimationWithHighlight:SSSpacingMargin];
}

- (void)toggleLinkDisplayState
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SS_MEDIA_LINK_WAS_TOGGLED object:@(self.isShowingRemoveLink)];
    
    [UIView animateWithDuration:SSBriefAnimationDuration animations:^{
        if (self.isShowingRemoveLink)
        {
            self.labelButton.buttonText = ss_Localized(@"listEdit.addLink");
            self.labelButton.buttonColor = [UIColor ssPrimaryColor];
        }
        else
        {
            self.labelButton.buttonText = ss_Localized(@"listEdit.removeLink");
            self.labelButton.buttonColor = [UIColor colorFromHexString:@"#F65E56"];
        }
    }];
}

#pragma mark - Cursor

- (void)addShadowInteraction API_AVAILABLE(ios(13.4))
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    UIPointerInteraction *hoverInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self.labelButton addInteraction:hoverInteraction];
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.labelButton parameters:[self previewParametersForLabel]];

    UIPointerHighlightEffect *highlight = [UIPointerHighlightEffect effectWithPreview:targetedPreview];
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:highlight
                                                             shape:nil];
    return pointerStyle;
}

- (UIPreviewParameters *)previewParametersForLabel
{
    CGRect contentRect = CGRectInset(self.labelButton.bounds, -8, -8);
    UIPreviewParameters *params = [UIPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return params;
}

@end
