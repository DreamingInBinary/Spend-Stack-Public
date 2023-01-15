//
//  SSGeneralTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 11/20/17.
//  Copyright © 2017 Jordan Morgan. All rights reserved.
//

#import "SSGeneralTableViewCell.h"
#import "UITableViewCell+Common.h"
#import "UIView+Animations.h"
#import "UIImageView+SSUtils.h"
#import "UIImage+Utils.h"

@interface SSGeneralTableViewCell() <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull, readwrite) SSLabel *topLabel;
@property (strong, nonatomic, nonnull, readwrite) SSLabel *bottomLabel;
@property (strong, nonatomic, nullable, readwrite) UISwitch *rightSwitch;
@property (strong, nonatomic, nonnull, readwrite) UIImageView *leftImageView;
@property (strong, nonatomic, nullable) UIColor *leftImageViewSelectedBackgroundColor;
@property (strong, nonatomic, nonnull) UIImageView *disclosureImage;
@property (strong, nonatomic, nonnull) UIView *dividerView;
@property (strong, nonatomic, nonnull) UIPointerInteraction *bottomLabelInteraction API_AVAILABLE(ios(13.4));
@property (strong, nonatomic, nullable, readwrite) UIButton *menuButton;

@end

@implementation SSGeneralTableViewCell

#pragma mark - Custom Setters

- (void)setShowSwitch:(BOOL)showSwitch
{
    _showSwitch = showSwitch;
    _rightSwitch.hidden = !showSwitch;
    _disclosureImage.hidden = showSwitch;
    
    [self.disclosureImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_rightMargin).with.offset(SSSpacingMargin);
        make.height.and.width.equalTo(showSwitch ? @0 : @28);
    }];
    
    [self remakeSwitchConstraints:showSwitch];
}

- (void)setShowDivider:(BOOL)showDivider
{
    _showDivider = showDivider;
    _dividerView.alpha = showDivider ? 1.0f : 0.0f;
}

- (void)setShowDisclosureIndicator:(BOOL)showDisclosureIndicator
{
    _showDisclosureIndicator = showDisclosureIndicator;
    _disclosureImage.hidden = !showDisclosureIndicator;
    _rightSwitch.hidden = showDisclosureIndicator;
    
    [self.disclosureImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_rightMargin).with.offset(SSSpacingMargin);
        make.height.and.width.equalTo(showDisclosureIndicator ? @28 : @0);
    }];
    
    [self remakeSwitchConstraints:!showDisclosureIndicator];
}

- (void)setHideAllAccessoryViews:(BOOL)hideAllAccessoryViews
{
    _hideAllAccessoryViews = hideAllAccessoryViews;
    _rightSwitch.hidden = _hideAllAccessoryViews;
    _disclosureImage.hidden = _hideAllAccessoryViews;
}

- (void)setHideBottomLabel:(BOOL)hideBottomLabel
{
    _hideBottomLabel = hideBottomLabel;
    self.bottomLabel.hidden = _hideBottomLabel;
    
    if (_hideBottomLabel)
    {
        // Basic early out. Can make this a bit smarter later.
        // If we've already moved over the bottom label, we've done the update of the constraints already.
        // So, skip doing it again since this is likely set in cellForRowAtIndexPath:.
        if (self.bottomLabel.ss_x != 0 || [SSCitizenship accessibilityFontsEnabled]) return;

        [self.leftImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_leftMargin);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.and.width.equalTo(@32);
        }];
        
        [self.topLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.leftImageView.mas_centerY);
            make.left.equalTo(self.leftImageView.mas_right).with.offset(SSLeftBigElementMargin);
            make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
        }];
        
        [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.greaterThanOrEqualTo(self.topLabel.mas_height);
            make.left.equalTo(self.topLabel.mas_left);
            make.top.greaterThanOrEqualTo(self.contentView.mas_top).with.offset(SSTopElementMargin);
            make.bottom.greaterThanOrEqualTo(self.dividerView.mas_top).with.offset(SSBottomElementMargin);
        }];
    }
    else
    {
        [self setConstraints];
    }
}


