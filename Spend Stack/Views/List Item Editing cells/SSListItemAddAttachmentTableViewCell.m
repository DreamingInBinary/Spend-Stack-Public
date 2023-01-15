//
//  SSListItemAddMediaTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 6/18/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemAddAttachmentTableViewCell.h"
#import "UITableViewCell+Common.h"

@interface SSListItemAddAttachmentTableViewCell() <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull) SSLabel *leftTitleLabel;
@property (strong, nonatomic, nullable, readwrite) UIButton *menuButton;

@end

@implementation SSListItemAddAttachmentTableViewCell

#pragma mark - Custom Setter

- (void)setViewMode:(AttachmentViewMode)viewMode
{
    _viewMode = viewMode;
    _leftTitleLabel.text = self.viewMode == AttachmentViewModeImage ? ss_Localized(@"listEdit.image.attach") : ss_Localized(@"listEdit.link.attach");
}

- (UIButton *)menuButton API_AVAILABLE(ios(14.0))
{
    if (!_menuButton)
    {
        _menuButton = [UIButton new];
        _menuButton.backgroundColor = [UIColor clearColor];
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
        self.backgroundColor = [UIColor clearColor];
        
        self.viewMode = AttachmentViewModeImage;
        self.leftTitleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.leftTitleLabel.textColor = [UIColor ssPrimaryColor];
        [self.leftTitleLabel configureFontWeight:UIFontWeightMedium];
        [self.contentView addPointerInteractionWithDelegate:self];
        
        [self.contentView addSubviews:@[self.leftTitleLabel]];
        
        self.selectedBackgroundView = [self ssSelectionView];
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        // Set up tag
        [self setConstraints];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.selectedBackgroundView.layer.cornerRadius = SSSpacingMargin;
    self.selectedBackgroundView.frame = CGRectInset(self.contentView.frame, 6, 6);
}

#pragma mark - Constraint Handling

- (void)setConstraints
{
    [super setConstraints];
    
    [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView.mas_leadingMargin);
        make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
        make.trailing.equalTo(self.contentView.mas_trailingMargin);
        make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
    }];
}

#pragma mark - Pointer Interaction Delegate

- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion API_AVAILABLE(ios(13.4))
{
    CGRect textRect = [self.leftTitleLabel.text boundingRectWithWidth:self.leftTitleLabel.ss_width
                                                                 text:self.leftTitleLabel.text
                                                                 font:self.leftTitleLabel.font];
    textRect = CGRectMake(0, self.leftTitleLabel.frame.origin.y, textRect.size.width + 20, self.leftTitleLabel.boundsHeight + 20);
    
    UIPointerRegion *validRegion = [UIPointerRegion regionWithRect:textRect identifier:nil];
    CGRect pointerRect = CGRectMake(request.location.x, request.location.y, 20, 20);
    pointerRect = [self.leftTitleLabel convertRect:pointerRect toView:self.leftTitleLabel];
    
    if (CGRectIntersectsRect(pointerRect, textRect)) {
        return validRegion;
    }
    
    return nil;
}

- (nullable UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region API_AVAILABLE(ios(13.4))
{
    if (interaction.view == nil) return nil;
    
    UIPreviewParameters *params = [UIPreviewParameters new];
    CGRect textRect = [self.leftTitleLabel.text boundingRectWithWidth:self.leftTitleLabel.ss_width
                                                                 text:self.leftTitleLabel.text
                                                                 font:self.leftTitleLabel.font];
    textRect = CGRectMake(0, 0, textRect.size.width, self.leftTitleLabel.boundsHeight);
    textRect = CGRectInset(textRect, -6, -6);
    params.visiblePath = [UIBezierPath bezierPathWithRoundedRect:textRect cornerRadius:SSSpacingMargin];
    
    UITargetedPreview *targetedPreview = [[UITargetedPreview alloc] initWithView:self.leftTitleLabel parameters:params];
    
    UIPointerHoverEffect *hover = [UIPointerHoverEffect effectWithPreview:targetedPreview];
    hover.prefersScaledContent = NO;
    
    UIPointerStyle *pointerStyle = [UIPointerStyle styleWithEffect:hover
                                                             shape:nil];
    return pointerStyle;
}

#pragma mark - Table View Cell Overrides

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted)
    {
        self.contentView.backgroundColor = nil;
    }
    else
    {
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected)
    {
        self.contentView.backgroundColor = nil;
    }
    else
    {
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];
    }
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    self.leftTitleLabel.text = self.viewMode == AttachmentViewModeImage ? ss_Localized(@"listEdit.image.attach") : ss_Localized(@"listEdit.link.attach");
    [self setConstraints];
}

@end
