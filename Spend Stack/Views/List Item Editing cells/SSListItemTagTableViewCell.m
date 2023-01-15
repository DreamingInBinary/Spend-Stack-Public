//
//  SSListItemTagTableViewCell.m
//  Spend Stack
//
//  Created by Jordan Morgan on 2/22/18.
//  Copyright © 2018 Jordan Morgan. All rights reserved.
//

#import "SSListItemTagTableViewCell.h"
#import "UITableViewCell+Common.h"
#import "SSTagSelectionViewModel.h"

@interface SSListItemTagTableViewCell() <UIPointerInteractionDelegate>

@property (strong, nonatomic, nonnull) UIView *tagView;
@property (strong, nonatomic, nullable) UIColor *tagViewSelectedBackgroundColor;
@property (strong, nonatomic, nonnull) SSLabel *leftTitleLabel;
@property (strong, nonatomic, nonnull) UIImageView *selectedBadgeImageView;

@end

@implementation SSListItemTagTableViewCell

#pragma mark - Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        self.tagView = [UIView new];
        self.leftTitleLabel = [[SSLabel alloc] initWithTextStyle:UIFontTextStyleBody];
        self.leftTitleLabel.textColor = [UIColor ssPrimaryColor];
        [self.leftTitleLabel configureFontWeight:UIFontWeightMedium];
        
        UIImage *img = [[UIImage systemImageNamed:@"checkmark.circle.fill"]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.selectedBadgeImageView = [[UIImageView alloc] initWithImage:img];
        self.selectedBadgeImageView.tintColor = [UIColor ssPrimaryColor];
        self.selectedBadgeImageView.hidden = YES;
        
        self.selectedBackgroundView = [self ssSelectionView];
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        [self.contentView addPointerInteractionWithDelegate:self];
        
        [self.contentView addSubviews:@[self.tagView,
                                        self.leftTitleLabel,
                                        self.selectedBadgeImageView]];
        
        // Set up tag
        [self setConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
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

- (void)didChangePreferredContentSize:(NSNotification *)note
{
    [self setConstraints];
}

- (void)setConstraints
{
    [super setConstraints];
    
    NSNumber *tagSize = [UIView tagViewDotHeightWidth];
    self.tagView.layer.cornerRadius = tagSize.integerValue/2;
    
    if ([SSCitizenship accessibilityFontsEnabled])
    {
        [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView.mas_left).with.offset(SSLeftBigElementMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.width.and.height.equalTo(tagSize);
        }];
        
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tagView.mas_bottom).with.offset(SSTopElementMargin);
            make.left.equalTo(self.tagView.mas_left);
            make.right.equalTo(self.selectedBadgeImageView.mas_left).with.offset(SSRightBigElementMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
    else
    {
        [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView.mas_leadingMargin);
            make.width.and.height.equalTo(tagSize);
            make.centerY.equalTo(self.contentView.mas_centerY);
        }];
        
        [self.leftTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tagView.mas_right).with.offset(SSLeftElementMargin);
            make.top.equalTo(self.contentView.mas_top).with.offset(SSTopBigElementMargin);
            make.trailing.equalTo(self.contentView.mas_trailingMargin);
            make.bottom.equalTo(self.dividerView.mas_top).with.offset(SSBottomBigElementMargin);
        }];
    }
    
    [self.selectedBadgeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.and.height.equalTo(@20);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.trailing.equalTo(self.contentView.mas_trailingMargin);
    }];
}

#pragma mark - Pointer Interaction Delegate

- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion API_AVAILABLE(ios(13.4))
{
    if ([self.leftTitleLabel.text isEqualToString:ss_Localized(@"listEdit.addTag")] == NO) return nil;
    
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
    if ([self.leftTitleLabel.text isEqualToString:ss_Localized(@"listEdit.addTag")] == NO) return nil;
    
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
        self.tagView.backgroundColor = self.tagViewSelectedBackgroundColor;
        if (self.shouldUseCheckmarkForSelection)
        {
            self.selectedBadgeImageView.hidden = NO;
        }
    }
    else
    {
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];
        self.selectedBadgeImageView.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected)
    {
        self.contentView.backgroundColor = nil;
        self.tagView.backgroundColor = self.tagViewSelectedBackgroundColor;
        if (self.shouldUseCheckmarkForSelection)
        {
            self.selectedBadgeImageView.hidden = NO;
        }
    }
    else
    {
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];
        self.selectedBadgeImageView.hidden = YES;
    }
}

#pragma mark - Public Methods

- (void)setData:(SSListItem *)item list:(SSList * _Nonnull)list
{
    [super setData:item list:list];
    self.leftTitleLabel.text = item.tag == nil ? ss_Localized(@"listEdit.addTag") : item.tag.name;
    
    // Add the rest of the cells, fix spacing to be consistent
    if (item.tag)
    {
        NSNumber *tagSize = [SSCitizenship accessibilityFontsEnabled] ?@(TAG_HEIGHT_WIDTH_ACCESSIBILITY) :@(TAG_HEIGHT_WIDTH_REGULAR);
        
        [self.tagView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(tagSize);
        }];
        
        [self.leftTitleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            if ([SSCitizenship accessibilityFontsEnabled])
            {
                make.left.equalTo(self.tagView.mas_left);
            }
            else
            {
                make.left.equalTo(self.tagView.mas_right).with.offset(SSLeftElementMargin);
            }
        }];
        
        self.tagView.backgroundColor = [SSTag rawColorFromColor:item.tag.color];
        self.tagView.layer.cornerRadius = tagSize.integerValue/2;
        self.leftTitleLabel.textColor = [UIColor ssMainFontColor];
        self.tagViewSelectedBackgroundColor = self.tagView.backgroundColor;
    }
    else
    {
        [self.tagView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.and.height.equalTo(@0);
        }];
        
        [self.leftTitleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tagView.mas_right);
        }];
        self.leftTitleLabel.textColor = [UIColor ssPrimaryColor];
    }
}

- (void)setDataForTag:(SSTagSelectionViewModel *)tag
{
    self.leftTitleLabel.text = tag.name;
    
    // Premature optimization :p
    if ([self.leftTitleLabel.textColor isEqual:[UIColor ssMainFontColor]] == NO)
    {
        self.leftTitleLabel.textColor = [UIColor ssMainFontColor];
        [self.leftTitleLabel configureFontWeight:UIFontWeightRegular];
    }

    self.tagView.backgroundColor = [SSTag rawColorFromColor:tag.color];
    self.tagViewSelectedBackgroundColor = self.tagView.backgroundColor;
}

@end