- (void)setStyleBottomLabelAsButton:(BOOL)styleBottomLabelAsButton
{
    _styleBottomLabelAsButton = styleBottomLabelAsButton;
    
    if (_styleBottomLabelAsButton)
    {
        _bottomLabel.textColor = [UIColor ssPrimaryColor];
        _bottomLabel.accessibilityTraits = UIAccessibilityTraitButton;
        [_bottomLabel configureFontWeight:UIFontWeightMedium];
        _bottomLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(performOnBottomLabelTapped)];
        [_bottomLabel addGestureRecognizer:tap];
    }
    else
    {
        _bottomLabel.textColor = [UIColor ssTextPlaceholderColor];
        _bottomLabel.accessibilityTraits = UIAccessibilityTraitStaticText;
        [_bottomLabel configureFontWeight:UIFontWeightRegular];
        _bottomLabel.userInteractionEnabled = NO;
        [_bottomLabel removeGestureRecognizer:_bottomLabel.gestureRecognizers.firstObject];
    }
    
    if ([SSCitizenship accessibilityFontsEnabled] == NO)
    {
        [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.leftImageView.mas_right).with.offset(SSLeftBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomElementMargin);
            make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
        }];
    }
}

- (void)performOnBottomLabelTapped
{
    if (self.onBottomLabelTapped == nil) return;
    
    [UIFeedbackGenerator playFeedbackOfType:SSHapticFeedbackTypeStyleLight];
    [self.bottomLabel dimInFromTapAnimationWithHighlight:SSSpacingMargin];
    __weak typeof(self) weakSelf = self;
    _bottomLabel.onAnimationFinished = ^{
        weakSelf.onBottomLabelTapped();
    };
}

- (UIButton *)menuButton API_AVAILABLE(ios(14.0))
{
    if (!_menuButton)
    {
        _menuButton = [UIButton new];
        _menuButton.showsMenuAsPrimaryAction = YES;
    }
    
    return _menuButton;
}

- (void)setMenu:(UIMenu *)menu API_AVAILABLE(ios(14.0))
{
    _menu = menu;
    
    if (_menu)
    {
        if (self.menuButton.superview == nil)
        {
            self.menuButton.menu = _menu;
            [self.contentView addSubview:self.menuButton];
            [self.menuButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self);
            }];
        }
    }
    else
    {
        if (_menuButton.superview)
        {
            [_menuButton removeFromSuperview];
        }
    }
}

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.backgroundColor = [UIColor systemBackgroundColor];
        self.contentView.clipsToBounds = NO;
        self.clipsToBounds = NO;
        
        self.topLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        [self.topLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        self.bottomLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleSubheadline];
        self.bottomLabel.textColor = [UIColor ssTextPlaceholderColor];
        [self.bottomLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        self.leftImageView = [UIImageView sqaureIconImageView];
        
        self.disclosureImage = [self ssDisclosureImageView];
        self.disclosureImage.hidden = YES;
        self.disclosureImage.isAccessibilityElement = NO;
        
        self.rightSwitch = [UISwitch new];
        self.rightSwitch.onTintColor = [UIColor ssPrimaryColor];
        self.rightSwitch.hidden = YES;
        [self.rightSwitch addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
        
        self.dividerView = [UIView new];
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
        
        [self.contentView addSubviews:@[self.topLabel,
                                        self.bottomLabel,
                                        self.leftImageView,
                                        self.disclosureImage,
                                        self.rightSwitch,
                                        self.dividerView]];
        
        self.dividerView.alpha = 0.0f;
        self.selectedBackgroundView = [self ssSelectionView];
        
        [self setConstraints];
        [self createPointerInteraction];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.selectedBackgroundView.layer.cornerRadius = SSSpacingMargin;
    self.selectedBackgroundView.frame = CGRectInset(self.contentView.frame, 6, 2);
}

#pragma mark - Constraint Handling

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    NSNumber *iconSize = @([UIImageView squareIconImageViewSize]);
    
    self.leftImageView.layer.cornerRadius = [SSCitizenship accessibilityFontsEnabled] ? floorf(iconSize.floatValue/2) : SSSpacingMargin;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.leftImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_leftMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.height.and.width.equalTo(iconSize);
        }];
        
        [self.topLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.leftImageView.mas_bottom).with.offset(SSTopBigElementMargin);
            make.left.equalTo(self.leftImageView.mas_left);
            make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
        }];
        
        [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.leftImageView.mas_left);
            make.right.lessThanOrEqualTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
            make.top.equalTo(self.topLabel.mas_bottom).with.offset(SSTopBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomElementMargin);
        }];
    }
    else
    {
        [self.leftImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_leftMargin);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.and.width.equalTo(iconSize);
        }];
        
        [self.topLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopElementMargin);
            make.left.equalTo(self.leftImageView.mas_right).with.offset(SSLeftBigElementMargin);
            make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
            make.bottom.equalTo(self.bottomLabel.mas_top).with.offset(-4);
        }];
        
        [self.bottomLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.leftImageView.mas_right).with.offset(SSLeftBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomElementMargin);
            make.right.equalTo(self.disclosureImage.mas_left).with.offset(SSRightElementMargin);
        }];
    }

    [self.disclosureImage mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_rightMargin).with.offset(SSSpacingMargin); // Because the image itself has padding
        make.height.and.width.equalTo(self.showDisclosureIndicator ? @28 : @0);
    }];
    
    [self remakeSwitchConstraints:self.showSwitch];
    
    [self.dividerView mas_remakeConstraints:[self constraintsForDividerView:self.dividerView]];
}
    
#pragma mark - Common Constraints
    
- (void)remakeSwitchConstraints:(BOOL)showSwitch
{
    [self.rightSwitch mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_rightMargin).with.priorityHigh();
        make.height.and.width.equalTo(self.showSwitch ? self.rightSwitch : @0);
    }];
}

#pragma mark - Table View Cell Overrides

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.showSwitch = NO;
    self.showDisclosureIndicator = NO;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted)
    {
        self.leftImageView.backgroundColor = self.leftImageViewSelectedBackgroundColor;
        self.dividerView.backgroundColor = [UIColor systemBackgroundColor];
    }
    else
    {
        self.dividerView.backgroundColor = [UIColor ssMutedColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    self.dividerView.backgroundColor = [UIColor ssMutedColor];
    
    if (selected)
    {
        self.leftImageView.backgroundColor = self.leftImageViewSelectedBackgroundColor;
    }
}

#pragma mark - Private Methods

- (void)toggleSwitch:(UISwitch *)rightSwitch
{
    if (self.onSwitchChanged)
    {
        self.onSwitchChanged(rightSwitch.isOn);
    }
}

#pragma mark - Cursor

- (void)createPointerInteraction
{
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    self.bottomLabelInteraction = [[UIPointerInteraction alloc] initWithDelegate:self];
    [self.bottomLabel addInteraction:self.bottomLabelInteraction];
}

- (void)setPointerInteractionEnabled:(BOOL)enabled
{
    self.bottomLabelInteraction.enabled = enabled;
}

#pragma mark - Pointer Interaction Delegate

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.bottomLabel parameters:[self previewParametersForLabel]];
    
    UIPointerHoverEffect *hover = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    hover.prefersScaledContent = NO;
    
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

- (UIPreviewParameters *)previewParametersForLabel
{
    CGRect textRangeRect = [self.bottomLabel.text boundingRectWithWidth:self.bottomLabel.boundsWidth
                                                                   text:self.bottomLabel.text
                                                                   font:self.bottomLabel.font];
    
    CGRect contentRect = CGRectInset(textRangeRect, -4, -4);
    UIPreviewParameters *params = [UIPreviewParameters new];
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:SSSpacingMargin];
    return params;
}

#pragma mark - Public Methods

- (void)setLeadingIconImage:(UIImage *)image backgroundColor:(UIColor *)backgroundColor
{
    self.leftImageView.image = [image squareIconTemplateImageFromImage];
    self.leftImageView.backgroundColor = backgroundColor;
    self.leftImageViewSelectedBackgroundColor = backgroundColor;
}

- (void)setLeadingIconWithSystemImage:(UIImage *)image backgroundColor:(UIColor *)backgroundColor
{
    self.leftImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.leftImageView.backgroundColor = backgroundColor;
    self.leftImageViewSelectedBackgroundColor = backgroundColor;
}

@end
